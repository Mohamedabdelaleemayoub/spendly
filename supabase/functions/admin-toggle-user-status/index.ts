import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 1. Verify caller session
    const supabaseUserClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user: callerUser }, error: userError } = await supabaseUserClient.auth.getUser();
    if (userError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Invalid authentication session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Verify caller is an active Admin
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role, status")
      .eq("id", callerUser.id)
      .single();

    if (profileError || !callerProfile || callerProfile.role !== "admin" || callerProfile.status !== "active") {
      return new Response(
        JSON.stringify({ error: "Unauthorized. Admin privileges required." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Parse target user_id and new status
    const { user_id, status } = await req.json();

    if (!user_id || !status || (status !== "active" && status !== "inactive")) {
      return new Response(
        JSON.stringify({ error: "user_id and valid status ('active' | 'inactive') are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. If deactivating, prevent deactivating oneself
    if (status === "inactive") {
      if (user_id === callerUser.id) {
        return new Response(
          JSON.stringify({ error: "You cannot deactivate your own admin account." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Also prevent deactivating the last active admin
      const { data: targetProfile } = await supabaseAdmin
        .from("profiles")
        .select("role, status")
        .eq("id", user_id)
        .single();

      if (targetProfile?.role === "admin" && targetProfile?.status === "active") {
        const { count } = await supabaseAdmin
          .from("profiles")
          .select("*", { count: "exact", head: true })
          .eq("role", "admin")
          .eq("status", "active");

        if (count !== null && count <= 1) {
          return new Response(
            JSON.stringify({ error: "Cannot deactivate the last active administrator." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }
    }

    // 5. Update public.profiles.status
    const { data: updatedProfile, error: updateError } = await supabaseAdmin
      .from("profiles")
      .update({ status })
      .eq("id", user_id)
      .select()
      .single();

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: updatedProfile.id,
          status: updatedProfile.status,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
