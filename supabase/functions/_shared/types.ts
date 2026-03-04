/**
 * Shared type definitions for photographes.ci Supabase Edge Functions
 */

// ─── App Settings ────────────────────────────────────────────────────────────

export interface AppSetting {
  id: string;
  key: string;
  value: string;
  description?: string;
  is_public: boolean;
  created_at: string;
  updated_at: string;
}

// ─── OTP ─────────────────────────────────────────────────────────────────────

export interface OtpVerification {
  id: string;
  phone: string;
  code: string;
  expires_at: string;
  verified: boolean;
  created_at: string;
}

export interface SendOtpRequest {
  phone: string;
}

export interface SendOtpResponse {
  success: boolean;
  message: string;
  expires_in_seconds: number;
}

export interface VerifyOtpRequest {
  phone: string;
  code: string;
}

export interface VerifyOtpResponse {
  success: boolean;
  access_token?: string;
  refresh_token?: string;
  user?: Record<string, unknown>;
  message: string;
}

// ─── Watermark ───────────────────────────────────────────────────────────────

export interface WatermarkRequest {
  image_url?: string;
  storage_path?: string;
}

export interface WatermarkResponse {
  success: boolean;
  watermarked_url: string;
  thumbnail_url: string;
  message: string;
}

// ─── Payment ─────────────────────────────────────────────────────────────────

export type PaymentProvider = "mtn" | "orange" | "wave" | "moov";
export type PaymentStatus = "pending" | "success" | "failed" | "cancelled";

export interface PaymentRequest {
  amount: number;
  phone: string;
  provider: PaymentProvider;
  reference: string;
  description?: string;
  contact_id?: string;
}

export interface PaymentResponse {
  success: boolean;
  transaction_id?: string;
  status: PaymentStatus;
  message: string;
  provider_reference?: string;
}

export interface PaymentTransaction {
  id: string;
  reference: string;
  amount: number;
  phone: string;
  provider: PaymentProvider;
  status: PaymentStatus;
  contact_id?: string;
  provider_reference?: string;
  created_at: string;
  updated_at: string;
}

// ─── Refund ──────────────────────────────────────────────────────────────────

export interface RefundResult {
  contact_id: string;
  transaction_id: string;
  amount: number;
  status: "refunded" | "failed";
  message: string;
}

export interface AutoRefundResponse {
  success: boolean;
  processed: number;
  refunded: number;
  failed: number;
  results: RefundResult[];
}

// ─── Settings Sync ───────────────────────────────────────────────────────────

export interface SyncSettingsResponse {
  success: boolean;
  settings: Record<string, string>;
  count: number;
  synced_at: string;
}

// ─── HTTP Helpers ─────────────────────────────────────────────────────────────

export interface ApiError {
  error: string;
  code?: string;
  details?: string;
}
