'use client'

import { useState } from 'react'
import { useSettings } from '@/hooks/useSettings'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'

export default function AdminSettingsPage() {
  const { settings, loading, updateSetting } = useSettings()
  const [editKey, setEditKey] = useState('')
  const [editValue, setEditValue] = useState('')
  const [newKey, setNewKey] = useState('')
  const [newValue, setNewValue] = useState('')

  const handleEdit = (key: string, value: string) => {
    setEditKey(key)
    setEditValue(value)
  }

  const handleSave = async () => {
    if (!editKey) return
    const { error } = await updateSetting(editKey, editValue)
    if (error) {
      toast.error('Erreur lors de la mise à jour')
    } else {
      toast.success('Paramètre mis à jour')
      setEditKey('')
      setEditValue('')
    }
  }

  const handleCreate = async () => {
    if (!newKey || !newValue) return
    const { error } = await updateSetting(newKey, newValue)
    if (error) {
      toast.error('Erreur lors de la création')
    } else {
      toast.success('Paramètre créé')
      setNewKey('')
      setNewValue('')
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Paramètres</h1>
        <p className="text-muted-foreground">Configuration de l&apos;application</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Nouveau paramètre</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex gap-3">
            <div className="flex-1">
              <Label>Clé</Label>
              <Input value={newKey} onChange={(e) => setNewKey(e.target.value)} placeholder="nom_parametre" />
            </div>
            <div className="flex-1">
              <Label>Valeur</Label>
              <Input value={newValue} onChange={(e) => setNewValue(e.target.value)} placeholder="valeur" />
            </div>
            <div className="flex items-end">
              <Button onClick={handleCreate}>Créer</Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Paramètres existants</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {settings.map((s) => (
            <div key={s.id} className="flex gap-3 items-end border-b pb-4">
              <div className="flex-1">
                <Label>Clé</Label>
                <Input value={s.key} readOnly className="bg-muted" />
              </div>
              <div className="flex-1">
                <Label>Valeur</Label>
                <Input
                  value={editKey === s.key ? editValue : s.value}
                  onChange={(e) => {
                    handleEdit(s.key, e.target.value)
                  }}
                  onFocus={() => handleEdit(s.key, s.value)}
                />
              </div>
              <Button
                variant="outline"
                onClick={() => { handleEdit(s.key, editKey === s.key ? editValue : s.value); handleSave() }}
                disabled={editKey !== s.key}
              >
                Enregistrer
              </Button>
            </div>
          ))}
          {settings.length === 0 && (
            <p className="text-muted-foreground text-center py-4">Aucun paramètre configuré</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
