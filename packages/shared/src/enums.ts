// ─────────────────────────────────────────────────────────────────────────────
// Enums et littéraux de types — Photographes.ci
// ─────────────────────────────────────────────────────────────────────────────

/** Rôle d'un utilisateur sur la plateforme. */
export type UserRole = 'client' | 'photographer' | 'admin';

/** Statut d'une réservation (format base de données). */
export type BookingStatus =
  | 'en_attente'
  | 'accepte'
  | 'refuse'
  | 'termine'
  | 'annule'
  | 'pending'
  | 'confirmed'
  | 'cancelled'
  | 'completed';

/** Statut d'un paiement. */
export type PaymentStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'refunded';

/** Opérateurs de Mobile Money disponibles. */
export type MobileMoneyOperator =
  | 'orange_money'
  | 'mtn_momo'
  | 'wave'
  | 'cinetpay'
  | 'card';

/** Plans d'abonnement photographe. */
export type SubscriptionPlan = 'free' | 'starter' | 'pro' | 'premium';

/** Statut d'un abonnement. */
export type SubscriptionStatus = 'active' | 'expired' | 'cancelled';

/** Types de notification. */
export type NotificationType =
  | 'booking_request'
  | 'booking_accepted'
  | 'booking_refused'
  | 'booking_completed'
  | 'message'
  | 'payment_received'
  | 'payment_failed'
  | 'review_received'
  | 'subscription_expiring';

/** Spécialités photographiques disponibles. */
export const SPECIALTIES = [
  'Portrait',
  'Mariage',
  'Événement',
  'Corporate',
  'Mode',
  'Famille',
  'Nature',
  'Sport',
] as const;
export type Specialty = (typeof SPECIALTIES)[number];

/** Communes / villes de Côte d'Ivoire couvertes. */
export const COMMUNES = [
  'Abidjan - Cocody',
  'Abidjan - Plateau',
  'Abidjan - Marcory',
  'Abidjan - Yopougon',
  'Abidjan - Treichville',
  'Abidjan - Adjamé',
  'Abidjan - Abobo',
  'Abidjan - Koumassi',
  'Abidjan - Port-Bouët',
  'Abidjan - Bingerville',
  'Bouaké',
  'Yamoussoukro',
  'Daloa',
  'San-Pédro',
  'Man',
  'Korhogo',
] as const;
export type Commune = (typeof COMMUNES)[number];

/** Libellés français des statuts de réservation. */
export const BOOKING_STATUS_LABELS: Record<BookingStatus, string> = {
  en_attente: 'En attente',
  accepte: 'Accepté',
  refuse: 'Refusé',
  termine: 'Terminé',
  annule: 'Annulé',
  pending: 'En attente',
  confirmed: 'Confirmé',
  cancelled: 'Annulé',
  completed: 'Terminé',
};

/** Libellés des plans d'abonnement. */
export const PLAN_LABELS: Record<SubscriptionPlan, string> = {
  free: 'Gratuit',
  starter: 'Starter',
  pro: 'Pro',
  premium: 'Premium',
};

/** Prix des plans en XOF / mois. */
export const PLAN_PRICES: Record<SubscriptionPlan, number> = {
  free: 0,
  starter: 5_000,
  pro: 15_000,
  premium: 35_000,
};

/** Coût par défaut d'une prise de contact (XOF). */
export const DEFAULT_CONTACT_COST = 500;

/** Devise par défaut. */
export const DEFAULT_CURRENCY = 'XOF';
