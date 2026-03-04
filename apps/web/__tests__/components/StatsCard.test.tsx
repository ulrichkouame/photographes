import { render, screen } from '@testing-library/react'
import { StatsCard } from '@/components/admin/StatsCard'
import { Users } from 'lucide-react'

describe('StatsCard', () => {
  it('renders title and value', () => {
    render(<StatsCard title="Total clients" value={42} icon={Users} />)
    expect(screen.getByText('Total clients')).toBeInTheDocument()
    expect(screen.getByText('42')).toBeInTheDocument()
  })

  it('renders icon', () => {
    const { container } = render(<StatsCard title="Test" value="100" icon={Users} />)
    expect(container.querySelector('svg')).toBeInTheDocument()
  })

  it('renders description when provided', () => {
    render(<StatsCard title="Test" value={10} icon={Users} description="Clients inscrits" />)
    expect(screen.getByText('Clients inscrits')).toBeInTheDocument()
  })

  it('renders positive trend', () => {
    render(<StatsCard title="Test" value={10} icon={Users} trend={{ value: 12, label: 'ce mois' }} />)
    expect(screen.getByText('+12% ce mois')).toBeInTheDocument()
  })
})
