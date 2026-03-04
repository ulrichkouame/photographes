/**
 * @photographes/shared
 * Types TypeScript partagés entre apps/web et toute intégration TS.
 * Alignés sur le schéma Supabase et les modèles Flutter.
 */

// ─── Enums & constantes ───────────────────────────────────────────────────────
export * from './enums';

// ─── Modèles de domaine ───────────────────────────────────────────────────────
export * from './models';

// ─── Types de la base de données (style Supabase) ────────────────────────────
export * from './database.types';

// ─── Types API (requêtes / réponses Edge Functions) ──────────────────────────
export * from './api';

// ─── Utilitaires de types ────────────────────────────────────────────────────
export * from './utils';
