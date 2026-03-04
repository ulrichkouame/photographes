'use client'

import { Badge } from '@/components/ui/badge'
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import type { Photographer } from '@/types/database'

interface PhotographersTableProps {
  photographers: Photographer[]
  onToggleFeatured?: (id: string, value: boolean) => void
  onDelete?: (id: string) => void
}

export function PhotographersTable({ photographers, onToggleFeatured, onDelete }: PhotographersTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Nom</TableHead>
          <TableHead>Commune</TableHead>
          <TableHead>Plan</TableHead>
          <TableHead>Note</TableHead>
          <TableHead>Statut</TableHead>
          <TableHead>En vedette</TableHead>
          <TableHead>Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {photographers.map((p) => (
          <TableRow key={p.id}>
            <TableCell className="font-medium">{p.name}</TableCell>
            <TableCell>{p.commune ?? '—'}</TableCell>
            <TableCell>
              <Badge variant="outline">{p.subscription_plan}</Badge>
            </TableCell>
            <TableCell>⭐ {p.rating.toFixed(1)}</TableCell>
            <TableCell>
              {p.available ? (
                <Badge variant="success">Disponible</Badge>
              ) : (
                <Badge variant="secondary">Indisponible</Badge>
              )}
            </TableCell>
            <TableCell>
              {p.featured ? (
                <Badge variant="default">Oui</Badge>
              ) : (
                <Badge variant="outline">Non</Badge>
              )}
            </TableCell>
            <TableCell>
              <div className="flex gap-2">
                {onToggleFeatured && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onToggleFeatured(p.id, !p.featured)}
                  >
                    {p.featured ? 'Retirer' : 'Mettre en vedette'}
                  </Button>
                )}
                {onDelete && (
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => onDelete(p.id)}
                  >
                    Supprimer
                  </Button>
                )}
              </div>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
