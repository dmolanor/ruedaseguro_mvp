// ============================================================
// RS-018: BCV Exchange Rate Edge Function
// ============================================================
// Deploy: supabase functions deploy bcv-rate
// Invoke: supabase functions invoke bcv-rate
// Schedule: pg_cron every 30 minutes or external cron
// ============================================================
// File: supabase/functions/bcv-rate/index.ts
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RateResponse {
  rate: number;
  fetched_at: string;
  source: string;
  is_suspicious: boolean;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    let rate: number | null = null;
    let source = "";
    let rawResponse: unknown = null;

    // --- Strategy 1: pydolarve.org community API ---
    try {
      const res = await fetch(
        "https://pydolarve.org/api/v2/dollar?monitor=bcv",
        { signal: AbortSignal.timeout(10000) }
      );
      if (res.ok) {
        const data = await res.json();
        rawResponse = data;
        // pydolarve returns { "price": 78.50, ... } or similar structure
        if (data?.price && typeof data.price === "number" && data.price > 0) {
          rate = data.price;
          source = "pydolarve_bcv";
        }
      }
    } catch (e) {
      console.warn("pydolarve fetch failed:", e);
    }

    // --- Strategy 2: alcambio.app API (fallback) ---
    if (!rate) {
      try {
        const res = await fetch("https://api.alcambio.app/graphql", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            query: `{ getRates { BCV { rate } } }`,
          }),
          signal: AbortSignal.timeout(10000),
        });
        if (res.ok) {
          const data = await res.json();
          rawResponse = data;
          const bcvRate = data?.data?.getRates?.BCV?.rate;
          if (bcvRate && typeof bcvRate === "number" && bcvRate > 0) {
            rate = bcvRate;
            source = "alcambio_bcv";
          }
        }
      } catch (e) {
        console.warn("alcambio fetch failed:", e);
      }
    }

    // --- No rate obtained ---
    if (!rate || rate <= 0) {
      return new Response(
        JSON.stringify({
          error: "All BCV rate sources failed",
          message:
            "Could not fetch USD/VES rate from any source. Try again later.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // --- Suspicion check: compare with last stored rate ---
    let isSuspicious = false;
    const { data: lastRate } = await supabase
      .from("exchange_rates")
      .select("rate")
      .eq("currency_pair", "USD/VES")
      .order("fetched_at", { ascending: false })
      .limit(1)
      .single();

    if (lastRate?.rate) {
      const pctChange =
        Math.abs(rate - lastRate.rate) / lastRate.rate;
      if (pctChange > 0.2) {
        isSuspicious = true;
        console.warn(
          `Suspicious rate change: ${lastRate.rate} → ${rate} (${(pctChange * 100).toFixed(1)}% change)`
        );
      }
    }

    // --- Insert new rate ---
    const fetchedAt = new Date().toISOString();
    const { error: insertError } = await supabase
      .from("exchange_rates")
      .insert({
        currency_pair: "USD/VES",
        rate,
        source,
        fetched_at: fetchedAt,
        is_official: true,
        raw_response: rawResponse,
      });

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to store rate", details: insertError }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const response: RateResponse = {
      rate,
      fetched_at: fetchedAt,
      source,
      is_suspicious: isSuspicious,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
