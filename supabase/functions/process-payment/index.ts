/**
 * process-payment — Traitement d'un paiement Mobile Money
 *
 * POST /functions/v1/process-payment
 * Headers: Authorization: Bearer <jwt>
 * Body: {
 *   "amount": 5000,
 *   "phone": "+2250700000000",
 *   "provider": "mtn" | "orange" | "wave" | "moov",
 *   "reference": "PHOTO-2024-001",
 *   "description": "Accès aux coordonnées photographe",
 *   "contact_id": "uuid"
 * }
 *
 * Dépendances (app_settings) :
 *   - payment_mtn_api_key       : Clé API MTN Mobile Money
 *   - payment_mtn_api_url       : URL API MTN
 *   - payment_orange_api_key    : Clé API Orange Money
 *   - payment_orange_api_url    : URL API Orange Money
 *   - payment_wave_api_key      : Clé API Wave
 *   - payment_wave_api_url      : URL API Wave
 *   - payment_moov_api_key      : Clé API Moov Money
 *   - payment_moov_api_url      : URL API Moov Money
 *   - payment_callback_url      : URL de callback pour les notifications
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient, getAppSetting } from "../_shared/supabase.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  parseJsonBody,
  sanitisePhone,
  validateRequiredFields,
} from "../_shared/utils.ts";
import type {
  PaymentProvider,
  PaymentRequest,
  PaymentResponse,
  PaymentStatus,
} from "../_shared/types.ts";

const VALID_PROVIDERS: PaymentProvider[] = ["mtn", "orange", "wave", "moov"];

// ─── Provider Adapters ────────────────────────────────────────────────────────

interface ProviderConfig {
  apiKey: string;
  apiUrl: string;
  callbackUrl?: string;
}

interface ProviderResult {
  status: PaymentStatus;
  providerReference: string;
  message: string;
}

async function initiateMtnPayment(
  config: ProviderConfig,
  req: PaymentRequest,
): Promise<ProviderResult> {
  const res = await fetch(`${config.apiUrl}/v1_0/collection/requesttopay`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
      "X-Reference-Id": req.reference,
      "X-Target-Environment": "production",
      ...(config.callbackUrl ? { "X-Callback-Url": config.callbackUrl } : {}),
    },
    body: JSON.stringify({
      amount: String(req.amount),
      currency: "XOF",
      externalId: req.reference,
      payer: { partyIdType: "MSISDN", partyId: req.phone.replace("+", "") },
      payerMessage: req.description ?? "Paiement photographes.ci",
      payeeNote: req.reference,
    }),
  });

  if (res.status === 202) {
    return { status: "pending", providerReference: req.reference, message: "Paiement initié." };
  }
  const errText = await res.text();
  throw new Error(`MTN API error (${res.status}): ${errText}`);
}

async function initiateOrangePayment(
  config: ProviderConfig,
  req: PaymentRequest,
): Promise<ProviderResult> {
  const res = await fetch(`${config.apiUrl}/orange-money-webpay/CI/v1`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      merchant_key: config.apiKey,
      currency: "OUV",
      order_id: req.reference,
      amount: req.amount,
      return_url: config.callbackUrl ?? "",
      cancel_url: config.callbackUrl ?? "",
      notif_url: config.callbackUrl ?? "",
      lang: "fr",
      reference: req.reference,
    }),
  });

  if (res.ok) {
    const data = await res.json() as { payment_token?: string; status?: string };
    return {
      status: "pending",
      providerReference: data.payment_token ?? req.reference,
      message: "Paiement Orange Money initié.",
    };
  }
  const errText = await res.text();
  throw new Error(`Orange API error (${res.status}): ${errText}`);
}

async function initiateWavePayment(
  config: ProviderConfig,
  req: PaymentRequest,
): Promise<ProviderResult> {
  const res = await fetch(`${config.apiUrl}/v1/checkout/sessions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: String(req.amount),
      currency: "XOF",
      client_reference: req.reference,
      success_url: config.callbackUrl ?? "",
      error_url: config.callbackUrl ?? "",
    }),
  });

  if (res.ok) {
    const data = await res.json() as { id?: string; status?: string };
    return {
      status: "pending",
      providerReference: data.id ?? req.reference,
      message: "Paiement Wave initié.",
    };
  }
  const errText = await res.text();
  throw new Error(`Wave API error (${res.status}): ${errText}`);
}

async function initiateMoovPayment(
  config: ProviderConfig,
  req: PaymentRequest,
): Promise<ProviderResult> {
  const res = await fetch(`${config.apiUrl}/api/v1/cashout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${config.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: req.amount,
      currency: "XOF",
      msisdn: req.phone.replace("+", ""),
      reference: req.reference,
      description: req.description ?? "Paiement photographes.ci",
      callback_url: config.callbackUrl ?? "",
    }),
  });

  if (res.ok) {
    const data = await res.json() as { transaction_id?: string };
    return {
      status: "pending",
      providerReference: data.transaction_id ?? req.reference,
      message: "Paiement Moov initié.",
    };
  }
  const errText = await res.text();
  throw new Error(`Moov API error (${res.status}): ${errText}`);
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("Méthode non autorisée. Utilisez POST.", 405);
  }

  const body = await parseJsonBody<PaymentRequest>(req);
  if (!body) {
    return errorResponse("Corps de la requête JSON invalide.", 400);
  }

  const validationError = validateRequiredFields(
    body as unknown as Record<string, unknown>,
    ["amount", "phone", "provider", "reference"],
  );
  if (validationError) return errorResponse(validationError, 400);

  if (!VALID_PROVIDERS.includes(body.provider)) {
    return errorResponse(
      `Provider invalide. Valeurs acceptées: ${VALID_PROVIDERS.join(", ")}.`,
      400,
    );
  }

  if (typeof body.amount !== "number" || body.amount <= 0) {
    return errorResponse("Le montant doit être un nombre positif.", 400);
  }

  const phone = sanitisePhone(body.phone);
  if (!phone) {
    return errorResponse(
      "Numéro de téléphone invalide. Utilisez le format +2250XXXXXXXXX.",
      400,
    );
  }

  const supabase = createAdminClient();

  // Vérifier l'unicité de la référence
  const { data: existingTx } = await supabase
    .from("photographes_payments")
    .select("id, status")
    .eq("reference", body.reference)
    .maybeSingle();

  if (existingTx) {
    if (existingTx.status === "success") {
      return errorResponse(
        "Cette référence de paiement a déjà été traitée avec succès.",
        409,
        "DUPLICATE_REFERENCE",
      );
    }
    if (existingTx.status === "pending") {
      return errorResponse(
        "Un paiement avec cette référence est déjà en attente.",
        409,
        "PENDING_PAYMENT",
      );
    }
  }

  // Charger la configuration du provider
  const providerPrefix = `payment_${body.provider}`;
  const [apiKey, apiUrl, callbackUrl] = await Promise.all([
    getAppSetting(supabase, `${providerPrefix}_api_key`, `PAYMENT_${body.provider.toUpperCase()}_API_KEY`),
    getAppSetting(supabase, `${providerPrefix}_api_url`, `PAYMENT_${body.provider.toUpperCase()}_API_URL`),
    getAppSetting(supabase, "payment_callback_url", "PAYMENT_CALLBACK_URL"),
  ]);

  if (!apiKey || !apiUrl) {
    return errorResponse(
      `Configuration du provider ${body.provider} non disponible.`,
      503,
      "MISSING_CONFIG",
    );
  }

  const providerConfig: ProviderConfig = { apiKey, apiUrl, callbackUrl: callbackUrl ?? undefined };
  const paymentReq: PaymentRequest = { ...body, phone };

  // Enregistrer la transaction en statut pending
  const { data: transaction, error: txError } = await supabase
    .from("photographes_payments")
    .insert({
      reference: body.reference,
      amount: body.amount,
      phone,
      provider: body.provider,
      status: "pending",
      contact_id: body.contact_id ?? null,
      description: body.description ?? null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .select("id")
    .single();

  if (txError || !transaction) {
    return errorResponse(
      "Erreur lors de l'enregistrement de la transaction.",
      500,
      "DB_ERROR",
      txError?.message,
    );
  }

  // Initier le paiement chez le provider
  let result: ProviderResult | undefined;
  try {
    switch (body.provider) {
      case "mtn":
        result = await initiateMtnPayment(providerConfig, paymentReq);
        break;
      case "orange":
        result = await initiateOrangePayment(providerConfig, paymentReq);
        break;
      case "wave":
        result = await initiateWavePayment(providerConfig, paymentReq);
        break;
      case "moov":
        result = await initiateMoovPayment(providerConfig, paymentReq);
        break;
    }
  } catch (err) {
    // Marquer la transaction comme échouée
    await supabase
      .from("photographes_payments")
      .update({ status: "failed", updated_at: new Date().toISOString() })
      .eq("id", transaction.id);

    return errorResponse(
      `Erreur lors de l'initiation du paiement: ${(err as Error).message}`,
      502,
      "PAYMENT_INITIATION_ERROR",
    );
  }

  if (!result) {
    return errorResponse("Provider non supporté.", 400, "UNSUPPORTED_PROVIDER");
  }

  // Mettre à jour la transaction avec la référence du provider
  await supabase
    .from("photographes_payments")
    .update({
      status: result.status,
      provider_reference: result.providerReference,
      updated_at: new Date().toISOString(),
    })
    .eq("id", transaction.id);

  const response: PaymentResponse = {
    success: true,
    transaction_id: transaction.id,
    status: result.status,
    message: result.message,
    provider_reference: result.providerReference,
  };

  return jsonResponse(response, 201);
});
