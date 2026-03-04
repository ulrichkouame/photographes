'use client'

import { AnalyticsChart } from '@/components/admin/AnalyticsChart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts'

const revenueData = [
  { label: 'Jan', value: 1200000 },
  { label: 'Fév', value: 1500000 },
  { label: 'Mar', value: 1800000 },
  { label: 'Avr', value: 1400000 },
  { label: 'Mai', value: 2100000 },
  { label: 'Jun', value: 2400000 },
  { label: 'Jul', value: 2200000 },
  { label: 'Aoû', value: 2600000 },
]

const bookingsByStatus = [
  { name: 'En attente', value: 35, color: '#f59e0b' },
  { name: 'Confirmé', value: 45, color: '#10b981' },
  { name: 'Annulé', value: 12, color: '#ef4444' },
  { name: 'Terminé', value: 88, color: '#6366f1' },
]

const topPhotographers = [
  { name: 'Kouamé Studio', bookings: 28 },
  { name: 'Aya Photo', bookings: 24 },
  { name: 'Lumière CI', bookings: 19 },
  { name: 'Capture Moment', bookings: 15 },
  { name: 'Djeneba Photos', bookings: 12 },
]

export default function AdminAnalyticsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Analytiques</h1>
        <p className="text-muted-foreground">Indicateurs de performance de la plateforme</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Revenus mensuels (XOF)</CardTitle>
        </CardHeader>
        <CardContent>
          <AnalyticsChart data={revenueData} valueLabel="XOF" />
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Réservations par statut</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={bookingsByStatus}
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {bookingsByStatus.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top photographes</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={topPhotographers} layout="vertical" margin={{ left: 20 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis dataKey="name" type="category" width={100} tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="bookings" fill="#6366f1" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
