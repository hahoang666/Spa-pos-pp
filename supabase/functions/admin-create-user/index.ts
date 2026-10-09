// Supabase Edge Function: create a Spa POS login account.
// Deploy with: supabase functions deploy admin-create-user
// Required secret: SUPABASE_SERVICE_ROLE_KEY (server-side only; never put it in index.html).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return json({ error: "SERVER_CONFIGURATION_MISSING" }, 500);
  }

  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "UNAUTHORIZED" }, 401);

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: callerData, error: callerError } = await callerClient.auth.getUser(token);
  if (callerError || !callerData.user) return json({ error: "UNAUTHORIZED" }, 401);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Authorization is based on the role code stored in Supabase, never a frontend role ID.
  const { data: callerProfile, error: callerProfileError } = await admin
    .from("profiles")
    .select("role_id,is_active")
    .eq("id", callerData.user.id)
    .maybeSingle();
  if (callerProfileError) return json({ error: "CALLER_PROFILE_LOOKUP_FAILED", detail: callerProfileError.message }, 500);
  if (!callerProfile || callerProfile.is_active !== true) return json({ error: "FORBIDDEN" }, 403);

  const { data: callerRole, error: callerRoleError } = await admin
    .from("roles")
    .select("code")
    .eq("id", callerProfile.role_id)
    .maybeSingle();
  if (callerRoleError) return json({ error: "CALLER_ROLE_LOOKUP_FAILED", detail: callerRoleError.message }, 500);
  if (callerRole?.code !== "ADMIN") return json({ error: "FORBIDDEN" }, 403);

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ error: "INVALID_JSON" }, 400); }
  const username = String(body.username ?? "").trim().toLowerCase();
  const fullName = String(body.full_name ?? "").trim();
  const password = String(body.password ?? "");
  const roleId = body.role_id;

  if (!/^[a-z0-9][a-z0-9._-]{2,31}$/.test(username)) {
    return json({ error: "INVALID_USERNAME", detail: "Tên đăng nhập phải có 3–32 ký tự: chữ thường, số, dấu chấm, gạch dưới hoặc gạch ngang." }, 400);
  }
  if (!fullName || fullName.length > 120) return json({ error: "INVALID_FULL_NAME" }, 400);
  if (password.length < 8) return json({ error: "PASSWORD_TOO_SHORT" }, 400);
  if (roleId === undefined || roleId === null || String(roleId) === "") return json({ error: "ROLE_REQUIRED" }, 400);

  const { data: role, error: roleError } = await admin
    .from("roles")
    .select("id,code,name")
    .eq("id", roleId)
    .maybeSingle();
  if (roleError) return json({ error: "ROLE_LOOKUP_FAILED", detail: roleError.message }, 500);
  if (!role) return json({ error: "ROLE_NOT_FOUND" }, 400);

  const { data: existing, error: existingError } = await admin
    .from("profiles")
    .select("id")
    .ilike("username", username)
    .maybeSingle();
  if (existingError) return json({ error: "USERNAME_LOOKUP_FAILED", detail: existingError.message }, 500);
  if (existing) return json({ error: "USERNAME_EXISTS" }, 409);

  // Supabase password auth requires an email identifier. This internal address maps
  // to the short username; it is not presented as the user's contact email.
  const syntheticEmail = `${username}@spa-pos.local`;
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: syntheticEmail,
    password,
    email_confirm: true,
    user_metadata: { username, full_name: fullName },
  });
  if (createError || !created.user) {
    return json({ error: "AUTH_USER_CREATE_FAILED", detail: createError?.message || "No user returned" }, 400);
  }

  // Live project schema uses profiles.full_name and bigint role IDs.
  const { error: profileInsertError } = await admin.from("profiles").insert({
    id: created.user.id,
    username,
    full_name: fullName,
    role_id: role.id,
    is_active: true,
    employee_id: null,
  });
  if (profileInsertError) {
    await admin.auth.admin.deleteUser(created.user.id);
    return json({ error: "PROFILE_CREATE_FAILED", detail: profileInsertError.message }, 400);
  }

  return json({
    user: { id: created.user.id, username, full_name: fullName, role_id: role.id, role_name: role.name },
  }, 201);
});
