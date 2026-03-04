import { createClient } from '@/lib/supabase/server'
import { StatsCard } from '@/components/admin/StatsCard'
import { AnalyticsChart } from '@/components/admin/AnalyticsChart'
import { PaymentsTable } from '@/components/admin/PaymentsTable'
import { Camera, Users, CreditCard, CalendarCheck } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default async function AdminDashboardPage() {
  const supabase = await createClient()

  const [
    { count: photographersCount },
    { count: clientsCount },
    { count: bookingsCount },
    { data: payments },
  ] = await Promise.all([
    supabase.from('photographes_photographers').select('*', { count: 'exact', head: true }),
    supabase.from('photographes_clients').select('*', { count: 'exact', head: true }),
    supabase.from('photographes_bookings').select('*', { count: 'exact', head: true }),
    supabase.from('photographes_payments').select('*').eq('status', 'completed').limit(5).order('created_at', { ascending: false }),
  ])

  const totalRevenue = (payments ?? []).reduce((sum, p) => sum + (p.amount ?? 0), 0)

  const revenueData = [
    { label: 'Jan', value: 1200000 },
    { label: 'Fév', value: 1500000 },
    { label: 'Mar', value: 1800000 },
    { label: 'Avr', value: 1400000 },
    { label: 'Mai', value: 2100000 },
    { label: 'Jun', value: 2400000 },
  ]

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
