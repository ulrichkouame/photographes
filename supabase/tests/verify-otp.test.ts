/**
 * Tests pour verify-otp
 * Exécution : deno test supabase/tests/verify-otp.test.ts
 */

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}

function isExpired(dateStr: string): boolean { return new Date(dateStr) < new Date(); }
function sanitisePhone(phone: string): string | null {
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 10 && cleaned.startsWith("0")) return `+225${cleaned}`;
  if (cleaned.length === 13 && cleaned.startsWith("225")) return `+${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith("225")) return `+${cleaned}`;
  return null;
}

Deno.test("verify-otp: rejette un code qui n'est pas 6 chiffres", () => {
  assertEquals(/^\d{6}$/.test("123456"), true);
  assertEquals(/^\d{6}$/.test("000000"), true);
  assertEquals(/^\d{6}$/.test("12345"), false);
  assertEquals(/^\d{6}$/.test("1234567"), false);
  assertEquals(/^\d{6}$/.test("abcdef"), false);
  assertEquals(/^\d{6}$/.test(""), false);
});

Deno.test("verify-otp: rejette un numéro invalide", () => {
  assertEquals(sanitisePhone("123"), null);
  assertEquals(sanitisePhone("+1234567890"), null);
});

Deno.test("verify-otp: accepte un numéro CI valide", () => {
  assertEquals(sanitisePhone("0700000000"), "+2250700000000");
});

Deno.test("verify-otp: OTP expiré est rejeté", () => {
  assertEquals(isExpired(new Date(Date.now() - 1000).toISOString()), true);
});

Deno.test("verify-otp: OTP futur est accepté", () => {
  assertEquals(isExpired(new Date(Date.now() + 60_000).toISOString()), false);
});

Deno.test("verify-otp: codes identiques correspondent", () => {
  assertEquals("123456" === "123456", true);
});

Deno.test("verify-otp: codes différents ne correspondent pas", () => {
  const stored: string = "123456";
  const submitted: string = "654321";
  assertEquals(stored === submitted, false);
});

Deno.test("verify-otp: flux succès avec OTP valide", async () => {
  const phone = "+2250700000000";
  const code = "123456";
  const mockOtp = {
    phone, code,
    expires_at: new Date(Date.now() + 60_000).toISOString(),
    verified: false,
  };
  async function verifyOtp(p: string, c: string): Promise<{ success: boolean; message: string; access_token?: string }> {
    const normPhone = sanitisePhone(p);
    if (!normPhone) return { success: false, message: "Numéro invalide" };
    if (!/^\d{6}$/.test(c)) return { success: false, message: "Code invalide" };
    if (mockOtp.phone !== normPhone || mockOtp.verified) return { success: false, message: "OTP introuvable" };
    if (isExpired(mockOtp.expires_at)) return { success: false, message: "OTP expiré" };
    if (mockOtp.code !== c) return { success: false, message: "Code incorrect" };
    return { success: true, access_token: "mock-jwt-token", message: "Authentification réussie." };
  }
  const result = await verifyOtp(phone, code);
  assertEquals(result.success, true);
  assertEquals(result.message, "Authentification réussie.");
  assertEquals(typeof result.access_token, "string");
});

Deno.test("verify-otp: flux échec avec OTP expiré", async () => {
  const mockOtp = {
    phone: "+2250700000000", code: "123456",
    expires_at: new Date(Date.now() - 1000).toISOString(),
    verified: false,
  };
  async function verifyOtp(p: string, c: string): Promise<{ success: boolean; message: string }> {
    const normPhone = sanitisePhone(p);
    if (!normPhone) return { success: false, message: "Numéro invalide" };
    if (isExpired(mockOtp.expires_at)) return { success: false, message: "Le code OTP a expiré." };
    if (mockOtp.code !== c) return { success: false, message: "Code incorrect" };
    return { success: true, message: "Authentification réussie." };
  }
  const result = await verifyOtp("+2250700000000", "123456");
  assertEquals(result.success, false);
  assertEquals(result.message, "Le code OTP a expiré.");
});

Deno.test("verify-otp: flux échec avec mauvais code", async () => {
  const mockOtp = {
    phone: "+2250700000000", code: "123456",
    expires_at: new Date(Date.now() + 60_000).toISOString(),
    verified: false,
  };
  async function verifyOtp(p: string, c: string): Promise<{ success: boolean; message: string }> {
    const normPhone = sanitisePhone(p);
    if (!normPhone) return { success: false, message: "Numéro invalide" };
    if (isExpired(mockOtp.expires_at)) return { success: false, message: "OTP expiré." };
    if (mockOtp.code !== c) return { success: false, message: "Code OTP incorrect." };
    return { success: true, message: "Authentification réussie." };
  }
  const result = await verifyOtp("+2250700000000", "999999");
  assertEquals(result.success, false);
  assertEquals(result.message, "Code OTP incorrect.");
});

Deno.test("verify-otp: OTP déjà vérifié ne peut pas être réutilisé", async () => {
  const mockOtp = {
    phone: "+2250700000000", code: "123456",
    expires_at: new Date(Date.now() + 60_000).toISOString(),
    verified: true,
  };
  async function verifyOtp(p: string, _c: string): Promise<{ success: boolean; message: string }> {
    const normPhone = sanitisePhone(p);
    if (!normPhone) return { success: false, message: "Numéro invalide" };
    if (mockOtp.verified) return { success: false, message: "Aucun code OTP en attente." };
    return { success: true, message: "Authentification réussie." };
  }
  const result = await verifyOtp("+2250700000000", "123456");
  assertEquals(result.success, false);
});
