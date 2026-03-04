/**
 * Shared HTTP utilities for photographes.ci Supabase Edge Functions
 */

import type { ApiError } from "./types.ts";

/** Standard CORS headers for all responses */
export const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

/** Return a JSON success response with CORS headers */
export function jsonResponse(
  data: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS,
      ...extraHeaders,
    },
  });
}

/** Return a JSON error response with CORS headers */
export function errorResponse(
  error: string,
  status = 400,
  code?: string,
  details?: string,
): Response {
  const body: ApiError = { error, ...(code ? { code } : {}), ...(details ? { details } : {}) };
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

/** Handle preflight OPTIONS request */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  return null;
}

/** Parse JSON body safely */
export async function parseJsonBody<T>(req: Request): Promise<T | null> {
  try {
    const text = await req.text();
    if (!text) return null;
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}

/** Validate that required fields are present in a body object */
export function validateRequiredFields(
  body: Record<string, unknown>,
  fields: string[],
): string | null {
  for (const field of fields) {
    if (body[field] === undefined || body[field] === null || body[field] === "") {
      return `Le champ '${field}' est requis.`;
    }
  }
  return null;
}

/** Generate a random numeric OTP code of `length` digits */
export function generateOtp(length = 6): string {
  const digits = "0123456789";
  let otp = "";
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  for (const byte of array) {
    otp += digits[byte % 10];
  }
  return otp;
}

/** Add `seconds` to current time and return ISO string */
export function expiresAt(seconds: number): string {
  return new Date(Date.now() + seconds * 1000).toISOString();
}

/** Check if a date string is in the past */
export function isExpired(dateStr: string): boolean {
  return new Date(dateStr) < new Date();
}

/** Sanitise a phone number to E.164 format for Côte d'Ivoire (+225) */
export function sanitisePhone(phone: string): string | null {
  const cleaned = phone.replace(/\D/g, "");
  // Accept 10-digit CI numbers (must start with 0, e.g. 07XXXXXXXX)
  if (cleaned.length === 10 && cleaned.startsWith("0")) return `+225${cleaned}`;
  // Accept 225XXXXXXXXXX (13 digits with country code)
  if (cleaned.length === 13 && cleaned.startsWith("225")) return `+${cleaned}`;
  // Accept 225XXXXXXXXX (12 digits, e.g. 2250XXXXXXXXX)
  if (cleaned.length === 12 && cleaned.startsWith("225")) return `+${cleaned}`;
  return null;
}
