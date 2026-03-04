/**
 * auto-refund — Remboursement automatique des contacts expirés et non traités
 *
 * POST /functions/v1/auto-refund  (peut aussi être déclenché par un cron Supabase)
 *
 * Cherche tous les contacts dont :
 *   - le paiement est en statut "success"
 *   - le contact est "expired" (date d'expiration dépassée) OU "unprocessed"
 *   - aucun remboursement n'a encore été émis
 *
 * Dépendances (app_settings) :
 *   - refund_provider           : Provider de remboursement par défaut ("mtn"|"orange"|"wave"|"moov")
 *   - payment_<provider>_api_key: Clé API du provider
 *   - payment_<provider>_api_url: URL API du provider
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient, getAppSetting } from "../_shared/supabase.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
} from "../_shared/utils.ts";
import type { AutoRefundResponse, RefundResult } from "../_shared/types.ts";

// ─── Refund via provider ──────────────────────────────────────────────────────

async function issueRefund(
  apiUrl: string,
  apiKey: string,
  provider: string,
  phone: string,
  amount: number,
  reference: string,
): Promise<{ providerReference: string }> {
  let url: string;
  let body: Record<string, unknown>;

  switch (provider) {
    case "orange":
      url = `${apiUrl}/refund`;
      body = { amount, currency: "XOF", reference, msisdn: phone.replace("+", "") };
      break;
    case "wave":
      url = `${apiUrl}/v1/refunds`;
      body = { amount: String(amount), currency: "XOF", client_reference: reference };
      break;
    case "moov":
      url = `${apiUrl}/api/v1/refund`;
      body = { amount, currency: "XOF", msisdn: phone.replace("+", ""), reference };
      break;
    default: // mtn
      // MTN refund uses a dedicated endpoint per transaction reference; no body needed
      url = `${apiUrl}/v1_0/collection/v1_0/payment/${reference}/refund`;
      body = {};
      break;
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "X-Reference-Id": reference,
    },
    // MTN refund endpoint does not accept a request body
    body: Object.keys(body).length > 0 ? JSON.stringify(body) : undefined,
  });

  if (!res.ok && res.status !== 202) {
    const errText = await res.text();
    throw new Error(`${provider} refund API error (${res.status}): ${errText}`);
  }

  const data = await res.json().catch(() => ({})) as Record<string, unknown>;
  return {
    providerReference: (data.transaction_id ?? data.id ?? data.payment_token ?? reference) as string,
  };
}

// ─── Handler ─────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST" && req.method !== "GET") {
    return errorResponse("Méthode non autorisée.", 405);
  }

  const supabase = createAdminClient();

  // Récupérer le provider de remboursement par défaut
  const refundProvider = await getAppSetting(supabase, "refund_provider", "REFUND_PROVIDER") ?? "mtn";

  const [apiKey, apiUrl] = await Promise.all([
    getAppSetting(
      supabase,
      `payment_${refundProvider}_api_key`,
      `PAYMENT_${refundProvider.toUpperCase()}_API_KEY`,
    ),
    getAppSetting(
      supabase,
      `payment_${refundProvider}_api_url`,
      `PAYMENT_${refundProvider.toUpperCase()}_API_URL`,
    ),
  ]);

  if (!apiKey || !apiUrl) {
    return errorResponse(
      `Configuration du provider de remboursement '${refundProvider}' non disponible.`,
      503,
      "MISSING_CONFIG",
    );
  }

  // Trouver les transactions éligibles au remboursement :
  // - statut "success"
  // - contact associé avec statut "expired" ou créé il y a plus de 48h sans traitement
  // - pas déjà remboursé (pas de refund_transaction_id)
  const { data: transactions, error: fetchError } = await supabase
    .from("payment_transactions")
    .select(
      "id, reference, amount, phone, provider, contact_id, provider_reference",
    )
    .eq("status", "success")
    .is("refund_transaction_id", null)
    .not("contact_id", "is", null);

  if (fetchError) {
    return errorResponse(
      "Erreur lors de la récupération des transactions.",
      500,
      "DB_ERROR",
      fetchError.message,
    );
  }

  if (!transactions || transactions.length === 0) {
    const response: AutoRefundResponse = {
      success: true,
      processed: 0,
      refunded: 0,
      failed: 0,
      results: [],
    };
    return jsonResponse(response, 200);
  }

  // Récupérer les contacts associés et filtrer ceux éligibles
  const contactIds = transactions.map((t) => t.contact_id as string);
  const { data: contacts, error: contactsError } = await supabase
    .from("contacts")
    .select("id, status, expires_at, processed_at")
    .in("id", contactIds);

  if (contactsError) {
    return errorResponse(
      "Erreur lors de la récupération des contacts.",
      500,
      "DB_ERROR",
      contactsError.message,
    );
  }

  const eligibleContactIds = new Set(
    (contacts ?? [])
      .filter((c) => {
        if (["refunded", "cancelled"].includes(c.status)) return false;
        const isExpired = c.expires_at && new Date(c.expires_at) < new Date();
        const isUnprocessed = !c.processed_at;
        const isEligibleStatus = ["expired", "unprocessed", "pending"].includes(c.status);
        return isEligibleStatus || (isExpired && isUnprocessed);
      })
      .map((c) => c.id),
  );

  const eligibleTransactions = transactions.filter(
    (t) => eligibleContactIds.has(t.contact_id as string),
  );

  if (eligibleTransactions.length === 0) {
    const response: AutoRefundResponse = {
      success: true,
      processed: 0,
      refunded: 0,
      failed: 0,
      results: [],
    };
    return jsonResponse(response, 200);
  }

  // Traiter les remboursements
  const results: RefundResult[] = [];
  let refunded = 0;
  let failed = 0;

  for (const tx of eligibleTransactions) {
    const refundRef = `REFUND-${tx.reference}-${Date.now()}`;
    try {
      const { providerReference } = await issueRefund(
        apiUrl,
        apiKey,
        refundProvider,
        tx.phone as string,
        tx.amount as number,
        refundRef,
      );

      // Enregistrer le remboursement
      const { data: refundTx } = await supabase
        .from("payment_transactions")
        .insert({
          reference: refundRef,
          amount: tx.amount,
          phone: tx.phone,
          provider: refundProvider,
          status: "success",
          contact_id: tx.contact_id,
          provider_reference: providerReference,
          is_refund: true,
          original_transaction_id: tx.id,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (refundTx) {
        // Mettre à jour la transaction originale
        await supabase
          .from("payment_transactions")
          .update({
            status: "refunded",
            refund_transaction_id: refundTx.id,
            updated_at: new Date().toISOString(),
          })
          .eq("id", tx.id);

        // Mettre à jour le statut du contact
        await supabase
          .from("contacts")
          .update({
            status: "refunded",
            updated_at: new Date().toISOString(),
          })
          .eq("id", tx.contact_id);
      }

      results.push({
        contact_id: tx.contact_id as string,
        transaction_id: tx.id as string,
        amount: tx.amount as number,
        status: "refunded",
        message: `Remboursement effectué. Référence provider: ${providerReference}`,
      });
      refunded++;
    } catch (err) {
      results.push({
        contact_id: tx.contact_id as string,
        transaction_id: tx.id as string,
        amount: tx.amount as number,
        status: "failed",
        message: `Échec du remboursement: ${(err as Error).message}`,
      });
      failed++;
    }
  }

  const response: AutoRefundResponse = {
    success: true,
    processed: eligibleTransactions.length,
    refunded,
    failed,
    results,
  };

  return jsonResponse(response, 200);
});
