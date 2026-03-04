// ─────────────────────────────────────────────────────────────────────────────
// Types API — Requêtes et réponses des Edge Functions Supabase
// ─────────────────────────────────────────────────────────────────────────────

// ─── send-otp ────────────────────────────────────────────────────────────────

export interface SendOtpRequest {
  phone: string; // format international : +225XXXXXXXXXX
}

export interface SendOtpResponse {
  success: boolean;
  message: string;
  /** Expire dans 10 minutes. */
  expires_at?: string;
}

// ─── verify-otp ──────────────────────────────────────────────────────────────

export interface VerifyOtpRequest {
  phone: string;
  otp: string; // 6 chiffres
}

export interface VerifyOtpResponse {
  success: boolean;
  /** Token de session Supabase si vérification réussie. */
  access_token?: string;
  refresh_token?: string;
  user_id?: string;
  is_new_user?: boolean;
  error?: string;
}

// ─── process-payment ─────────────────────────────────────────────────────────

export interface ProcessPaymentRequest {
  booking_id: string;
  amount: number;
  currency?: string; // défaut : 'XOF'
  operator: 'orange_money' | 'mtn_momo' | 'wave' | 'cinetpay' | 'card';
  phone_number?: string;
  /** Métadonnées libres transmises au fournisseur. */
  metadata?: Record<string, unknown>;
}

export interface ProcessPaymentResponse {
  success: boolean;
  payment_id: string;
  transaction_id?: string;
  /** URL de redirection (pour CinetPay / Wave web). */
  redirect_url?: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  error?: string;
}

// ─── auto-refund ─────────────────────────────────────────────────────────────

export interface AutoRefundRequest {
  payment_id: string;
  reason?: string;
}

export interface AutoRefundResponse {
  success: boolean;
  refund_id?: string;
  error?: string;
}

// ─── watermark ───────────────────────────────────────────────────────────────

export interface WatermarkRequest {
  /** Clé Cloudflare R2 de l'image source. */
  source_key: string;
  /** Texte du watermark. */
  text?: string;
  /** Position : 'bottom-right' | 'center' | 'tile'. */
  position?: 'bottom-right' | 'center' | 'tile';
  /** Opacité 0–1. */
  opacity?: number;
}

export interface WatermarkResponse {
  success: boolean;
  /** URL publique de l'image watermarkée. */
  watermarked_url?: string;
  /** Clé R2 de l'image watermarkée. */
  output_key?: string;
  error?: string;
}

// ─── sync-settings ───────────────────────────────────────────────────────────

export interface SyncSettingsResponse {
  contact_cost: number;
  payment_api_url: string;
  wasender_api_url: string;
  wasender_token: string;
  maintenance_mode: boolean;
}

// ─── Pagination ──────────────────────────────────────────────────────────────

export interface PaginationParams {
  page?: number;     // défaut : 1
  per_page?: number; // défaut : 20
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
}

// ─── Réponse d'erreur standard ───────────────────────────────────────────────

export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

// ─── Filtre photographes ──────────────────────────────────────────────────────

export interface PhotographerFilter {
  city?: string;
  specialty?: string;
  min_price?: number;
  max_price?: number;
  is_available?: boolean;
  min_rating?: number;
  search?: string; // recherche textuelle sur nom/bio
  sort_by?: 'rating' | 'price_asc' | 'price_desc' | 'newest';
}
