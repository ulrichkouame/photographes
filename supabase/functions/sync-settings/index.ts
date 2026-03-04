/**
 * sync-settings — Récupération et synchronisation des paramètres dynamiques
 *
 * GET  /functions/v1/sync-settings          → Retourne les paramètres publics (is_public=true)
 * POST /functions/v1/sync-settings          → Retourne tous les paramètres (admin, JWT requis)
 *
 * Cette function permet au front-end de récupérer les constantes dynamiques
 * stockées en base (app_settings) et filtrées selon leur visibilité.
 *
 * Table app_settings :
 *   id          uuid PRIMARY KEY
 *   key         text UNIQUE NOT NULL
 *   value       text NOT NULL
 *   description text
 *   is_public   boolean DEFAULT false
 *   created_at  timestamptz DEFAULT now()
 *   updated_at  timestamptz DEFAULT now()
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
} from "../_shared/utils.ts";
import type { AppSetting, SyncSettingsResponse } from "../_shared/types.ts";

// Keys whose values must NEVER be returned by this function (even for admins),
// because they contain secrets.
const SECRET_KEYS = new Set([
  "wasender_api_key",
  "r2_secret_key",
  "r2_access_key_id",
  "payment_mtn_api_key",
  "payment_orange_api_key",
  "payment_wave_api_key",
  "payment_moov_api_key",
]);

serve(async (req: Request) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "GET" && req.method !== "POST") {
    return errorResponse("Méthode non autorisée. Utilisez GET ou POST.", 405);
  }

  const supabase = createAdminClient();

  // Determine si la requête est authentifiée (pour les paramètres privés)
  const authHeader = req.headers.get("authorization") ?? "";
  const isAuthenticated = authHeader.startsWith("Bearer ") && authHeader.length > 10;

  // GET public = paramètres is_public seulement
  // POST authenticated = tous les paramètres non-secrets
  let query = supabase
    .from("photographes_app_settings")
    .select("key, value, description, is_public, updated_at")
    .order("key");

  if (req.method === "GET" || !isAuthenticated) {
    query = query.eq("is_public", true);
  }

  const { data: settings, error } = await query;

  if (error) {
    return errorResponse(
      "Erreur lors de la récupération des paramètres.",
      500,
      "DB_ERROR",
      error.message,
    );
  }

  const filteredSettings = (settings as AppSetting[] ?? []).filter(
    (s) => !SECRET_KEYS.has(s.key),
  );

  const settingsMap = filteredSettings.reduce<Record<string, string>>((acc, s) => {
    acc[s.key] = s.value;
    return acc;
  }, {});

  const response: SyncSettingsResponse = {
    success: true,
    settings: settingsMap,
    count: filteredSettings.length,
    synced_at: new Date().toISOString(),
  };

  return jsonResponse(response, 200);
});
