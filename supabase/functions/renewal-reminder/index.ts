// RS-066 — Renewal reminder system.
//
// Invoke daily via cron or manually:
//   curl -X POST https://<project>.supabase.co/functions/v1/renewal-reminder \
//     -H "Authorization: Bearer <service-role-key>"
//
// Logic:
//   1. Find active policies expiring within 30 days that have no pending renewal_link
//   2. For each: create a renewal_links record with a Pago Móvil deep-link
//   3. (Phase 1.5) Send push notification to rider once Firebase is configured
//   4. Emit MQTT event for Thony's Broker Portal to surface to broker pipeline

import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// AZ Capital Pago Móvil account details (set via Supabase Vault / env vars)
const PM_PHONE = Deno.env.get("AZ_PAGO_MOVIL_PHONE") ?? "04120000000";
const PM_BANK_CODE = Deno.env.get("AZ_PAGO_MOVIL_BANK_CODE") ?? "0134";
const PM_RIF = Deno.env.get("AZ_COMPANY_RIF") ?? "J-XXXXXXXXX-X";

function buildPagoMovilLink(params: {
  phone: string;
  bankCode: string;
  amountUsd: number;
  reference: string;
  concept: string;
}): string {
  // Deep-link format used by major Venezuelan bank apps for Pago Móvil C2B.
  // Format is not standardised — this is the most widely supported variant.
  const encoded = encodeURIComponent(params.concept);
  return (
    `pagomovil://pay?` +
    `phone=${params.phone}&` +
    `bank=${params.bankCode}&` +
    `amount=${params.amountUsd.toFixed(2)}&` +
    `ref=${params.reference}&` +
    `concept=${encoded}`
  );
}

Deno.serve(async (req) => {
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (cronSecret) {
    const authHeader = req.headers.get("Authorization");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (
      authHeader !== `Bearer ${cronSecret}` &&
      authHeader !== `Bearer ${serviceKey}`
    ) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  const now = new Date();
  const in30Days = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)
    .toISOString()
    .split("T")[0];

  // 1. Find active policies expiring soon
  const { data: expiringPolicies, error: fetchError } = await supabase
    .from("policies")
    .select(
      `id, profile_id, end_date, premium_usd,
       profiles!profile_id(full_name, phone),
       policy_types!policy_type_id(name, tier),
       brokers!broker_id(id)`,
    )
    .eq("status", "active")
    .lte("end_date", in30Days)
    .gte("end_date", now.toISOString().split("T")[0])
    .limit(100);

  if (fetchError) {
    console.error("Failed to fetch expiring policies:", fetchError);
    return new Response(
      JSON.stringify({ error: fetchError.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  let created = 0;
  let skipped = 0;
  const details: string[] = [];

  for (const policy of expiringPolicies ?? []) {
    // 2. Skip if a non-expired renewal_link already exists
    const { data: existing } = await supabase
      .from("renewal_links")
      .select("id")
      .eq("policy_id", policy.id)
      .is("completed_at", null)
      .gte("expires_at", now.toISOString())
      .maybeSingle();

    if (existing) {
      skipped++;
      continue;
    }

    // 3. Generate renewal link
    const reference = `REN-${policy.id.substring(0, 8).toUpperCase()}`;
    const concept =
      `Renovación RCV ${policy.policy_types?.name ?? ""} — ${reference}`;

    const link = buildPagoMovilLink({
      phone: PM_PHONE,
      bankCode: PM_BANK_CODE,
      amountUsd: policy.premium_usd ?? 17,
      reference,
      concept,
    });

    const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)
      .toISOString();

    await supabase.from("renewal_links").insert({
      policy_id: policy.id,
      broker_id: policy.brokers?.id ?? null,
      pago_movil_link: link,
      expires_at: expiresAt,
    });

    // 4. Audit event for Thony's Broker Portal (MQTT event in Phase 1.5)
    await supabase.from("audit_log").insert({
      actor_id: policy.profile_id,
      event_type: "policy.renewal_link_created",
      target_id: policy.id,
      target_table: "policies",
      payload: {
        days_remaining: Math.ceil(
          (new Date(policy.end_date).getTime() - now.getTime()) /
            (24 * 60 * 60 * 1000),
        ),
        tier: policy.policy_types?.tier,
        renewal_reference: reference,
      },
    });

    // TODO (Phase 1.5): Send push notification via Firebase FCM once configured.
    // await sendPushNotification({
    //   userId: policy.profile_id,
    //   title: 'Tu póliza vence pronto',
    //   body: `Renueva tu ${policy.policy_types?.name} antes del ${policy.end_date}`,
    //   data: { policyId: policy.id, link },
    // });

    created++;
    details.push(
      `policy=${policy.id.substring(0, 8)} end_date=${policy.end_date} ref=${reference}`,
    );
  }

  return new Response(
    JSON.stringify({
      created,
      skipped,
      details,
      ts: new Date().toISOString(),
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
