/**
 * watermark — Ajout d'un watermark «photographes.ci» sur une image,
 *             génération d'une miniature 400px et upload vers Cloudflare R2
 *
 * POST /functions/v1/watermark
 * Headers: Authorization: Bearer <jwt>
 * Body: { "image_url": "https://..." }
 *    ou { "storage_path": "photos/uuid/original.jpg" }
 *
 * Dépendances (app_settings) :
 *   - r2_account_id    : Cloudflare account ID
 *   - r2_access_key_id : R2 Access Key ID
 *   - r2_secret_key    : R2 Secret Access Key
 *   - r2_bucket_name   : Nom du bucket R2
 *   - r2_public_url    : URL publique du bucket (ex: https://pub.r2.dev/bucket)
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient, getAppSetting } from "../_shared/supabase.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  parseJsonBody,
  validateRequiredFields,
} from "../_shared/utils.ts";
import type { WatermarkRequest, WatermarkResponse } from "../_shared/types.ts";

// ─── Image Processing (via @cf-wasm/photon on Deno) ──────────────────────────

/**
 * Draw a centred semi-transparent watermark text onto raw RGBA pixel data.
 * Uses the Canvas API available in Deno Deploy / Supabase Edge runtime.
 */
async function applyWatermarkAndThumbnail(
  originalBytes: Uint8Array,
  contentType: string,
): Promise<{ watermarked: Uint8Array; thumbnail: Uint8Array }> {
  // Decode original image using the browser-compatible ImageBitmap API
  const originalBlob = new Blob([originalBytes], { type: contentType });
  const imageBitmap = await createImageBitmap(originalBlob);

  const { width, height } = imageBitmap;

  // ── Full-size watermarked image ────────────────────────────────────────────
  const fullCanvas = new OffscreenCanvas(width, height);
  const fullCtx = fullCanvas.getContext("2d")!;
  fullCtx.drawImage(imageBitmap, 0, 0);

  // Watermark text style
  const fontSize = Math.max(24, Math.floor(Math.min(width, height) * 0.05));
  fullCtx.font = `bold ${fontSize}px Arial, sans-serif`;
  fullCtx.fillStyle = "rgba(255, 255, 255, 0.55)";
  fullCtx.strokeStyle = "rgba(0, 0, 0, 0.30)";
  fullCtx.lineWidth = 2;
  fullCtx.textAlign = "center";
  fullCtx.textBaseline = "middle";

  // Draw watermark in the lower-right area
  const text = "photographes.ci";
  const x = width * 0.75;
  const y = height * 0.92;
  fullCtx.strokeText(text, x, y);
  fullCtx.fillText(text, x, y);

  const fullBlob = await fullCanvas.convertToBlob({ type: "image/jpeg", quality: 0.90 });
  const watermarked = new Uint8Array(await fullBlob.arrayBuffer());

  // ── Thumbnail (400px wide) ─────────────────────────────────────────────────
  const thumbWidth = 400;
  const thumbHeight = Math.round((height / width) * thumbWidth);
  const thumbCanvas = new OffscreenCanvas(thumbWidth, thumbHeight);
  const thumbCtx = thumbCanvas.getContext("2d")!;
  thumbCtx.drawImage(imageBitmap, 0, 0, thumbWidth, thumbHeight);

  // Also apply a smaller watermark on the thumbnail
  const thumbFontSize = Math.max(12, Math.floor(thumbWidth * 0.04));
  thumbCtx.font = `bold ${thumbFontSize}px Arial, sans-serif`;
  thumbCtx.fillStyle = "rgba(255, 255, 255, 0.55)";
  thumbCtx.strokeStyle = "rgba(0, 0, 0, 0.30)";
  thumbCtx.lineWidth = 1;
  thumbCtx.textAlign = "center";
  thumbCtx.textBaseline = "middle";
  thumbCtx.strokeText(text, thumbWidth * 0.75, thumbHeight * 0.92);
  thumbCtx.fillText(text, thumbWidth * 0.75, thumbHeight * 0.92);

  const thumbBlob = await thumbCanvas.convertToBlob({ type: "image/jpeg", quality: 0.80 });
  const thumbnail = new Uint8Array(await thumbBlob.arrayBuffer());

  return { watermarked, thumbnail };
}

