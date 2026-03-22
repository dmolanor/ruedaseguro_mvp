// ============================================================
// RS-020: Send WhatsApp OTP (phone verification)
// ============================================================
// Deploy: supabase functions deploy send-otp
// Invoked by Flutter during login/registration (unauthenticated).
//
// Flow:
//   1. Normalise Venezuelan phone to +58XXXXXXXXXX
//   2. Generate 6-digit OTP, hash with SHA-256 + random salt
//   3. Invalidate prior unverified codes for same phone
//   4. Insert new record in phone_verifications
//   5. Send OTP via Meta WhatsApp Business Cloud API (template)
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Accepts: +58XXXXXXXXXX | 04XXXXXXXXX | 4XXXXXXXXX
function normalizePhone(raw: string): string {
  const s = raw.trim();
  if (s.startsWith('+')) return s;
  if (s.startsWith('0')) return `+58${s.slice(1)}`;
  return `+58${s}`;
}

function isValidVenPhone(phone: string): boolean {
  // +58 followed by a valid operator prefix (412,414,416,424,426) + 7 digits
  return /^\+58(412|414|416|424|426)\d{7}$/.test(phone);
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

    if (!phone) {
      return new Response(JSON.stringify({ error: 'phone_required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const normalized = normalizePhone(phone);

    if (!isValidVenPhone(normalized)) {
      return new Response(JSON.stringify({ error: 'invalid_phone_format' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // --- Generate OTP ---
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const salt = crypto.randomUUID();
    const otp_hash = bufToHex(
      await crypto.subtle.digest('SHA-256', new TextEncoder().encode(otp + salt))
    );

    // --- Persist to Supabase ---
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Invalidate all previous unverified codes for this phone
    await supabase
      .from('phone_verifications')
      .update({ verified: true })
      .eq('phone', normalized)
      .eq('verified', false);

    const { error: insertError } = await supabase
      .from('phone_verifications')
      .insert({ phone: normalized, otp_hash, salt });

    if (insertError) {
      console.error('DB insert error:', insertError);
      return new Response(JSON.stringify({ error: 'db_error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // --- Dev bypass: skip WhatsApp, log OTP to console ---
    // Set SUPABASE_OTP_DEV_BYPASS=true via: supabase secrets set SUPABASE_OTP_DEV_BYPASS=true
    // Check logs with: supabase functions logs send-otp
    if (Deno.env.get('SUPABASE_OTP_DEV_BYPASS') === 'true') {
      console.log(`[DEV] OTP for ${normalized}: ${otp}`);
      return new Response(
        JSON.stringify({ ok: true, dev_mode: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // --- Send via Meta WhatsApp Cloud API ---
    const waToken = Deno.env.get('WHATSAPP_TOKEN');
    const phoneNumberId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID');

    if (!waToken || !phoneNumberId) {
      console.error('WhatsApp env vars not configured');
      return new Response(JSON.stringify({ error: 'whatsapp_not_configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const waRes = await fetch(
      `https://graph.facebook.com/v19.0/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${waToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: normalized,
          type: 'template',
          template: {
            // Template must be created and approved in Meta Business Manager
            // Category: Authentication
            // Body: Tu código de verificación RuedaSeguro es: {{1}}. Válido por 10 minutos.
            name: 'otp_verification',
            language: { code: 'es' },
            components: [
              {
                type: 'body',
                parameters: [{ type: 'text', text: otp }],
              },
            ],
          },
        }),
        signal: AbortSignal.timeout(10_000),
      }
    );

    if (!waRes.ok) {
      const errBody = await waRes.text();
      console.error('WhatsApp send failed:', waRes.status, errBody);
      return new Response(
        JSON.stringify({ error: 'whatsapp_send_failed', detail: errBody }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('send-otp unexpected error:', err);
    return new Response(
      JSON.stringify({ error: 'internal_error', message: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
