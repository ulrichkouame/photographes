/**
 * Tests pour watermark
 * Exécution : deno test supabase/tests/watermark.test.ts
 */

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}
function assertMatch(actual: string, pattern: RegExp, msg?: string): void {
  if (!pattern.test(actual)) throw new Error(msg ?? `"${actual}" does not match ${pattern}`);
}
function assertStringIncludes(actual: string, expected: string, msg?: string): void {
  if (!actual.includes(expected)) throw new Error(msg ?? `"${actual}" does not include "${expected}"`);
}

async function sha256Hex(data: Uint8Array | string): Promise<string> {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  const hashBuffer = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hashBuffer)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.test("watermark: sha256Hex retourne un hash hexadécimal de 64 caractères", async () => {
  const hash = await sha256Hex("hello world");
  assertEquals(hash.length, 64);
  assertMatch(hash, /^[0-9a-f]{64}$/);
});

Deno.test("watermark: sha256Hex est déterministe", async () => {
  assertEquals(await sha256Hex("test"), await sha256Hex("test"));
});

Deno.test("watermark: sha256Hex de données différentes est différent", async () => {
  const h1 = await sha256Hex("abc");
  const h2 = await sha256Hex("def");
  assertEquals(h1 === h2, false);
});

Deno.test("watermark: construction de l'URL R2 publique", () => {
  function buildR2Url(publicUrl: string, path: string): string {
    return `${publicUrl.replace(/\/$/, "")}/${path}`;
  }
  assertEquals(
    buildR2Url("https://pub.r2.dev/photos", "watermarked/uuid/img.jpg"),
    "https://pub.r2.dev/photos/watermarked/uuid/img.jpg",
  );
  assertEquals(
    buildR2Url("https://pub.r2.dev/photos/", "thumbnails/uuid/img.jpg"),
    "https://pub.r2.dev/photos/thumbnails/uuid/img.jpg",
  );
});

Deno.test("watermark: génération du chemin de fichier watermarked et thumbnail", () => {
  const uid = "550e8400-e29b-41d4-a716-446655440000";
  const baseName = "portrait";
  const watermarkedPath = `watermarked/${uid}/${baseName}_watermarked.jpg`;
  const thumbnailPath = `thumbnails/${uid}/${baseName}_thumbnail.jpg`;
  assertStringIncludes(watermarkedPath, "watermarked");
  assertStringIncludes(watermarkedPath, "_watermarked.jpg");
  assertStringIncludes(thumbnailPath, "thumbnails");
  assertStringIncludes(thumbnailPath, "_thumbnail.jpg");
});

Deno.test("watermark: requête sans image_url ni storage_path est rejetée", () => {
  function validate(body: { image_url?: string; storage_path?: string }): string | null {
    if (!body.image_url && !body.storage_path) {
      return "Le champ 'image_url' ou 'storage_path' est requis.";
    }
    return null;
  }
  assertEquals(validate({}), "Le champ 'image_url' ou 'storage_path' est requis.");
  assertEquals(validate({ image_url: "https://example.com/img.jpg" }), null);
  assertEquals(validate({ storage_path: "photos/uuid/img.jpg" }), null);
});

Deno.test("watermark: extraction du nom de base depuis une URL", () => {
  function extractBaseName(imageUrl: string): string {
    const urlPath = new URL(imageUrl).pathname;
    return urlPath.split("/").pop()?.replace(/\.[^.]+$/, "") ?? "unknown";
  }
  assertEquals(extractBaseName("https://example.com/photos/portrait.jpg"), "portrait");
  assertEquals(extractBaseName("https://example.com/images/wedding-photo.png"), "wedding-photo");
});

Deno.test("watermark: extraction du nom de base depuis un storage_path", () => {
  function extractBaseNameFromPath(storagePath: string): string {
    return storagePath.split("/").pop()?.replace(/\.[^.]+$/, "") ?? "unknown";
  }
  assertEquals(extractBaseNameFromPath("photos/uuid/portrait.jpg"), "portrait");
  assertEquals(extractBaseNameFromPath("uploads/wedding.png"), "wedding");
});

Deno.test("watermark: validation de la config R2 complète", () => {
  function validateR2Config(config: {
    accountId?: string; accessKeyId?: string; secretKey?: string;
    bucketName?: string; publicUrl?: string;
  }): boolean {
    return !!(config.accountId && config.accessKeyId && config.secretKey && config.bucketName && config.publicUrl);
  }
  assertEquals(validateR2Config({ accountId: "acc", accessKeyId: "key", secretKey: "secret", bucketName: "photos", publicUrl: "https://pub.r2.dev" }), true);
  assertEquals(validateR2Config({ accountId: "acc", accessKeyId: "key", bucketName: "photos", publicUrl: "https://pub.r2.dev" }), false);
});

Deno.test("watermark: AWS Signature V4 — hmac sha256", async () => {
  // Basic HMAC-SHA256 sanity check
  const key = new TextEncoder().encode("secret-key");
  const cryptoKey = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode("test-data"));
  const hex = Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
  assertEquals(hex.length, 64);
  assertMatch(hex, /^[0-9a-f]{64}$/);
});
