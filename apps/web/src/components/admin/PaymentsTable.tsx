'use client'

import { Badge } from '@/components/ui/badge'
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow
} from '@/components/ui/table'
import type { Payment } from '@/types/database'
import { formatCurrency, formatDate } from '@/lib/utils'

interface PaymentsTableProps {
  payments: Payment[]
}

const statusLabels: Record<string, string> = {
  pending: 'En attente',
  completed: 'Complété',
  failed: 'Échoué',
  refunded: 'Remboursé',
}

const statusVariants: Record<string, 'default' | 'secondary' | 'destructive' | 'outline' | 'success'> = {
  pending: 'secondary',
  completed: 'success',
  failed: 'destructive',
  refunded: 'outline',
}

export function PaymentsTable({ payments }: PaymentsTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>ID</TableHead>
          <TableHead>Prestataire</TableHead>
          <TableHead>Montant</TableHead>
          <TableHead>Statut</TableHead>
          <TableHead>Date</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {payments.map((p) => (
          <TableRow key={p.id}>
            <TableCell className="font-mono text-xs">{p.id.slice(0, 8)}...</TableCell>
            <TableCell>{p.provider}</TableCell>
            <TableCell className="font-medium">{formatCurrency(p.amount)}</TableCell>
            <TableCell>
              <Badge variant={statusVariants[p.status] ?? 'outline'}>
                {statusLabels[p.status] ?? p.status}
              </Badge>
            </TableCell>
            <TableCell>{formatDate(p.created_at)}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
