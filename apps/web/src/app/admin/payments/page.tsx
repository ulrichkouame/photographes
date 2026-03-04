import { PaymentsTable } from '@/components/admin/PaymentsTable'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { createClient } from '@/lib/supabase/server'

export default async function AdminPaymentsPage() {
  const supabase = await createClient()
  const { data: payments } = await supabase
    .from('payments')
    .select('*')
    .order('created_at', { ascending: false })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Paiements</h1>
        <p className="text-muted-foreground">Historique de tous les paiements</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Paiements ({payments?.length ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          <PaymentsTable payments={payments ?? []} />
        </CardContent>
      </Card>
    </div>
  )
}
