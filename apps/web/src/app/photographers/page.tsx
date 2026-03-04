'use client'

import { useState } from 'react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { PhotographerFilters } from '@/components/photographers/PhotographerFilters'
import { PhotographerFeed } from '@/components/photographers/PhotographerFeed'

export default function PhotographersPage() {
  const [filters, setFilters] = useState({})

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1 container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Photographes</h1>
          <p className="text-muted-foreground">
            Découvrez les meilleurs photographes de Côte d&apos;Ivoire
          </p>
        </div>
        <div className="flex flex-col lg:flex-row gap-8">
          <aside className="lg:w-72 shrink-0">
            <PhotographerFilters onChange={setFilters} />
          </aside>
          <div className="flex-1">
            <PhotographerFeed initialFilters={filters} />
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
