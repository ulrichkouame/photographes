/**
 * verify-otp — Vérification du code OTP et retour d'un JWT de session
 *
 * POST /functions/v1/verify-otp
 * Body: { "phone": "+2250700000000", "code": "123456" }
 *
 * Retourne un access_token JWT signé par Supabase Auth ainsi que les
 * informations de l'utilisateur. Crée le compte si c'est la première
 * connexion du numéro de téléphone.
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import {
  errorResponse,
  handleCors,
  isExpired,
  jsonResponse,
  parseJsonBody,
  sanitisePhone,
  validateRequiredFields,
} from "../_shared/utils.ts";
import type { VerifyOtpRequest, VerifyOtpResponse } from "../_shared/types.ts";

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("Méthode non autorisée. Utilisez POST.", 405);
  }

  const body = await parseJsonBody<VerifyOtpRequest>(req);
  if (!body) {
    return errorResponse("Corps de la requête JSON invalide.", 400);
  }

  const validationError = validateRequiredFields(
    body as unknown as Record<string, unknown>,
    ["phone", "code"],
  );
  if (validationError) return errorResponse(validationError, 400);

  const phone = sanitisePhone(body.phone);
  if (!phone) {
    return errorResponse(
      "Numéro de téléphone invalide. Utilisez le format +2250XXXXXXXXX.",
      400,
    );
  }

  const code = String(body.code).trim();
  if (!/^\d{6}$/.test(code)) {
    return errorResponse("Le code OTP doit contenir exactement 6 chiffres.", 400);
  }

  const supabase = createAdminClient();

  // Récupérer l'OTP enregistré pour ce numéro
  const { data: otpRecord, error: fetchError } = await supabase
    .from("photographes_otp_verifications")
    .select("*")
    .eq("phone", phone)
    .eq("verified", false)
    .single();

  if (fetchError || !otpRecord) {
    return errorResponse(
      "Aucun code OTP en attente pour ce numéro. Veuillez d'abord demander un code.",
      404,
      "OTP_NOT_FOUND",
    );
  }

  // Vérifier l'expiration
  if (isExpired(otpRecord.expires_at)) {
    await supabase.from("photographes_otp_verifications").delete().eq("phone", phone);
    return errorResponse(
      "Le code OTP a expiré. Veuillez en demander un nouveau.",
      410,
      "OTP_EXPIRED",
    );
  }

  // Vérifier le code
  if (otpRecord.code !== code) {
    return errorResponse(
      "Code OTP incorrect.",
      401,
      "OTP_INVALID",
    );
  }

  // Marquer l'OTP comme vérifié
  await supabase
    .from("photographes_otp_verifications")
    .update({ verified: true, updated_at: new Date().toISOString() })
    .eq("phone", phone);

  // Chercher ou créer l'utilisateur Supabase Auth via son numéro de téléphone
  const { data: existingUsers } = await supabase.auth.admin.listUsers();
  const existingUser = existingUsers?.users?.find(
    (u) => u.phone === phone || u.user_metadata?.phone === phone,
  );

  let userId: string;

  if (existingUser) {
    userId = existingUser.id;
  } else {
    // Créer un nouvel utilisateur avec ce numéro de téléphone
    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      phone,
      phone_confirm: true,
      user_metadata: { phone, verified_at: new Date().toISOString() },
    });

    if (createError || !newUser?.user) {
      return errorResponse(
        "Erreur lors de la création du compte utilisateur.",
        500,
        "USER_CREATE_ERROR",
        createError?.message,
      );
    }
    userId = newUser.user.id;
  }

  // Générer une session JWT pour cet utilisateur
  const { data: session, error: sessionError } = await supabase.auth.admin.createSession({
    userId,
  });

  if (sessionError || !session) {
    return errorResponse(
      "Erreur lors de la création de la session.",
      500,
      "SESSION_ERROR",
      sessionError?.message,
    );
  }

  const response: VerifyOtpResponse = {
    success: true,
    access_token: session.session.access_token,
    refresh_token: session.session.refresh_token,
    user: {
      id: session.user.id,
      phone: session.user.phone,
      created_at: session.user.created_at,
      user_metadata: session.user.user_metadata,
    },
    message: "Authentification réussie.",
  };

  return jsonResponse(response, 200);
});
