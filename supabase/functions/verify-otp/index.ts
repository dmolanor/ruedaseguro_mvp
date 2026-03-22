// ============================================================
// RS-020: Verify WhatsApp OTP and issue Supabase session
// ============================================================
// Deploy: supabase functions deploy verify-otp
// Invoked by Flutter after user enters the 6-digit code.
//
// Flow:
//   1. Find latest unverified, non-expired record for the phone
//   2. Increment attempts and reject if >= 5
//   3. Verify SHA-256(otp + salt) against stored hash
//   4. Mark OTP as verified
//   5. Look up user_phones → create auth user if first time
//   6. Create a Supabase session with admin.createSession()
//   7. Return { access_token, refresh_token, is_new_user }
//
// Flutter side:
//   final res = await supabase.auth.setSession(refreshToken);
//   — or —
//   await supabase.auth.recoverSession(jsonEncode({ access_token, refresh_token, ... }));
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function normalizePhone(raw: string): string {
  const s = raw.trim();
  if (s.startsWith('+')) return s;
  if (s.startsWith('0')) return `+58${s.slice(1)}`;
  return `+58${s}`;
}

function bufToHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => null);
    const phone: string | undefined = body?.phone;
    const otp: string | undefined = body?.otp;

    if (!phone || !otp) {
      return new Response(JSON.stringify({ error: 'phone_and_otp_required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const normalized = normalizePhone(phone);

    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // --- Fetch latest valid OTP record ---
    const { data: record, error: fetchError } = await adminClient
      .from('phone_verifications')
      .select('id, otp_hash, salt, attempts')
      .eq('phone', normalized)
      .eq('verified', false)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (fetchError || !record) {
      return new Response(
        JSON.stringify({ error: 'otp_expired_or_not_found' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // --- Rate-limit: max 5 attempts per code ---
    if (record.attempts >= 5) {
      return new Response(
        JSON.stringify({ error: 'too_many_attempts' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // --- Dev bypass: accept master code "000000" without hash check ---
    const isDevBypass =
      Deno.env.get('SUPABASE_OTP_DEV_BYPASS') === 'true' && String(otp) === '000000';

    if (!isDevBypass) {
      // --- Verify hash ---
      const computedHash = bufToHex(
        await crypto.subtle.digest(
          'SHA-256',
          new TextEncoder().encode(String(otp) + record.salt)
        )
      );

      if (computedHash !== record.otp_hash) {
        const newAttempts = record.attempts + 1;
        await adminClient
          .from('phone_verifications')
          .update({ attempts: newAttempts })
          .eq('id', record.id);

        return new Response(
          JSON.stringify({
            error: 'invalid_otp',
            attempts_remaining: 5 - newAttempts,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // --- Mark OTP as verified (consume it) ---
    await adminClient
      .from('phone_verifications')
      .update({ verified: true })
      .eq('id', record.id);

    // --- Look up or create auth user ---
    let userId: string;
    let isNewUser = false;

    const { data: phoneRecord } = await adminClient
      .from('user_phones')
      .select('user_id')
      .eq('phone', normalized)
      .single();

    if (phoneRecord) {
      userId = phoneRecord.user_id;
    } else {
      // First time this phone verifies — create a Supabase Auth user
      const { data: newUserData, error: createError } =
        await adminClient.auth.admin.createUser({
          phone: normalized,
          phone_confirm: true,
        });

      if (createError || !newUserData?.user) {
        console.error('Auth user creation failed:', createError);
        return new Response(
          JSON.stringify({ error: 'user_creation_failed' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      userId = newUserData.user.id;
      isNewUser = true;

      // Persist phone → user_id mapping for future logins
      await adminClient
        .from('user_phones')
        .insert({ phone: normalized, user_id: userId });
    }

    // --- Issue a Supabase session ---
    const { data: sessionData, error: sessionError } =
      await adminClient.auth.admin.createSession({ user_id: userId });

    if (sessionError || !sessionData?.session) {
      console.error('Session creation failed:', sessionError);
      return new Response(
        JSON.stringify({ error: 'session_creation_failed' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { access_token, refresh_token, expires_in } = sessionData.session;

    return new Response(
      JSON.stringify({
        ok: true,
        is_new_user: isNewUser,
        access_token,
        refresh_token,
        expires_in,
        user_id: userId,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('verify-otp unexpected error:', err);
    return new Response(
      JSON.stringify({ error: 'internal_error', message: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
