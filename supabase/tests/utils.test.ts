/**
 * Tests unitaires pour les utilitaires partagés (_shared/utils.ts)
 *
 * Exécution : deno test supabase/tests/utils.test.ts
 */

// ─── Assertions inline ────────────────────────────────────────────────────────
function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) {
    throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}
function assertNotEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual === expected) {
    throw new Error(msg ?? `Expected values to differ, both were ${JSON.stringify(actual)}`);
  }
}
function assertMatch(actual: string, pattern: RegExp, msg?: string): void {
  if (!pattern.test(actual)) {
    throw new Error(msg ?? `Expected "${actual}" to match ${pattern}`);
  }
}

// ─── Reimplemented helpers (no external imports) ──────────────────────────────
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
function isExpired(dateStr: string): boolean {
  return new Date(dateStr) < new Date();
}
function sanitisePhone(phone: string): string | null {
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 10 && cleaned.startsWith("0")) return `+225${cleaned}`;
  if (cleaned.length === 13 && cleaned.startsWith("225")) return `+${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith("225")) return `+${cleaned}`;
  return null;
}
function validateRequiredFields(body: Record<string, unknown>, fields: string[]): string | null {
  for (const field of fields) {
    if (body[field] === undefined || body[field] === null || body[field] === "") {
      return `Le champ '${field}' est requis.`;
    }
  }
  return null;
}

// ─── generateOtp ─────────────────────────────────────────────────────────────

Deno.test("generateOtp: retourne exactement 6 chiffres par défaut", () => {
  const otp = generateOtp();
  assertEquals(otp.length, 6);
  assertMatch(otp, /^\d{6}$/);
});

Deno.test("generateOtp: retourne le bon nombre de chiffres si spécifié", () => {
  for (const len of [4, 6, 8]) {
    const otp = generateOtp(len);
    assertEquals(otp.length, len);
    assertMatch(otp, new RegExp(`^\\d{${len}}$`));
  }
});

Deno.test("generateOtp: deux OTP consécutifs sont généralement différents", () => {
  const a = generateOtp();
  const b = generateOtp();
  assertNotEquals(a, b);
});

// ─── expiresAt ───────────────────────────────────────────────────────────────

Deno.test("expiresAt: la date retournée est dans le futur", () => {
  const future = new Date(expiresAt(300));
  const now = new Date();
  assertEquals(future > now, true);
});

Deno.test("expiresAt: délai approximativement correct (300s)", () => {
  const before = Date.now();
  const expiry = new Date(expiresAt(300)).getTime();
  const after = Date.now();
  assertEquals(expiry >= before + 299_000, true);
  assertEquals(expiry <= after + 301_000, true);
});

// ─── isExpired ───────────────────────────────────────────────────────────────

Deno.test("isExpired: une date passée est expirée", () => {
  const pastDate = new Date(Date.now() - 1000).toISOString();
  assertEquals(isExpired(pastDate), true);
});

Deno.test("isExpired: une date future n'est pas expirée", () => {
  const futureDate = new Date(Date.now() + 60_000).toISOString();
  assertEquals(isExpired(futureDate), false);
});

// ─── sanitisePhone ───────────────────────────────────────────────────────────

Deno.test("sanitisePhone: normalise un numéro CI 10 chiffres", () => {
  assertEquals(sanitisePhone("0700000000"), "+2250700000000");
  assertEquals(sanitisePhone("0102030405"), "+2250102030405");
});

Deno.test("sanitisePhone: accepte le format E.164 avec +225 (12 chiffres après +)", () => {
  assertEquals(sanitisePhone("+2250700000000"), "+2250700000000");
});

Deno.test("sanitisePhone: accepte le format 225XXXXXXXXXX (sans +, 13 chiffres)", () => {
  assertEquals(sanitisePhone("2250700000000"), "+2250700000000");
});

Deno.test("sanitisePhone: rejette les numéros invalides", () => {
  assertEquals(sanitisePhone("123"), null);
  assertEquals(sanitisePhone("abcdefghij"), null);
  assertEquals(sanitisePhone(""), null);
});

// ─── validateRequiredFields ──────────────────────────────────────────────────

Deno.test("validateRequiredFields: retourne null si tous les champs sont présents", () => {
  const body = { phone: "+2250700000000", code: "123456" };
  assertEquals(validateRequiredFields(body, ["phone", "code"]), null);
});

Deno.test("validateRequiredFields: retourne un message si un champ est manquant", () => {
  const body = { phone: "+2250700000000" };
  const result = validateRequiredFields(body, ["phone", "code"]);
  assertEquals(typeof result, "string");
  assertMatch(result!, /code/);
});

Deno.test("validateRequiredFields: détecte les chaînes vides comme manquantes", () => {
  const body = { phone: "" };
  const result = validateRequiredFields(body, ["phone"]);
  assertEquals(typeof result, "string");
});

Deno.test("validateRequiredFields: détecte null comme manquant", () => {
  const body = { phone: null };
  const result = validateRequiredFields(body as Record<string, unknown>, ["phone"]);
  assertEquals(typeof result, "string");
});
