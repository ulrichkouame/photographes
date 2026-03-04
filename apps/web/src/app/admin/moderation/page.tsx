import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow
} from '@/components/ui/table'
import { createClient } from '@/lib/supabase/server'

export default async function AdminModerationPage() {
  const supabase = await createClient()
  const { data: photographers } = await supabase
    .from('photographer_profiles')
    .select('*')
    .eq('available', false)
    .order('created_at', { ascending: false })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Modération</h1>
        <p className="text-muted-foreground">Photographes nécessitant une vérification</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>En attente de validation ({photographers?.length ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nom</TableHead>
                <TableHead>Commune</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {(photographers ?? []).map((p) => (
                <TableRow key={p.id}>
                  <TableCell className="font-medium">{p.name}</TableCell>
                  <TableCell>{p.commune ?? '—'}</TableCell>
                  <TableCell><Badge variant="outline">{p.subscription_plan}</Badge></TableCell>
                  <TableCell><Badge variant="secondary">Indisponible</Badge></TableCell>
                  <TableCell>
                    <Button variant="outline" size="sm">Examiner</Button>
                  </TableCell>
                </TableRow>
              ))}
              {(photographers ?? []).length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                    Aucun élément à modérer
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
