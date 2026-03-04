'use client'

import { PhotographersTable } from '@/components/admin/PhotographersTable'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { createClient } from '@/lib/supabase/client'
import type { Photographer } from '@/types/database'
import { Loader2 } from 'lucide-react'
import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'

export default function AdminPhotographersPage() {
  const [photographers, setPhotographers] = useState<Photographer[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  const loadPhotographers = useCallback(async () => {
    const supabase = createClient()
    setLoading(true)
    let query = supabase.from('photographes_photographer_profiles').select('*').order('created_at', { ascending: false })
    if (search) query = query.ilike('name', `%${search}%`)
    const { data } = await query
    setPhotographers(data ?? [])
    setLoading(false)
  }, [search])

  useEffect(() => { loadPhotographers() }, [loadPhotographers])

  const handleToggleFeatured = async (id: string, value: boolean) => {
    const supabase = createClient()
    await supabase.from('photographes_photographers').update({ is_featured: value }).eq('id', id)
    toast.success(value ? 'Mis en vedette' : 'Retiré de la vedette')
    loadPhotographers()
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Supprimer ce photographe ?')) return
    const supabase = createClient()
    await supabase.from('photographes_photographers').delete().eq('id', id)
    toast.success('Photographe supprimé')
    loadPhotographers()
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Photographes</h1>
        <p className="text-muted-foreground">Gestion des photographes inscrits</p>
      </div>
      <Input
        placeholder="Rechercher un photographe..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="max-w-md"
      />
      <Card>
        <CardHeader>
          <CardTitle>Liste des photographes</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <Loader2 className="h-6 w-6 animate-spin" />
            </div>
          ) : (
            <PhotographersTable
              photographers={photographers}
              onToggleFeatured={handleToggleFeatured}
              onDelete={handleDelete}
            />
          )}
        </CardContent>
      </Card>
    </div>
  )
}
