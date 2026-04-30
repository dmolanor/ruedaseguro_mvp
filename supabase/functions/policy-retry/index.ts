// RS-062 — Policy provisional retry queue.
//
// Invoke via cron (every 15 min) or manually:
//   curl -X POST https://<project>.supabase.co/functions/v1/policy-retry \
//     -H "Authorization: Bearer <service-role-key>"
//
// Logic:
//   Find policies WHERE issuance_status IN ('pending','provisional')
//                  AND carrier_api_attempts < 3
//                  AND (provisional_issued_at IS NULL OR provisional_issued_at < now() - 15min)
//   → Call carrier API stub (replace with real Acsel/Sirway client in RS-060)
//   → On success: set confirmed, carrier_policy_number, status=active
//   → On failure (attempt 3): set issuance_status=rejected, create CRITICAL ticket

import { createClient } from "jsr:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ── Stub carrier call (replace with Acsel/Sirway HTTP call in RS-060) ──
async function callCarrierApi(
  policyId: string,
  vehiclePlate: string,
): Promise<{ success: boolean; policyNumber?: string; error?: string }> {
  // TODO (RS-060): POST to Acsel/Sirway endpoint when William provides docs.
  // Simulate API with realistic latency.
  await new Promise((r) => setTimeout(r, 800));
  const ts = Date.now() % 10000000;
  return {
    success: true,
    policyNumber: `ACL-${vehiclePlate.replace(/[^A-Z0-9]/g, "")}-${ts}`,
  };
}

Deno.serve(async (req) => {
  // Auth is always required — either CRON_SECRET (scheduler) or service_role key (manual).
  const cronSecret = Deno.env.get("CRON_SECRET");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authHeader = req.headers.get("Authorization");
  const validCron = cronSecret && authHeader === `Bearer ${cronSecret}`;
  const validService = serviceKey && authHeader === `Bearer ${serviceKey}`;
  if (!validCron && !validService) {
    return new Response("Unauthorized", { status: 401 });
  }

  const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();

  // Find candidate policies for retry
  const { data: policies, error: fetchError } = await supabase
    .from("policies")
    .select("id, carrier_api_attempts, vehicle_id, profile_id")
    .in("issuance_status", ["pending", "provisional"])
    .lt("carrier_api_attempts", 3)
    .or(
      `provisional_issued_at.is.null,provisional_issued_at.lt.${fifteenMinsAgo}`,
    )
    .limit(20); // Process at most 20 per run to stay within Edge Function limits

  if (fetchError) {
    console.error("Failed to fetch candidate policies:", fetchError);
    return new Response(
      JSON.stringify({ error: fetchError.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const results: Array<{
    policyId: string;
    outcome: string;
    policyNumber?: string;
  }> = [];

  for (const policy of policies ?? []) {
    const { id: policyId, carrier_api_attempts, profile_id } = policy;
    const attempt = (carrier_api_attempts ?? 0) + 1;
    const now = new Date().toISOString();

    // Fetch vehicle plate for carrier payload
    const { data: vehicle } = await supabase
      .from("vehicles")
      .select("plate, brand, model, year")
      .eq("id", policy.vehicle_id)
      .maybeSingle();

    // Mark api_submitted + increment attempt counter
    await supabase.from("policies").update({
      issuance_status: "api_submitted",
      carrier_api_attempts: attempt,
    }).eq("id", policyId);

    let outcome: string;
    try {
      const apiResult = await callCarrierApi(
        policyId,
        vehicle?.plate ?? "UNKNOWN",
      );

      if (apiResult.success && apiResult.policyNumber) {
        await supabase.from("policies").update({
          issuance_status: "confirmed",
          carrier_policy_number: apiResult.policyNumber,
          confirmed_at: now,
          status: "active",
        }).eq("id", policyId);

        await supabase.from("audit_log").insert({
          actor_id: profile_id,
          event_type: "policy.carrier_confirmed_via_retry",
          target_id: policyId,
          target_table: "policies",
          payload: {
            carrier_policy_number: apiResult.policyNumber,
            attempt,
          },
        });

        outcome = "confirmed";
        results.push({
          policyId,
          outcome: "confirmed",
          policyNumber: apiResult.policyNumber,
        });
      } else {
        throw new Error(apiResult.error ?? "carrier_rejected");
      }
    } catch (err) {
      const isFinalAttempt = attempt >= 3;
      outcome = isFinalAttempt ? "max_attempts_reached" : "provisional";

      if (isFinalAttempt) {
        // After 3 failed attempts: create CRITICAL ticket for ops desk
        await supabase.from("policies").update({
          issuance_status: "provisional",
          provisional_issued_at: now,
        }).eq("id", policyId);

        await supabase.from("tickets").insert({
          entity_type: "system",
          entity_id: policyId,
          rider_id: profile_id,
          policy_id: policyId,
          subject: `Emisión fallida tras 3 intentos — Póliza ${policyId.substring(0, 8).toUpperCase()}`,
          description: `La API de la aseguradora no respondió correctamente en 3 intentos. Requiere emisión manual.\nError: ${String(err)}`,
          priority: "critical",
          status: "open",
        });

        await supabase.from("audit_log").insert({
          actor_id: profile_id,
          event_type: "policy.carrier_max_attempts",
          target_id: policyId,
          target_table: "policies",
          payload: { attempts: attempt, error: String(err) },
        });
      } else {
        await supabase.from("policies").update({
          issuance_status: "provisional",
          provisional_issued_at: now,
        }).eq("id", policyId);
      }

      results.push({ policyId, outcome });
    }
  }

  return new Response(
    JSON.stringify({
      processed: results.length,
      results,
      ts: new Date().toISOString(),
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
