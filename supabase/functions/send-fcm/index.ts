// Edge Function: gửi push FCM tới một người dùng.
//
// Triển khai:
//   1. supabase functions deploy send-fcm
//   2. supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat serviceAccount.json)"
//      (Firebase Console > Project settings > Service accounts > Generate new private key)
//   SUPABASE_URL và SUPABASE_SERVICE_ROLE_KEY được Supabase tự cung cấp.
//
// Gọi: POST { userId, title, body, data? } -> tra users.fcm_token rồi gọi FCM HTTP v1.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const b64url = (b: ArrayBuffer | string) => {
  const bytes = typeof b === "string" ? new TextEncoder().encode(b) : new Uint8Array(b);
  let s = "";
  bytes.forEach((c) => (s += String.fromCharCode(c)));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

async function getAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  )}`;
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${b64url(sig)}`,
    }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`OAuth lỗi: ${JSON.stringify(json)}`);
  return json.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const reply = (obj: unknown, status = 200) =>
    new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });
  try {
    const { userId, title, body, data } = await req.json();
    if (!userId) return reply({ error: "Thiếu userId" }, 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: user } = await supabase.from("users").select("fcm_token").eq("id", userId).maybeSingle();
    if (!user?.fcm_token) return reply({ sent: false, reason: "Người dùng chưa có fcm_token" });

    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const accessToken = await getAccessToken(sa);
    // FCM yêu cầu mọi giá trị trong data là chuỗi.
    const strData: Record<string, string> = {};
    for (const [k, v] of Object.entries(data ?? {})) strData[k] = String(v);

    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: { token: user.fcm_token, notification: { title, body }, data: strData },
      }),
    });
    return reply({ sent: res.ok, result: await res.json() }, res.ok ? 200 : 502);
  } catch (e) {
    return reply({ error: String(e) }, 500);
  }
});
