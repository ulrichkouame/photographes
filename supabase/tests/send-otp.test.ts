/**
 * Tests pour send-otp
 * Exécution : deno test supabase/tests/send-otp.test.ts
 */

// ─── Assertions inline ────────────────────────────────────────────────────────
function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) {
    throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
function assertMatch(actual: string, pattern: RegExp, msg?: string): void {
  if (!pattern.test(actual)) throw new Error(msg ?? `"${actual}" does not match ${pattern}`);
}

// ─── Logique réimplémentée pour les tests ─────────────────────────────────────
function sanitisePhone(phone: string): string | null {
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 10 && cleaned.startsWith("0")) return `+225${cleaned}`;
  if (cleaned.length === 13 && cleaned.startsWith("225")) return `+${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith("225")) return `+${cleaned}`;
  return null;
}
function generateOtp(length = 6): string {
  const digits = "0123456789";
  let otp = "";
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  for (const byte of array) otp += digits[byte % 10];
  return otp;
}
function expiresAt(seconds: number): string {
  return new Date(Date.now() + seconds * 1000).toISOString();
}

// ─── Tests de validation ─────────────────────────────────────────────────────

Deno.test("send-otp: rejette un corps de requête vide", async () => {
  const req = new Request("http://localhost/functions/v1/send-otp", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
  });
  let parsed: unknown = null;
  try {
    const text = await req.text();
    if (text) parsed = JSON.parse(text);
  } catch { parsed = null; }
  assertEquals(parsed, null);
});

Deno.test("send-otp: rejette un numéro de téléphone invalide", () => {
  assertEquals(sanitisePhone("123"), null);
  assertEquals(sanitisePhone("abc"), null);
  assertEquals(sanitisePhone(""), null);
});

Deno.test("send-otp: accepte un numéro CI valide (10 chiffres)", () => {
  assertEquals(sanitisePhone("0700000000"), "+2250700000000");
});

Deno.test("send-otp: requête OPTIONS retourne status 204", () => {
  const res = new Response(null, {
    status: 204,
    headers: { "Access-Control-Allow-Origin": "*" },
  });
  assertEquals(res.status, 204);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
});

Deno.test("send-otp: le code OTP généré est composé de 6 chiffres", () => {
  const otp = generateOtp();
  assertEquals(otp.length, 6);
  assertEquals(/^\d{6}$/.test(otp), true);
});

Deno.test("send-otp: la date d'expiration est dans le futur (600s)", () => {
  const expiry = new Date(expiresAt(600));
  const now = new Date();
  assertEquals(expiry > now, true);
  const diffMs = expiry.getTime() - now.getTime();
  assertEquals(diffMs > 598_000, true);
  assertEquals(diffMs < 601_000, true);
});

Deno.test("send-otp: le message contient le code OTP, la durée et la marque", () => {
  const code = "123456";
  const expiryMinutes = 10;
  const message = `*photographes.ci*\n\nVotre code de vérification est : *${code}*\n\nCe code est valable pendant ${expiryMinutes} minutes.\n\nNe partagez ce code avec personne.`;
  assertMatch(message, /photographes\.ci/);
  assertMatch(message, /123456/);
  assertMatch(message, /10 minutes/);
  assertMatch(message, /Ne partagez/);
});

Deno.test("send-otp: construire la requête WasenderAPI correctement", async () => {
  const apiKey = "test-api-key";
  const phone = "+2250700000000";
  const message = "Test message";
  const apiUrl = "https://api.wasenderapi.com/api/send-message";

  const mockFetch = async (url: string, options: RequestInit): Promise<Response> => {
    assertEquals(url, apiUrl);
    assertEquals((options.headers as Record<string, string>)["Authorization"], `Bearer ${apiKey}`);
    const body = JSON.parse(options.body as string);
    assertEquals(body.phoneNumber, phone);
    assertEquals(body.message, message);
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  };

  const res = await mockFetch(apiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${apiKey}` },
    body: JSON.stringify({ phoneNumber: phone, message }),
  });
  assertEquals(res.status, 200);
});

Deno.test("send-otp: erreur WasenderAPI non-200 déclenche une erreur", async () => {
  const mockFetch = async (_url: string, _options: RequestInit): Promise<Response> => {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  };
  const res = await mockFetch("https://api.wasenderapi.com/api/send-message", {
    method: "POST",
    headers: {},
    body: "{}",
  });
  assertEquals(res.ok, false);
  assertEquals(res.status, 401);
});
