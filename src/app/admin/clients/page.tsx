import { createClient } from '@/lib/supabase/server'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow
} from '@/components/ui/table'

export default async function AdminClientsPage() {
  const supabase = await createClient()
  const { data: clients } = await supabase
    .from('photographes_clients')
    .select('*')
    .order('created_at', { ascending: false })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Clients</h1>
        <p className="text-muted-foreground">Liste des clients inscrits</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Clients ({clients?.length ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nom</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Date d&apos;inscription</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {(clients ?? []).map((client) => (
                <TableRow key={client.id}>
                  <TableCell className="font-medium">{client.name}</TableCell>
                  <TableCell>{client.email}</TableCell>
                  <TableCell>{new Date(client.created_at).toLocaleDateString('fr-CI')}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
