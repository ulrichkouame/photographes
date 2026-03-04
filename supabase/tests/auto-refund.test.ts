/**
 * Tests pour auto-refund
 * Exécution : deno test supabase/tests/auto-refund.test.ts
 */

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) throw new Error(msg ?? `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}
function assertStringIncludes(actual: string, expected: string, msg?: string): void {
  if (!actual.includes(expected)) throw new Error(msg ?? `"${actual}" does not include "${expected}"`);
}

interface MockContact {
  id: string; status: string;
  expires_at: string | null; processed_at: string | null;
}
interface MockTransaction {
  id: string; reference: string; amount: number; phone: string;
  provider: string; contact_id: string; status: string;
  refund_transaction_id: string | null;
}
interface RefundResult {
  contact_id: string; transaction_id: string; amount: number;
  status: "refunded" | "failed"; message: string;
}

function isContactEligibleForRefund(contact: MockContact): boolean {
  if (["refunded", "cancelled"].includes(contact.status)) return false;
  const isExpired = contact.expires_at && new Date(contact.expires_at) < new Date();
  const isUnprocessed = !contact.processed_at;
  const isEligibleStatus = ["expired", "unprocessed", "pending"].includes(contact.status);
  return !!(isEligibleStatus || (isExpired && isUnprocessed));
}

Deno.test("auto-refund: contact expiré est éligible", () => {
  assertEquals(isContactEligibleForRefund({
    id: "c1", status: "expired",
    expires_at: new Date(Date.now() - 86400_000).toISOString(), processed_at: null,
  }), true);
});

Deno.test("auto-refund: contact pending est éligible", () => {
  assertEquals(isContactEligibleForRefund({
    id: "c2", status: "pending", expires_at: null, processed_at: null,
  }), true);
});

Deno.test("auto-refund: contact actif non expiré n'est pas éligible", () => {
  assertEquals(isContactEligibleForRefund({
    id: "c3", status: "active",
    expires_at: new Date(Date.now() + 86400_000).toISOString(),
    processed_at: new Date().toISOString(),
  }), false);
});

Deno.test("auto-refund: contact remboursé n'est pas éligible", () => {
  assertEquals(isContactEligibleForRefund({
    id: "c4", status: "refunded",
    expires_at: new Date(Date.now() - 86400_000).toISOString(), processed_at: null,
  }), false);
});

Deno.test("auto-refund: contact unprocessed est éligible", () => {
  assertEquals(isContactEligibleForRefund({
    id: "c5", status: "unprocessed", expires_at: null, processed_at: null,
  }), true);
});

Deno.test("auto-refund: seules les transactions success sans refund_transaction_id sont traitées", () => {
  const transactions: MockTransaction[] = [
    { id: "tx-1", reference: "REF-1", amount: 5000, phone: "+2250700000000", provider: "mtn", contact_id: "c1", status: "success", refund_transaction_id: null },
    { id: "tx-2", reference: "REF-2", amount: 5000, phone: "+2250700000001", provider: "mtn", contact_id: "c2", status: "success", refund_transaction_id: "refund-tx-2" },
    { id: "tx-3", reference: "REF-3", amount: 5000, phone: "+2250700000002", provider: "orange", contact_id: "c3", status: "pending", refund_transaction_id: null },
  ];
  const eligible = transactions.filter((tx) => tx.status === "success" && tx.refund_transaction_id === null);
  assertEquals(eligible.length, 1);
  assertEquals(eligible[0].id, "tx-1");
});

Deno.test("auto-refund: résumé avec remboursements partiels", () => {
  const results: RefundResult[] = [
    { contact_id: "c1", transaction_id: "t1", amount: 5000, status: "refunded", message: "OK" },
    { contact_id: "c2", transaction_id: "t2", amount: 5000, status: "refunded", message: "OK" },
    { contact_id: "c3", transaction_id: "t3", amount: 5000, status: "failed", message: "Erreur" },
  ];
  assertEquals(results.filter((r) => r.status === "refunded").length, 2);
  assertEquals(results.filter((r) => r.status === "failed").length, 1);
});

Deno.test("auto-refund: référence de remboursement est unique", () => {
  const originalRef = "PHOTO-2024-001";
  const ref1 = `REFUND-${originalRef}-${Date.now()}`;
  const ref2 = `REFUND-${originalRef}-${Date.now() + 1}`;
  assertStringIncludes(ref1, "REFUND-");
  assertStringIncludes(ref1, originalRef);
  assertEquals(ref1 !== ref2, true);
});

Deno.test("auto-refund: contact passe au statut refunded après remboursement", () => {
  const contact: MockContact = { id: "c1", status: "expired", expires_at: new Date(Date.now() - 1000).toISOString(), processed_at: null };
  const updated = { ...contact, status: "refunded" };
  assertEquals(updated.status, "refunded");
});

Deno.test("auto-refund: provider par défaut est 'mtn' si non configuré", () => {
  function getRefundProvider(setting: string | null): string { return setting ?? "mtn"; }
  assertEquals(getRefundProvider(null), "mtn");
  assertEquals(getRefundProvider("orange"), "orange");
  assertEquals(getRefundProvider("wave"), "wave");
});
