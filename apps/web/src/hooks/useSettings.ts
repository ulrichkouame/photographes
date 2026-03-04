'use client'

import { createClient } from '@/lib/supabase/client'
import { useCallback, useEffect, useState } from 'react'

export interface UserSettings {
  user_id: string
  language: string
  dark_mode: boolean
  notifications_push: boolean
  notifications_email: boolean
  notifications_sms: boolean
  currency: string
}

const DEFAULT_SETTINGS: Omit<UserSettings, 'user_id'> = {
  language: 'fr',
  dark_mode: false,
  notifications_push: true,
  notifications_email: true,
  notifications_sms: true,
  currency: 'XOF',
}

export function useSettings() {
  const [settings, setSettings] = useState<UserSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchSettings = useCallback(async () => {
    const supabase = createClient()
    setLoading(true)
    setError(null)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return
      const { data, error } = await supabase
        .from('photographes_app_settings')
        .select('*')
        .eq('user_id', user.id)
        .single()
      if (error && error.code !== 'PGRST116') throw error // PGRST116 = no rows found
      setSettings(data ?? { user_id: user.id, ...DEFAULT_SETTINGS })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur inconnue')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchSettings() }, [fetchSettings])

  const updateSettings = async (patch: Partial<Omit<UserSettings, 'user_id'>>) => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { error: new Error('Non authentifié') }

    const { error } = await supabase
      .from('photographes_app_settings')
      .upsert({ user_id: user.id, ...patch }, { onConflict: 'user_id' })
    if (!error) await fetchSettings()
    return { error }
  }

  return { settings, loading, error, updateSettings, refetch: fetchSettings }
}
