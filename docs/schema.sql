-- ============================================================
-- photographes.ci — Schéma de base de données (Supabase/PostgreSQL)
-- ============================================================
-- Exécuter dans l'éditeur SQL Supabase ou via les migrations.
-- ============================================================

-- ─── Extensions ───────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── app_settings ─────────────────────────────────────────────────────────────
-- Paramètres dynamiques de l'application (clé/valeur)
CREATE TABLE IF NOT EXISTS public.app_settings (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    key         TEXT        UNIQUE NOT NULL,
    value       TEXT        NOT NULL,
    description TEXT,
    is_public   BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.app_settings IS 'Configuration dynamique de l''application photographes.ci';
COMMENT ON COLUMN public.app_settings.is_public IS 'Si true, visible via sync-settings sans authentification';

-- ─── otp_verifications ────────────────────────────────────────────────────────
-- Codes OTP temporaires envoyés par WhatsApp
CREATE TABLE IF NOT EXISTS public.otp_verifications (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone       TEXT        UNIQUE NOT NULL,
    code        TEXT        NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    verified    BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.otp_verifications IS 'Codes OTP pour l''authentification par numéro de téléphone';

-- ─── contacts ─────────────────────────────────────────────────────────────────
-- Profils des photographes (vendeurs de coordonnées)
CREATE TABLE IF NOT EXISTS public.contacts (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
    name         TEXT        NOT NULL,
    phone        TEXT,
    email        TEXT,
    city         TEXT,
    speciality   TEXT,
    bio          TEXT,
    avatar_url   TEXT,
    portfolio    JSONB       DEFAULT '[]',
    status       TEXT        NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending','active','expired','unprocessed','refunded','cancelled')),
    expires_at   TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.contacts IS 'Profils des photographes disponibles sur photographes.ci';
COMMENT ON COLUMN public.contacts.status IS 'pending=en attente de paiement, active=visible, expired=expiré, unprocessed=payé mais non traité, refunded=remboursé';

-- ─── payment_transactions ─────────────────────────────────────────────────────
-- Transactions Mobile Money
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference               TEXT        UNIQUE NOT NULL,
    amount                  NUMERIC     NOT NULL CHECK (amount > 0),
    phone                   TEXT        NOT NULL,
    provider                TEXT        NOT NULL CHECK (provider IN ('mtn','orange','wave','moov')),
    status                  TEXT        NOT NULL DEFAULT 'pending'
                                        CHECK (status IN ('pending','success','failed','cancelled','refunded')),
    contact_id              UUID        REFERENCES public.contacts(id) ON DELETE SET NULL,
    provider_reference      TEXT,
    description             TEXT,
    is_refund               BOOLEAN     NOT NULL DEFAULT false,
    original_transaction_id UUID        REFERENCES public.payment_transactions(id) ON DELETE SET NULL,
    refund_transaction_id   UUID        REFERENCES public.payment_transactions(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.payment_transactions IS 'Historique des transactions Mobile Money';
COMMENT ON COLUMN public.payment_transactions.is_refund IS 'Si true, cette transaction est un remboursement';

-- ─── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_otp_phone ON public.otp_verifications (phone);
CREATE INDEX IF NOT EXISTS idx_otp_expires ON public.otp_verifications (expires_at);
CREATE INDEX IF NOT EXISTS idx_contacts_status ON public.contacts (status);
CREATE INDEX IF NOT EXISTS idx_contacts_expires ON public.contacts (expires_at);
CREATE INDEX IF NOT EXISTS idx_payment_status ON public.payment_transactions (status);
CREATE INDEX IF NOT EXISTS idx_payment_contact ON public.payment_transactions (contact_id);
CREATE INDEX IF NOT EXISTS idx_payment_reference ON public.payment_transactions (reference);
CREATE INDEX IF NOT EXISTS idx_settings_key ON public.app_settings (key);
CREATE INDEX IF NOT EXISTS idx_settings_public ON public.app_settings (is_public) WHERE is_public = true;

-- ─── Row Level Security ───────────────────────────────────────────────────────
ALTER TABLE public.app_settings         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_verifications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- app_settings: lecture publique uniquement pour is_public=true
CREATE POLICY "public_settings_read" ON public.app_settings
    FOR SELECT USING (is_public = true);

-- otp_verifications: Edge Functions uniquement (service role)
CREATE POLICY "service_role_otp" ON public.otp_verifications
    USING (auth.role() = 'service_role');

-- contacts: lecture publique, modification par propriétaire ou service_role
CREATE POLICY "contacts_public_read" ON public.contacts
    FOR SELECT USING (status = 'active');

CREATE POLICY "contacts_owner_update" ON public.contacts
    FOR UPDATE USING (
        auth.uid() = user_id OR auth.role() = 'service_role'
    );

CREATE POLICY "contacts_owner_insert" ON public.contacts
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR auth.role() = 'service_role'
    );

-- payment_transactions: lecture par propriétaire ou service_role
CREATE POLICY "payments_owner_read" ON public.payment_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.contacts c
            WHERE c.id = contact_id AND c.user_id = auth.uid()
        ) OR auth.role() = 'service_role'
    );

CREATE POLICY "payments_service_insert" ON public.payment_transactions
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "payments_service_update" ON public.payment_transactions
    FOR UPDATE USING (auth.role() = 'service_role');

-- ─── Triggers updated_at ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_app_settings_updated_at
    BEFORE UPDATE ON public.app_settings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_otp_updated_at
    BEFORE UPDATE ON public.otp_verifications
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_contacts_updated_at
    BEFORE UPDATE ON public.contacts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_payment_updated_at
    BEFORE UPDATE ON public.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── Données initiales (app_settings) ────────────────────────────────────────
INSERT INTO public.app_settings (key, value, description, is_public) VALUES
    ('app_name',              'photographes.ci',                'Nom de l''application',                          true),
    ('app_version',           '1.0.0',                          'Version de l''application',                      true),
    ('app_currency',          'XOF',                            'Devise utilisée (FCFA)',                         true),
    ('app_country_code',      '+225',                           'Indicatif pays (Côte d''Ivoire)',                true),
    ('contact_price',         '5000',                           'Prix d''accès aux coordonnées (FCFA)',           true),
    ('contact_validity_days', '30',                             'Durée de validité d''un accès contact (jours)', true),
    ('otp_expiry_seconds',    '600',                            'Durée de validité OTP (secondes)',               false),
    ('watermark_text',        'photographes.ci',                'Texte du watermark sur les images',              false),
    ('refund_provider',       'mtn',                            'Provider de remboursement par défaut',           false),
    ('wasender_api_url',      'https://api.wasenderapi.com/api/send-message', 'URL API WasenderAPI', false)
ON CONFLICT (key) DO NOTHING;
