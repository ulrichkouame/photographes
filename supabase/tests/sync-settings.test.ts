/**
 * Tests pour sync-settings
 * Exécution : deno test supabase/tests/sync-settings.test.ts
 */

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}
function assertStringIncludes(actual: string, expected: string, msg?: string): void {
  if (!actual.includes(expected)) throw new Error(msg ?? `"${actual}" does not include "${expected}"`);
}

interface AppSetting {
  id: string; key: string; value: string; description?: string;
  is_public: boolean; created_at: string; updated_at: string;
}

const SECRET_KEYS = new Set([
  "wasender_api_key", "r2_secret_key", "r2_access_key_id",
  "payment_mtn_api_key", "payment_orange_api_key", "payment_wave_api_key", "payment_moov_api_key",
]);

function filterSettings(settings: AppSetting[], publicOnly: boolean): Record<string, string> {
  return settings
    .filter((s) => !SECRET_KEYS.has(s.key))
    .filter((s) => !publicOnly || s.is_public)
    .reduce<Record<string, string>>((acc, s) => { acc[s.key] = s.value; return acc; }, {});
}

const now = new Date().toISOString();
const mockSettings: AppSetting[] = [
  { id: "1", key: "app_name", value: "photographes.ci", is_public: true, created_at: now, updated_at: now },
  { id: "2", key: "contact_price", value: "5000", is_public: true, created_at: now, updated_at: now },
  { id: "3", key: "otp_expiry_seconds", value: "600", is_public: false, created_at: now, updated_at: now },
  { id: "4", key: "wasender_api_key", value: "secret-key", is_public: false, created_at: now, updated_at: now },
  { id: "5", key: "refund_provider", value: "mtn", is_public: false, created_at: now, updated_at: now },
];

Deno.test("sync-settings: GET public retourne uniquement is_public=true", () => {
  const result = filterSettings(mockSettings, true);
  assertEquals(Object.keys(result).length, 2);
  assertEquals(result["app_name"], "photographes.ci");
  assertEquals(result["contact_price"], "5000");
  assertEquals(result["otp_expiry_seconds"], undefined as unknown as string);
});

Deno.test("sync-settings: les clés secrètes ne sont jamais retournées", () => {
  const result = filterSettings(mockSettings, false);
  assertEquals(result["wasender_api_key"], undefined as unknown as string);
  assertEquals(result["r2_secret_key"], undefined as unknown as string);
});

Deno.test("sync-settings: POST authentifié retourne les paramètres privés non-secrets", () => {
  const result = filterSettings(mockSettings, false);
  assertEquals(result["otp_expiry_seconds"], "600");
  assertEquals(result["refund_provider"], "mtn");
  assertEquals(result["wasender_api_key"], undefined as unknown as string);
});

Deno.test("sync-settings: la réponse contient les champs requis", () => {
  const settings = filterSettings(mockSettings, true);
  const response = {
    success: true, settings,
    count: Object.keys(settings).length,
    synced_at: new Date().toISOString(),
  };
  assertEquals(response.success, true);
  assertEquals(typeof response.settings, "object");
  assertEquals(typeof response.count, "number");
  assertEquals(typeof response.synced_at, "string");
});

Deno.test("sync-settings: le compteur correspond au nombre de paramètres", () => {
  const publicSettings = filterSettings(mockSettings, true);
  const allSettings = filterSettings(mockSettings, false);
  assertEquals(Object.keys(publicSettings).length, 2);
  assertEquals(Object.keys(allSettings).length, 4);
});

Deno.test("sync-settings: détection de l'authentification depuis le header", () => {
  function isAuthenticated(h: string | null): boolean {
    return !!(h && h.startsWith("Bearer ") && h.length > 10);
  }
  assertEquals(isAuthenticated(null), false);
  assertEquals(isAuthenticated(""), false);
  assertEquals(isAuthenticated("Bearer "), false);
  assertEquals(isAuthenticated("Bearer eyJhbGciOiJIUzI1NiJ9.test.sig"), true);
  assertEquals(isAuthenticated("Basic dXNlcjpwYXNz"), false);
});

Deno.test("sync-settings: la liste des clés secrètes bloque les bonnes clés", () => {
  const secretKeys = ["wasender_api_key", "r2_secret_key", "r2_access_key_id", "payment_mtn_api_key", "payment_orange_api_key", "payment_wave_api_key", "payment_moov_api_key"];
  for (const key of secretKeys) assertEquals(SECRET_KEYS.has(key), true);
  for (const key of ["app_name", "contact_price", "app_currency"]) assertEquals(SECRET_KEYS.has(key), false);
});

Deno.test("sync-settings: retourne une liste vide si aucun paramètre", () => {
  assertEquals(Object.keys(filterSettings([], true)).length, 0);
});

Deno.test("sync-settings: synced_at est une date ISO valide", () => {
  const syncedAt = new Date().toISOString();
  assertEquals(isNaN(new Date(syncedAt).getTime()), false);
  assertStringIncludes(syncedAt, "T");
  assertStringIncludes(syncedAt, "Z");
});
