// ─────────────────────────────────────────────────────────────────────────────
// Utilitaires de types TypeScript — Photographes.ci
// ─────────────────────────────────────────────────────────────────────────────

/** Rend toutes les propriétés d'un type optionnelles en profondeur. */
export type DeepPartial<T> = T extends object
  ? { [P in keyof T]?: DeepPartial<T[P]> }
  : T;

/** Extrait les clés dont la valeur est du type `V`. */
export type KeysOfType<T, V> = {
  [K in keyof T]: T[K] extends V ? K : never;
}[keyof T];

/** Rend certaines propriétés requises. */
export type RequiredFields<T, K extends keyof T> = T & Required<Pick<T, K>>;

/** Rend certaines propriétés optionnelles. */
export type OptionalFields<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

/** Exclut les champs auto-gérés par la DB pour les insertions. */
export type InsertPayload<T extends { id?: string; created_at?: string; updated_at?: string }> =
  Omit<T, 'id' | 'created_at' | 'updated_at'>;

/** Extrait les champs modifiables (exclut id et created_at). */
export type UpdatePayload<T extends { id?: string; created_at?: string }> =
  Partial<Omit<T, 'id' | 'created_at'>>;

/** Résultat asynchrone Supabase avec gestion d'erreur. */
export type SupabaseResult<T> =
  | { data: T; error: null }
  | { data: null; error: { message: string; code?: string } };

/**
 * Formate un montant en XOF.
 * @example formatCurrency(1500) // '1 500 FCFA'
 */
export function formatCurrency(
  amount: number,
  currency = 'XOF',
  locale = 'fr-CI',
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

/**
 * Formate une date ISO en date française lisible.
 * @example formatDate('2026-03-04') // '4 mars 2026'
 */
export function formatDate(
  isoDate: string,
  options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'long', year: 'numeric' },
  locale = 'fr-FR',
): string {
  return new Date(isoDate).toLocaleDateString(locale, options);
}

/**
 * Génère un slug à partir d'une chaîne de caractères.
 * @example toSlug('Portrait - Abidjan') // 'portrait-abidjan'
 */
export function toSlug(str: string): string {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-');
}

/**
 * Retourne les initiales d'un nom.
 * @example getInitials('Kouamé Ulrich') // 'KU'
 */
export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

/**
 * Masque partiellement un numéro de téléphone.
 * @example maskPhone('+22507123456') // '+225 07 *** 456'
 */
export function maskPhone(phone: string): string {
  if (phone.length < 6) return phone;
  const start = phone.slice(0, phone.length - 6);
  const end = phone.slice(-3);
  return `${start}***${end}`;
}

/**
 * Vérifie si une URL est valide.
 */
export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}
