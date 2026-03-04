'use client'

import { useEffect } from 'react'
import { PhotographerCard } from './PhotographerCard'
import { usePhotographers } from '@/hooks/usePhotographers'
import { Loader2 } from 'lucide-react'

interface PhotographerFeedProps {
  initialFilters?: Record<string, unknown>
}

export function PhotographerFeed({ initialFilters = {} }: PhotographerFeedProps) {
  const { photographers, loading, error, filters, fetchPhotographers } = usePhotographers(initialFilters)

  useEffect(() => {
    fetchPhotographers(filters)
  }, [fetchPhotographers]) // eslint-disable-line react-hooks/exhaustive-deps

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-20 text-destructive">
        <p>{error}</p>
      </div>
    )
  }

  if (photographers.length === 0) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        <p className="text-lg">Aucun photographe trouvé</p>
        <p className="text-sm mt-2">Essayez de modifier vos filtres</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {photographers.map((p) => (
        <PhotographerCard key={p.id} photographer={p} />
      ))}
    </div>
  )
}
