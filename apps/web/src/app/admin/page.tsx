import { AnalyticsChart } from '@/components/admin/AnalyticsChart'
import { PaymentsTable } from '@/components/admin/PaymentsTable'
import { StatsCard } from '@/components/admin/StatsCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { createClient } from '@/lib/supabase/server'
import { CalendarCheck, Camera, CreditCard, Users } from 'lucide-react'

export default async function AdminDashboardPage() {
  const supabase = await createClient()

  const [
    { count: photographersCount },
    { count: clientsCount },
    { count: bookingsCount },
    { data: payments },
  ] = await Promise.all([
    supabase.from('photographers').select('*', { count: 'exact', head: true }),
    supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'client'),
    supabase.from('bookings').select('*', { count: 'exact', head: true }),
    supabase.from('payments').select('id,amount,created_at,status,operator').eq('status', 'completed').order('created_at', { ascending: false }).limit(5),
  ])

  const totalRevenue = (payments ?? []).reduce((sum, p) => sum + (p.amount ?? 0), 0)

  // Revenus des 6 derniers mois, calculés depuis les paiements réels
  const sixMonthsAgo = new Date()
  sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6)
  const { data: allPayments } = await supabase
    .from('payments')
    .select('amount,created_at')
    .eq('status', 'completed')
    .gte('created_at', sixMonthsAgo.toISOString())

  const MONTH_LABELS = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc']
  const revenueByMonth: Record<string, number> = {}
    ; (allPayments ?? []).forEach((p) => {
      const month = MONTH_LABELS[new Date(p.created_at).getMonth()]
      revenueByMonth[month] = (revenueByMonth[month] ?? 0) + (p.amount ?? 0)
    })
  const revenueData = Object.entries(revenueByMonth).map(([label, value]) => ({ label, value }))

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold">Tableau de bord</h1>
        <p className="text-muted-foreground">Vue d&apos;ensemble de la plateforme</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="Photographes"
          value={photographersCount ?? 0}
          icon={Camera}
          description="Photographes inscrits"
        />
        <StatsCard
          title="Clients"
          value={clientsCount ?? 0}
          icon={Users}
          description="Clients enregistrés"
        />
        <StatsCard
          title="Réservations"
          value={bookingsCount ?? 0}
          icon={CalendarCheck}
          description="Total des réservations"
        />
        <StatsCard
          title="Revenus (récents)"
          value={`${(totalRevenue / 1000).toFixed(0)}K XOF`}
          icon={CreditCard}
          description="5 derniers paiements"
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Revenus mensuels</CardTitle>
        </CardHeader>
        <CardContent>
          <AnalyticsChart data={revenueData} valueLabel="XOF" />
        </CardContent>
      </Card>

      {payments && payments.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Paiements récents</CardTitle>
          </CardHeader>
          <CardContent>
            <PaymentsTable payments={payments} />
          </CardContent>
        </Card>
      )}
    </div>
  )
}