// ─── Cloudflare R2 Upload (S3-compatible) ────────────────────────────────────

interface R2Config {
  accountId: string;
  accessKeyId: string;
  secretKey: string;
  bucketName: string;
  publicUrl: string;
}

async function uploadToR2(
  config: R2Config,
  path: string,
  data: Uint8Array,
  contentType: string,
): Promise<string> {
  const endpoint =
    `https://${config.accountId}.r2.cloudflarestorage.com/${config.bucketName}/${path}`;

  // Build a minimal AWS Signature V4 for Cloudflare R2
  const now = new Date();
  const dateStr = now.toISOString().replace(/[:-]|\.\d{3}/g, "").slice(0, 8);
  const timeStr = now.toISOString().replace(/[:-]|\.\d{3}/g, "").slice(0, 15) + "Z";
  const region = "auto";
  const service = "s3";

  const host = `${config.accountId}.r2.cloudflarestorage.com`;
  const canonicalUri = `/${config.bucketName}/${path}`;

  const payloadHash = await sha256Hex(data);

  const canonicalHeaders =
    `content-type:${contentType}\nhost:${host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${timeStr}\n`;
  const signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date";

  const canonicalRequest = [
    "PUT",
    canonicalUri,
    "",
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join("\n");

  const credentialScope = `${dateStr}/${region}/${service}/aws4_request`;
  const stringToSign = [
    "AWS4-HMAC-SHA256",
    timeStr,
    credentialScope,
    await sha256Hex(new TextEncoder().encode(canonicalRequest)),
  ].join("\n");

  const signingKey = await deriveSigningKey(config.secretKey, dateStr, region, service);
  const signature = await hmacHex(signingKey, stringToSign);

  const authHeader =
    `AWS4-HMAC-SHA256 Credential=${config.accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  const res = await fetch(endpoint, {
    method: "PUT",
    headers: {
      "Content-Type": contentType,
      "Host": host,
      "x-amz-content-sha256": payloadHash,
      "x-amz-date": timeStr,
      "Authorization": authHeader,
    },
    body: data,
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`R2 upload failed (${res.status}): ${errText}`);
  }

  return `${config.publicUrl.replace(/\/$/, "")}/${path}`;
}

// ─── AWS Signature V4 helpers ─────────────────────────────────────────────────

async function sha256Hex(data: Uint8Array | string): Promise<string> {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  const hashBuffer = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function hmacSha256(key: ArrayBuffer | Uint8Array, data: string): Promise<ArrayBuffer> {
  const k = key instanceof ArrayBuffer ? key : key.buffer;
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    k,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode(data));
}

async function hmacHex(key: ArrayBuffer | Uint8Array, data: string): Promise<string> {
  const buf = await hmacSha256(key, data);
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function deriveSigningKey(
  secret: string,
  date: string,
  region: string,
  service: string,
): Promise<ArrayBuffer> {
  const kDate = await hmacSha256(new TextEncoder().encode(`AWS4${secret}`), date);
  const kRegion = await hmacSha256(kDate, region);
  const kService = await hmacSha256(kRegion, service);
  return hmacSha256(kService, "aws4_request");
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("Méthode non autorisée. Utilisez POST.", 405);
  }

  const body = await parseJsonBody<WatermarkRequest>(req);
  if (!body) {
    return errorResponse("Corps de la requête JSON invalide.", 400);
  }

  if (!body.image_url && !body.storage_path) {
    return errorResponse(
      "Le champ 'image_url' ou 'storage_path' est requis.",
      400,
    );
  }

  const supabase = createAdminClient();

  // Charger la configuration R2
  const [accountId, accessKeyId, secretKey, bucketName, publicUrl] = await Promise.all([
    getAppSetting(supabase, "r2_account_id", "R2_ACCOUNT_ID"),
    getAppSetting(supabase, "r2_access_key_id", "R2_ACCESS_KEY_ID"),
    getAppSetting(supabase, "r2_secret_key", "R2_SECRET_KEY"),
    getAppSetting(supabase, "r2_bucket_name", "R2_BUCKET_NAME"),
    getAppSetting(supabase, "r2_public_url", "R2_PUBLIC_URL"),
  ]);

  if (!accountId || !accessKeyId || !secretKey || !bucketName || !publicUrl) {
    return errorResponse(
      "Configuration Cloudflare R2 incomplète.",
      503,
      "MISSING_CONFIG",
    );
  }

  const r2Config: R2Config = { accountId, accessKeyId, secretKey, bucketName, publicUrl };

  // Récupérer l'image source
  let imageBytes: Uint8Array;
  let contentType = "image/jpeg";
  let baseName: string;

  if (body.storage_path) {
    const { data, error } = await supabase.storage
      .from("photographes_portfolio_photos")
      .download(body.storage_path);

    if (error || !data) {
      return errorResponse(
        `Impossible de télécharger l'image depuis le storage: ${error?.message}`,
        404,
        "STORAGE_ERROR",
      );
    }
    imageBytes = new Uint8Array(await data.arrayBuffer());
    contentType = data.type || "image/jpeg";
    baseName = body.storage_path.split("/").pop()?.replace(/\.[^.]+$/, "") ?? crypto.randomUUID();
  } else {
    let fetchRes: Response;
    try {
      fetchRes = await fetch(body.image_url!);
    } catch (err) {
      return errorResponse(
        `Impossible de télécharger l'image: ${(err as Error).message}`,
        502,
        "FETCH_ERROR",
      );
    }

    if (!fetchRes.ok) {
      return errorResponse(
        `Erreur lors du téléchargement de l'image (${fetchRes.status}).`,
        502,
        "FETCH_ERROR",
      );
    }

    imageBytes = new Uint8Array(await fetchRes.arrayBuffer());
    contentType = fetchRes.headers.get("content-type") ?? "image/jpeg";
    const urlPath = new URL(body.image_url!).pathname;
    baseName = urlPath.split("/").pop()?.replace(/\.[^.]+$/, "") ?? crypto.randomUUID();
  }

  // Appliquer le watermark et générer la miniature
  let watermarked: Uint8Array;
  let thumbnail: Uint8Array;
  try {
    ({ watermarked, thumbnail } = await applyWatermarkAndThumbnail(imageBytes, contentType));
  } catch (err) {
    return errorResponse(
      `Erreur lors du traitement de l'image: ${(err as Error).message}`,
      500,
      "PROCESSING_ERROR",
    );
  }

  // Uploader vers R2
  const uid = crypto.randomUUID();
  const watermarkedPath = `watermarked/${uid}/${baseName}_watermarked.jpg`;
  const thumbnailPath = `thumbnails/${uid}/${baseName}_thumbnail.jpg`;

  try {
    const [watermarkedUrl, thumbnailUrl] = await Promise.all([
      uploadToR2(r2Config, watermarkedPath, watermarked, "image/jpeg"),
      uploadToR2(r2Config, thumbnailPath, thumbnail, "image/jpeg"),
    ]);

    const response: WatermarkResponse = {
      success: true,
      watermarked_url: watermarkedUrl,
      thumbnail_url: thumbnailUrl,
      message: "Image traitée et uploadée avec succès.",
    };

    return jsonResponse(response, 200);
  } catch (err) {
    return errorResponse(
      `Erreur lors de l'upload vers R2: ${(err as Error).message}`,
      502,
      "UPLOAD_ERROR",
    );
  }
});
