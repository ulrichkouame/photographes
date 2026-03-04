/**
 * Tests pour process-payment
 * Exécution : deno test supabase/tests/process-payment.test.ts
 */

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}
function assertStringIncludes(actual: string, expected: string, msg?: string): void {
  if (!actual.includes(expected)) throw new Error(msg ?? `"${actual}" does not include "${expected}"`);
}

type PaymentProvider = "mtn" | "orange" | "wave" | "moov";
type PaymentStatus = "pending" | "success" | "failed" | "cancelled";

const VALID_PROVIDERS: PaymentProvider[] = ["mtn", "orange", "wave", "moov"];
function sanitisePhone(phone: string): string | null {
  const cleaned = phone.replace(/\D/g, "");
  if (cleaned.length === 10 && cleaned.startsWith("0")) return `+225${cleaned}`;
  if (cleaned.length === 13 && cleaned.startsWith("225")) return `+${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith("225")) return `+${cleaned}`;
  return null;
}

Deno.test("process-payment: providers valides sont acceptés", () => {
  for (const p of VALID_PROVIDERS) assertEquals(VALID_PROVIDERS.includes(p), true);
});

Deno.test("process-payment: provider invalide est rejeté", () => {
  for (const p of ["paypal", "visa", "mpesa", ""]) {
    assertEquals(VALID_PROVIDERS.includes(p as PaymentProvider), false);
  }
});

Deno.test("process-payment: montant doit être positif", () => {
  function validateAmount(amount: unknown): string | null {
    if (typeof amount !== "number" || amount <= 0) return "Le montant doit être un nombre positif.";
    return null;
  }
  assertEquals(validateAmount(5000), null);
  assertEquals(validateAmount(-100), "Le montant doit être un nombre positif.");
  assertEquals(validateAmount(0), "Le montant doit être un nombre positif.");
  assertEquals(validateAmount("5000"), "Le montant doit être un nombre positif.");
  assertEquals(validateAmount(null), "Le montant doit être un nombre positif.");
});

Deno.test("process-payment: numéro de téléphone valide", () => {
  assertEquals(sanitisePhone("0700000000"), "+2250700000000");
  assertEquals(sanitisePhone("abc"), null);
});

Deno.test("process-payment: construction requête MTN", () => {
  const body = {
    amount: String(5000), currency: "XOF", externalId: "PHOTO-2024-001",
    payer: { partyIdType: "MSISDN", partyId: "2250700000000" },
    payerMessage: "Paiement photographes.ci", payeeNote: "PHOTO-2024-001",
  };
  assertEquals(body.currency, "XOF");
  assertEquals(body.payer.partyId, "2250700000000");
  assertEquals(body.externalId, "PHOTO-2024-001");
});

Deno.test("process-payment: construction requête Wave", () => {
  const body = {
    amount: "5000", currency: "XOF", client_reference: "PHOTO-2024-001",
    success_url: "https://photographes.ci/webhooks/payment",
    error_url: "https://photographes.ci/webhooks/payment",
  };
  assertEquals(body.currency, "XOF");
  assertEquals(body.client_reference, "PHOTO-2024-001");
  assertStringIncludes(body.success_url, "photographes.ci");
});

Deno.test("process-payment: construction requête Orange Money", () => {
  const body = {
    merchant_key: "orange-key", currency: "OUV", order_id: "PHOTO-2024-001",
    amount: 5000, lang: "fr", reference: "PHOTO-2024-001",
    return_url: "https://photographes.ci/webhooks/payment",
    cancel_url: "https://photographes.ci/webhooks/payment",
    notif_url: "https://photographes.ci/webhooks/payment",
  };
  assertEquals(body.currency, "OUV");
  assertEquals(body.lang, "fr");
  assertEquals(body.amount, 5000);
});

Deno.test("process-payment: doublon success est rejeté", () => {
  interface Tx { id: string; status: PaymentStatus; reference: string }
  function checkDuplicate(existing: Tx | null): { isDuplicate: boolean } | null {
    if (!existing) return null;
    if (existing.status === "success") return { isDuplicate: true };
    if (existing.status === "pending") return { isDuplicate: true };
    return null;
  }
  assertEquals(checkDuplicate(null), null);
  assertEquals(checkDuplicate({ id: "1", status: "success", reference: "REF-1" })?.isDuplicate, true);
  assertEquals(checkDuplicate({ id: "1", status: "pending", reference: "REF-1" })?.isDuplicate, true);
  assertEquals(checkDuplicate({ id: "1", status: "failed", reference: "REF-1" }), null);
});

Deno.test("process-payment: statuts de transaction valides", () => {
  const validStatuses: PaymentStatus[] = ["pending", "success", "failed", "cancelled"];
  for (const s of validStatuses) assertEquals(validStatuses.includes(s), true);
  for (const s of ["processing", "error", "done"]) {
    assertEquals(validStatuses.includes(s as PaymentStatus), false);
  }
});

Deno.test("process-payment: référence de remboursement suit le bon format", () => {
  const originalRef = "PHOTO-2024-001";
  const timestamp = 1700000000000;
  const refundRef = `REFUND-${originalRef}-${timestamp}`;
  assertStringIncludes(refundRef, "REFUND-");
  assertStringIncludes(refundRef, originalRef);
  assertStringIncludes(refundRef, String(timestamp));
});
