'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { PhotographersTable } from '@/components/admin/PhotographersTable'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { Photographer } from '@/types/database'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'

export default function AdminPhotographersPage() {
  const [photographers, setPhotographers] = useState<Photographer[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const supabase = createClient()

  const loadPhotographers = async () => {
    setLoading(true)
    let query = supabase.from('photographes_photographers').select('*').order('created_at', { ascending: false })
    if (search) query = query.ilike('name', `%${search}%`)
    const { data } = await query
    setPhotographers(data ?? [])
    setLoading(false)
  }

  useEffect(() => { loadPhotographers() }, [search]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleToggleFeatured = async (id: string, value: boolean) => {
    await supabase.from('photographes_photographers').update({ featured: value }).eq('id', id)
    toast.success(value ? 'Mis en vedette' : 'Retiré de la vedette')
    loadPhotographers()
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Supprimer ce photographe ?')) return
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
