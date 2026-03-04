'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { AppSetting } from '@/types/database'

export function useSettings() {
  const [settings, setSettings] = useState<AppSetting[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchSettings = useCallback(async () => {
    const supabase = createClient()
    setLoading(true)
    setError(null)
    try {
      const { data, error } = await supabase
        .from('photographes_app_settings')
        .select('*')
        .order('key')
      if (error) throw error
      setSettings(data ?? [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur inconnue')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchSettings() }, [fetchSettings])

  const updateSetting = async (key: string, value: string) => {
    const supabase = createClient()
    const { error } = await supabase
      .from('photographes_app_settings')
      .upsert({ key, value, updated_at: new Date().toISOString() }, { onConflict: 'key' })
    if (!error) await fetchSettings()
    return { error }
  }

  const getSetting = (key: string) => settings.find(s => s.key === key)?.value ?? null

  return { settings, loading, error, updateSetting, getSetting, refetch: fetchSettings }
}
