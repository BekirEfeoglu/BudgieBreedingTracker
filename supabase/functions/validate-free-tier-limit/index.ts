import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const LIMITS: Record<string, number> = {
  birds: 15,
  breeding_pairs: 5,
  incubations: 3,
};

serve(async (req) => {
  try {
    const { table, user_id } = await req.json();

    if (!table || !user_id) {
      return new Response(
        JSON.stringify({ error: "Missing table or user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const limit = LIMITS[table];
    if (!limit) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium, role")
      .eq("id", user_id)
      .single();

    if (
      profile?.is_premium ||
      profile?.role === "admin" ||
      profile?.role === "founder"
    ) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    let query = supabase
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("user_id", user_id)
      .eq("is_deleted", false);

    if (table === "breeding_pairs") {
      query = query.in("status", ["active", "ongoing"]);
    }
    if (table === "incubations") {
      query = query.eq("status", "active");
    }

    const { count } = await query;
    const allowed = (count ?? 0) < limit;

    return new Response(
      JSON.stringify({ allowed, count, limit }),
      {
        status: allowed ? 200 : 403,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
