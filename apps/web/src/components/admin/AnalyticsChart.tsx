'use client'

import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts'

interface DataPoint {
  label: string
  value: number
}

interface AnalyticsChartProps {
  data: DataPoint[]
  title?: string
  color?: string
  valueLabel?: string
}

export function AnalyticsChart({
  data,
  title,
  color = '#6366f1',
  valueLabel = 'Valeur',
}: AnalyticsChartProps) {
  return (
    <div className="w-full">
      {title && <h3 className="text-sm font-medium mb-4">{title}</h3>}
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
          <XAxis
            dataKey="label"
            className="text-xs"
            tick={{ fontSize: 12 }}
          />
          <YAxis className="text-xs" tick={{ fontSize: 12 }} />
          <Tooltip
            contentStyle={{
              backgroundColor: 'hsl(var(--background))',
              border: '1px solid hsl(var(--border))',
              borderRadius: '8px',
            }}
            formatter={(value: number) => [value, valueLabel]}
          />
          <Line
            type="monotone"
            dataKey="value"
            stroke={color}
            strokeWidth={2}
            dot={{ r: 4 }}
            activeDot={{ r: 6 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}
