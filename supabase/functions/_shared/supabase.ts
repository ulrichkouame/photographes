/**
 * Supabase client factory for photographes.ci Edge Functions
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Create an admin Supabase client using the service-role key.
 * Should only be used server-side (Edge Functions).
 */
export function createAdminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables are required.",
    );
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Create a regular (anon) Supabase client.
 * Used for operations that should respect Row Level Security.
 */
export function createAnonClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !key) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required.",
    );
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Read a setting value from the `app_settings` table.
 * Falls back to an optional environment variable.
 */
export async function getAppSetting(
  // deno-lint-ignore no-explicit-any
  supabase: ReturnType<typeof createClient<any>>,
  key: string,
  envFallback?: string,
): Promise<string | null> {
  const { data, error } = await supabase
    .from("photographes_app_settings")
    .select("value")
    .eq("key", key)
    .single();

  if (error || !data) {
    if (envFallback) return Deno.env.get(envFallback) ?? null;
    return null;
  }
  return data.value as string;
}
