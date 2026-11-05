import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceKey) return json({ error: "Teacher invitation service is not configured." }, 503);

  const authorization = req.headers.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) return json({ error: "Sign in first." }, 401);
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return json({ error: "Your session is invalid or expired." }, 401);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

  try {
    const body = await req.json();

    if (body.action === "create_invite") {
      const teacherId = String(body.teacher_id || "");
      const email = String(body.email || "").trim().toLowerCase();
      if (!teacherId || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        return json({ error: "Choose a teacher and enter a valid email address." }, 400);
      }
      const { data: teacher, error: teacherError } = await admin.from("school_teachers")
        .select("id,full_name").eq("id", teacherId).eq("user_id", user.id).maybeSingle();
      if (teacherError || !teacher) return json({ error: "Teacher record not found in your school." }, 404);

      const token = Array.from(crypto.getRandomValues(new Uint8Array(18)))
        .map((b) => b.toString(16).padStart(2, "0")).join("");
      const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString();
      const { error: accountError } = await admin.from("school_teacher_accounts").upsert({
        user_id: user.id, teacher_id: teacherId, auth_user_id: null,
        account_status: "pending", updated_at: new Date().toISOString(),
      }, { onConflict: "user_id,teacher_id" });
      if (accountError) throw accountError;

      await admin.from("school_teacher_invites").delete()
        .eq("user_id", user.id).eq("teacher_id", teacherId).is("claimed_at", null);
      const { error: inviteError } = await admin.from("school_teacher_invites").insert({
        user_id: user.id, teacher_id: teacherId, email, token_hash: await sha256(token), expires_at: expiresAt,
      });
      if (inviteError) throw inviteError;
      return json({ invite_code: token, expires_at: expiresAt, teacher_name: teacher.full_name, email });
    }

    if (body.action === "claim_invite") {
      const token = String(body.invite_code || "").trim().toLowerCase();
      if (!/^[a-f0-9]{36}$/.test(token)) return json({ error: "Enter the complete teacher invitation code." }, 400);
      const { data: invite, error: inviteError } = await admin.from("school_teacher_invites")
        .select("id,user_id,teacher_id,email,expires_at,claimed_at")
        .eq("token_hash", await sha256(token)).maybeSingle();
      if (inviteError || !invite || invite.claimed_at || new Date(invite.expires_at).getTime() < Date.now()) {
        return json({ error: "This invitation code is invalid, expired or already used." }, 400);
      }
      if ((user.email || "").toLowerCase() !== invite.email.toLowerCase()) {
        return json({ error: "Sign up or sign in using the email address the school invited." }, 403);
      }

      const claimedAt = new Date().toISOString();
      const { data: claimed, error: claimError } = await admin.from("school_teacher_invites")
        .update({ claimed_at: claimedAt }).eq("id", invite.id).is("claimed_at", null).select("id").maybeSingle();
      if (claimError || !claimed) return json({ error: "This invitation has already been claimed." }, 409);

      const { error: linkError } = await admin.from("school_teacher_accounts").update({
        auth_user_id: user.id, account_status: "active", updated_at: claimedAt,
      }).eq("user_id", invite.user_id).eq("teacher_id", invite.teacher_id);
      if (linkError) {
        await admin.from("school_teacher_invites").update({ claimed_at: null }).eq("id", invite.id);
        throw linkError;
      }
      return json({ success: true, school_owner_id: invite.user_id, teacher_id: invite.teacher_id });
    }

    return json({ error: "Unknown action." }, 400);
  } catch (error) {
    console.error("school-teacher-access:", error);
    return json({ error: "The teacher account request could not be completed." }, 500);
  }
});