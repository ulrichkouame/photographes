'use client'

import { useState } from 'react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue
} from '@/components/ui/select'

const CATEGORIES = [
  'Mariage', 'Portrait', 'Commercial', 'Événement', 'Mode', 'Architecture', 'Nature', 'Sport'
]

const COMMUNES = [
  'Abidjan', 'Cocody', 'Plateau', 'Marcory', 'Yopougon', 'Adjamé', 'Bouaké', 'Yamoussoukro'
]

interface FilterValues {
  search: string
  category: string
  commune: string
  min_rating: number
  available: boolean
}

interface PhotographerFiltersProps {
  onChange: (filters: Partial<FilterValues>) => void
}

export function PhotographerFilters({ onChange }: PhotographerFiltersProps) {
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('')
  const [commune, setCommune] = useState('')
  const [minRating, setMinRating] = useState(0)
  const [available, setAvailable] = useState(false)

  const handleApply = () => {
    onChange({ search, category, commune, min_rating: minRating, available })
  }

  const handleReset = () => {
    setSearch('')
    setCategory('')
    setCommune('')
    setMinRating(0)
    setAvailable(false)
    onChange({ search: '', category: '', commune: '', min_rating: 0, available: false })
  }

  return (
    <div className="bg-card border rounded-lg p-4 space-y-4">
      <h3 className="font-semibold">Filtres</h3>
      <div className="space-y-2">
        <Label htmlFor="search">Recherche</Label>
        <Input
          id="search"
          placeholder="Nom, bio..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>
      <div className="space-y-2">
        <Label>Catégorie</Label>
        <Select value={category} onValueChange={setCategory}>
          <SelectTrigger>
            <SelectValue placeholder="Toutes les catégories" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Toutes les catégories</SelectItem>
            {CATEGORIES.map((c) => (
              <SelectItem key={c} value={c}>{c}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2">
        <Label>Commune</Label>
        <Select value={commune} onValueChange={setCommune}>
          <SelectTrigger>
            <SelectValue placeholder="Toutes les communes" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Toutes les communes</SelectItem>
            {COMMUNES.map((c) => (
              <SelectItem key={c} value={c}>{c}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2">
        <Label htmlFor="min-rating">Note minimale: {minRating}/5</Label>
        <input
          id="min-rating"
          type="range"
          min={0}
          max={5}
          step={0.5}
          value={minRating}
          onChange={(e) => setMinRating(Number(e.target.value))}
          className="w-full"
        />
      </div>
      <div className="flex items-center justify-between">
        <Label htmlFor="available">Disponibles uniquement</Label>
        <Switch id="available" checked={available} onCheckedChange={setAvailable} />
      </div>
      <div className="flex gap-2">
        <Button className="flex-1" onClick={handleApply}>Appliquer</Button>
        <Button variant="outline" onClick={handleReset}>Réinitialiser</Button>
      </div>
    </div>
  )
}
