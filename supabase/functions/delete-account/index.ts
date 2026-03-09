// Supabase Edge Function: delete-account
// Deletes the caller's app data (best-effort) and then deletes the Auth user.
// Requires secrets:
// - SUPABASE_URL
// - SUPABASE_ANON_KEY
// - SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function buildCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Vary": "Origin",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, x-supabase-authorization",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function stripBearer(value: string): string {
  const v = value.trim();
  return v.toLowerCase().startsWith("bearer ") ? v.slice(7).trim() : v;
}

function looksLikeJwt(token: string): boolean {
  const t = token.trim();
  // JWTs are 3 base64url segments separated by dots.
  const parts = t.split(".");
  return parts.length === 3 && parts.every((p) => p.length > 10);
}

Deno.serve(async (req) => {
  const corsHeaders = buildCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Note: Supabase reserves the `SUPABASE_` prefix for platform-provided vars.
  // The CLI blocks setting secrets that start with `SUPABASE_`, so we support
  // custom names that you can set via `supabase secrets set`.
  const supabaseUrl =
    Deno.env.get("SUPABASE_URL") ?? Deno.env.get("PROJECT_URL") ?? "";
  const anonKey =
    Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("ANON_KEY") ?? "";
  const serviceRoleKey =
    Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return new Response(
      JSON.stringify({
        error:
          "Missing required secrets. Set PROJECT_URL, ANON_KEY, SERVICE_ROLE_KEY (or ensure SUPABASE_URL/SUPABASE_ANON_KEY are available).",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  // On web, the Supabase gateway may place tokens in different headers.
  // Prefer the value that actually looks like a JWT.
  const authCandidates: Array<{ source: string; value: string }> = [
    { source: "authorization", value: req.headers.get("authorization") ?? "" },
    { source: "x-supabase-authorization", value: req.headers.get("x-supabase-authorization") ?? "" },
  ].filter((c) => c.value.trim().length > 0);

  const chosen = authCandidates.find((c) => looksLikeJwt(stripBearer(c.value))) ?? authCandidates[0];
  const chosenToken = chosen ? stripBearer(chosen.value) : "";
  const authHeader = chosenToken ? `Bearer ${chosenToken}` : "";

  // Client bound to the caller's JWT (so we can reliably identify the user)
  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response(
      JSON.stringify({
        error: "Unauthorized: no valid user session",
        details: userError?.message ?? null,
        debug: {
          usedHeader: chosen?.source ?? null,
          hasAuthorization: req.headers.has("authorization"),
          hasXSupabaseAuthorization: req.headers.has("x-supabase-authorization"),
          authLooksJwt: chosenToken ? looksLikeJwt(chosenToken) : false,
          authLength: chosenToken.length,
        },
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  // Admin client (service role) to delete rows + delete auth user.
  const admin = createClient(supabaseUrl, serviceRoleKey);

  // 1) Delete app data (best-effort; keep scoped to this user's identifiers).
  // Your app stores a profile row in table `user` keyed by email.
  // If you have more tables (chat, progress, etc.), add deletions here.
  try {
    if (user.email) {
      await admin.from("user").delete().eq("email", user.email);
    }
  } catch (_) {
    // ignore: app data deletion may fail depending on schema/policies
  }

  // 2) Delete the auth user (this is the critical part).
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return new Response(
      JSON.stringify({ error: "Failed to delete auth user", details: deleteError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
