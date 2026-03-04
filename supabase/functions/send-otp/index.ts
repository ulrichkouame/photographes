/**
 * send-otp — Envoi d'un code OTP par WhatsApp via WasenderAPI
 *
 * POST /functions/v1/send-otp
 * Body: { "phone": "+2250700000000" }
 *
 * Dépendances (app_settings) :
 *   - wasender_api_key  : Clé API WasenderAPI
 *   - wasender_api_url  : URL de l'API WasenderAPI (facultatif, défaut fourni)
 *   - otp_expiry_seconds: Durée de validité de l'OTP en secondes (défaut: 600)
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient, getAppSetting } from "../_shared/supabase.ts";
import {
  errorResponse,
  expiresAt,
  generateOtp,
  handleCors,
  jsonResponse,
  parseJsonBody,
  sanitisePhone,
  validateRequiredFields,
} from "../_shared/utils.ts";
import type { SendOtpRequest, SendOtpResponse } from "../_shared/types.ts";

const WASENDER_DEFAULT_URL = "https://api.wasenderapi.com/api/send-message";
const DEFAULT_OTP_EXPIRY_SECONDS = 600;

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("Méthode non autorisée. Utilisez POST.", 405);
  }

  const body = await parseJsonBody<SendOtpRequest>(req);
  if (!body) {
    return errorResponse("Corps de la requête JSON invalide.", 400);
  }

  const validationError = validateRequiredFields(
    body as unknown as Record<string, unknown>,
    ["phone"],
  );
  if (validationError) return errorResponse(validationError, 400);

  const phone = sanitisePhone(body.phone);
  if (!phone) {
    return errorResponse(
      "Numéro de téléphone invalide. Utilisez le format +2250XXXXXXXXX.",
      400,
    );
  }

  const supabase = createAdminClient();

  // Récupérer la configuration dynamique
  const [apiKey, apiUrl, expiryStr] = await Promise.all([
    getAppSetting(supabase, "wasender_api_key", "WASENDER_API_KEY"),
    getAppSetting(supabase, "wasender_api_url", "WASENDER_API_URL"),
    getAppSetting(supabase, "otp_expiry_seconds", "OTP_EXPIRY_SECONDS"),
  ]);

  if (!apiKey) {
    return errorResponse(
      "Configuration du service d'envoi de messages non disponible.",
      503,
      "MISSING_CONFIG",
    );
  }

  const expirySeconds = parseInt(expiryStr ?? String(DEFAULT_OTP_EXPIRY_SECONDS), 10);
  const code = generateOtp(6);
  const expiry = expiresAt(expirySeconds);

  // Stocker l'OTP en base (invalider les précédents pour ce numéro)
  const { error: upsertError } = await supabase
    .from("photographes_otp_verifications")
    .upsert(
      {
        phone,
        code,
        expires_at: expiry,
        verified: false,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "phone" },
    );

  if (upsertError) {
    return errorResponse(
      "Erreur lors de la génération du code OTP.",
      500,
      "DB_ERROR",
      upsertError.message,
    );
  }

  // Envoyer le message WhatsApp via WasenderAPI
  const message =
    `*photographes.ci*\n\nVotre code de vérification est : *${code}*\n\nCe code est valable pendant ${Math.floor(expirySeconds / 60)} minutes.\n\nNe partagez ce code avec personne.`;

  const wasenderUrl = apiUrl ?? WASENDER_DEFAULT_URL;

  let sendError: string | null = null;
  try {
    const wasenderRes = await fetch(wasenderUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        phoneNumber: phone,
        message,
      }),
    });

    if (!wasenderRes.ok) {
      const errText = await wasenderRes.text();
      sendError = `Erreur WasenderAPI (${wasenderRes.status}): ${errText}`;
    }
  } catch (err) {
    sendError = `Erreur réseau lors de l'envoi du message: ${(err as Error).message}`;
  }

  if (sendError) {
    // Supprimer l'OTP enregistré si l'envoi a échoué
    await supabase.from("photographes_otp_verifications").delete().eq("phone", phone);
    return errorResponse(sendError, 502, "SEND_ERROR");
  }

  const response: SendOtpResponse = {
    success: true,
    message:
      `Un code de vérification a été envoyé au ${phone} via WhatsApp.`,
    expires_in_seconds: expirySeconds,
  };

  return jsonResponse(response, 200);
});
