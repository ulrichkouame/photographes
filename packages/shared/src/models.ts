// ─────────────────────────────────────────────────────────────────────────────
// Modèles de domaine — Photographes.ci
// Correspondent aux tables Supabase et aux modèles Flutter.
// ─────────────────────────────────────────────────────────────────────────────

import type {
  BookingStatus,
  MobileMoneyOperator,
  NotificationType,
  PaymentStatus,
  SubscriptionPlan,
  SubscriptionStatus,
  UserRole,
} from './enums';

// ─── Profil utilisateur ───────────────────────────────────────────────────────

/** Correspond à la table `public.profiles`. */
export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  role: UserRole;
  created_at: string;
  updated_at: string;
}

// ─── Photographe ─────────────────────────────────────────────────────────────

/** Correspond à la table `public.photographers`. */
export interface Photographer {
  id: string;
  profile_id: string;
  bio: string | null;
  city: string | null;
  specialties: string[] | null;
  price_per_hour: number | null;
  is_available: boolean;
  created_at: string;
}

/** Vue enrichie `public.photographer_profiles` (avec stats agrégées). */
export interface PhotographerProfile extends Photographer {
  full_name: string | null;
  avatar_url: string | null;
  average_rating: number;
  review_count: number;
  portfolio_count: number;
}

// ─── Portfolio ────────────────────────────────────────────────────────────────

/** Correspond à la table `public.portfolio_photos`. */
export interface PortfolioPhoto {
  id: string;
  photographer_id: string;
  url: string;
  caption: string | null;
  category: string | null;
  is_cover: boolean;
  sort_order: number;
  created_at: string;
}

// ─── Réservation ─────────────────────────────────────────────────────────────

/** Correspond à la table `public.bookings`. */
export interface Booking {
  id: string;
  client_id: string | null;
  photographer_id: string | null;
  event_date: string;
  duration_hours: number;
  service_type: string | null;
  location: string | null;
  message: string | null;
  status: BookingStatus;
  total_price: number | null;
  contact_cost: number;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

/** Réservation enrichie avec les noms client/photographe. */
export interface BookingWithDetails extends Booking {
  client_name?: string;
  photographer_name?: string;
  photographer_avatar?: string;
}

// ─── Avis ─────────────────────────────────────────────────────────────────────

/** Correspond à la table `public.reviews`. */
export interface Review {
  id: string;
  booking_id: string;
  client_id: string;
  photographer_id: string;
  rating: number; // 1.0 – 5.0
  comment: string | null;
  created_at: string;
  /** Nom client pour affichage (jointure). */
  client_name?: string;
  client_avatar?: string;
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

/** Correspond à la table `public.chat_rooms`. */
export interface ChatRoom {
  id: string;
  booking_id: string | null;
  client_id: string;
  photographer_id: string;
  created_at: string;
  /** Last message (jointure). */
  last_message?: Message;
  unread_count?: number;
}

/** Correspond à la table `public.messages`. */
export interface Message {
  id: string;
  room_id: string;
  sender_id: string;
  content: string;
  is_read: boolean;
  created_at: string;
}

// ─── Paiement ─────────────────────────────────────────────────────────────────

/** Correspond à la table `public.payments`. */
export interface Payment {
  id: string;
  booking_id: string | null;
  client_id: string | null;
  amount: number;
  currency: string;
  operator: MobileMoneyOperator;
  phone_number: string | null;
  status: PaymentStatus;
  transaction_id: string | null;
  provider_ref: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

// ─── Service photographe ──────────────────────────────────────────────────────

/** Correspond à la table `public.services`. */
export interface Service {
  id: string;
  photographer_id: string;
  name: string;
  description: string | null;
  price: number;
  duration_hours: number | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ─── Abonnement ───────────────────────────────────────────────────────────────

/** Correspond à la table `public.subscriptions`. */
export interface Subscription {
  id: string;
  photographer_id: string;
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  started_at: string;
  expires_at: string | null;
  monthly_price: number;
  features: Record<string, unknown>;
  payment_id: string | null;
  created_at: string;
}

// ─── Notification ─────────────────────────────────────────────────────────────

/** Correspond à la table `public.notifications`. */
export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  body: string | null;
  data: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;
}

// ─── Paramètres utilisateur ───────────────────────────────────────────────────

/** Correspond à la table `public.app_settings`. */
export interface AppSettings {
  user_id: string;
  language: string;
  dark_mode: boolean;
  notifications_push: boolean;
  notifications_email: boolean;
  notifications_sms: boolean;
  currency: string;
  updated_at: string;
}

// ─── Disponibilité ────────────────────────────────────────────────────────────

/** Correspond à la table `public.availability`. */
export interface Availability {
  id: string;
  photographer_id: string;
  date: string; // ISO date YYYY-MM-DD
  is_available: boolean;
  slots_remaining: number;
  note: string | null;
}

// ─── OTP ──────────────────────────────────────────────────────────────────────

/** Correspond à la table `public.otp_verifications`. */
export interface OtpVerification {
  id: string;
  phone: string;
  otp_hash: string;
  attempts: number;
  verified: boolean;
  expires_at: string;
  created_at: string;
}
