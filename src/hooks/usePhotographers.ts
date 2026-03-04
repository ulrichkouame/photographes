'use client'

import { useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { Photographer } from '@/types/database'

interface Filters {
  search?: string
  category?: string
  commune?: string
  budget_min?: number
  budget_max?: number
  min_rating?: number
  available?: boolean
  page?: number
  limit?: number
}

export function usePhotographers(initialFilters: Filters = {}) {
  const [photographers, setPhotographers] = useState<Photographer[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<Filters>(initialFilters)
  const [total, setTotal] = useState(0)

  const fetchPhotographers = useCallback(async (f: Filters = filters) => {
    setLoading(true)
    setError(null)
    try {
      const params = new URLSearchParams()
      if (f.search) params.set('search', f.search)
      if (f.category) params.set('category', f.category)
      if (f.commune) params.set('commune', f.commune)
      if (f.budget_min !== undefined) params.set('budget_min', String(f.budget_min))
      if (f.budget_max !== undefined) params.set('budget_max', String(f.budget_max))
      if (f.min_rating !== undefined) params.set('min_rating', String(f.min_rating))
      if (f.available !== undefined) params.set('available', String(f.available))
      if (f.page !== undefined) params.set('page', String(f.page))
      if (f.limit !== undefined) params.set('limit', String(f.limit))

      const res = await fetch(`/api/photographers?${params.toString()}`)
      if (!res.ok) throw new Error('Erreur lors du chargement des photographes')
      const data = await res.json()
      setPhotographers(data.photographers ?? [])
      setTotal(data.total ?? 0)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur inconnue')
    } finally {
      setLoading(false)
    }
  }, [filters])

  const updateFilters = useCallback((newFilters: Partial<Filters>) => {
    const updated = { ...filters, ...newFilters, page: 1 }
    setFilters(updated)
    fetchPhotographers(updated)
  }, [filters, fetchPhotographers])

  return { photographers, loading, error, filters, total, fetchPhotographers, updateFilters }
}
