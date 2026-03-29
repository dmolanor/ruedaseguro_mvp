// ============================================================
// RS-048: BCV Exchange Rate Edge Function — Sprint 2A
// ============================================================
// Behaviour:
//   1. Check exchange_rates table for a rate < 60 min old.
//      If found → return immediately (cache hit, stale: false).
//   2. If stale or no entry → attempt to fetch from external APIs
//      (pydolarve → alcambio, in order).
//   3. If all external sources fail → return last known rate
//      with { stale: true } so Flutter shows "Tasa aproximada".
//   4. On a fresh fetch → insert a new row, return it.
//
// Response schema:
//   { rate: number, fetched_at: string, source: string,
//     stale: boolean, is_suspicious: boolean }
//
// Deploy: supabase functions deploy bcv-rate
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

const CACHE_TTL_MINUTES = 60;
const SUSPICION_THRESHOLD = 0.20; // 20% change from last stored rate

interface StoredRate {
  rate: number;
  fetched_at: string;
  source: string;
}

interface BcvResponse {
  rate: number;
  fetched_at: string;
  source: string;
  stale: boolean;
  is_suspicious: boolean;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ── Step 1: Check cache ──────────────────────────────────
    const cutoff = new Date(
      Date.now() - CACHE_TTL_MINUTES * 60 * 1000
    ).toISOString();

    const { data: cached } = await supabase
      .from("exchange_rates")
      .select("rate, fetched_at, source")
      .eq("currency_pair", "USD/VES")
      .gt("fetched_at", cutoff)
      .order("fetched_at", { ascending: false })
      .limit(1)
      .maybeSingle() as { data: StoredRate | null };

    if (cached) {
      // Cache hit — return without external call
      return json200({
        rate: cached.rate,
        fetched_at: cached.fetched_at,
        source: cached.source,
        stale: false,
        is_suspicious: false,
      });
    }

    // ── Step 2: Get last known rate for suspicion check ──────
    const { data: lastKnown } = await supabase
      .from("exchange_rates")
      .select("rate, fetched_at, source")
      .eq("currency_pair", "USD/VES")
      .order("fetched_at", { ascending: false })
      .limit(1)
      .maybeSingle() as { data: StoredRate | null };

    // ── Step 3: Try external sources ─────────────────────────
    let freshRate: number | null = null;
    let freshSource = "";
    let rawResponse: unknown = null;

    // Source A: pydolarve.org
    try {
      const res = await fetch(
        "https://pydolarve.org/api/v2/dollar?monitor=bcv",
        { signal: AbortSignal.timeout(8_000) }
      );
      if (res.ok) {
        const data = await res.json();
        rawResponse = data;
        if (typeof data?.price === "number" && data.price > 0) {
          freshRate = data.price;
          freshSource = "pydolarve_bcv";
        }
      }
    } catch (e) {
      console.warn("pydolarve failed:", e instanceof Error ? e.message : e);
    }

    // Source B: alcambio.app (fallback)
    if (!freshRate) {
      try {
        const res = await fetch("https://api.alcambio.app/graphql", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query: `{ getRates { BCV { rate } } }` }),
          signal: AbortSignal.timeout(8_000),
        });
        if (res.ok) {
          const data = await res.json();
          rawResponse = data;
          const r = data?.data?.getRates?.BCV?.rate;
          if (typeof r === "number" && r > 0) {
            freshRate = r;
            freshSource = "alcambio_bcv";
          }
        }
      } catch (e) {
        console.warn("alcambio failed:", e instanceof Error ? e.message : e);
      }
    }

    // ── Step 4: All external sources failed → return stale ───
    if (!freshRate) {
      if (lastKnown) {
        console.warn("All BCV sources failed. Returning stale rate.");
        return json200({
          rate: lastKnown.rate,
          fetched_at: lastKnown.fetched_at,
          source: lastKnown.source,
          stale: true,
          is_suspicious: false,
        });
      }
      // No cached rate at all — hard failure
      return new Response(
        JSON.stringify({
          error: "No BCV rate available",
          message: "All sources failed and no cached rate exists.",
        }),
        { status: 503, headers: CORS_HEADERS }
      );
    }

    // ── Step 5: Suspicion check ──────────────────────────────
    let isSuspicious = false;
    if (lastKnown?.rate) {
      const pct = Math.abs(freshRate - lastKnown.rate) / lastKnown.rate;
      if (pct > SUSPICION_THRESHOLD) {
        isSuspicious = true;
        console.warn(
          `Suspicious rate: ${lastKnown.rate} → ${freshRate} (${(pct * 100).toFixed(1)}%)`
        );
      }
    }

    // ── Step 6: Persist new rate ─────────────────────────────
    const fetchedAt = new Date().toISOString();
    const { error: insertError } = await supabase
      .from("exchange_rates")
      .insert({
        currency_pair: "USD/VES",
        rate: freshRate,
        source: freshSource,
        fetched_at: fetchedAt,
        is_official: true,
        raw_response: rawResponse,
      });

    if (insertError) {
      console.error("Failed to persist rate:", insertError);
      // Still return the fresh rate even if DB write failed
    }

    return json200({
      rate: freshRate,
      fetched_at: fetchedAt,
      source: freshSource,
      stale: false,
      is_suspicious: isSuspicious,
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: CORS_HEADERS }
    );
  }
});

function json200(body: BcvResponse): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: CORS_HEADERS,
  });
}
