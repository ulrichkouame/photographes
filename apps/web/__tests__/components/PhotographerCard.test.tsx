import { render, screen } from '@testing-library/react'
import { PhotographerCard } from '@/components/photographers/PhotographerCard'
import type { Photographer } from '@/types/database'

const mockPhotographer: Photographer = {
  id: 'test-id-1',
  user_id: 'user-id-1',
  name: 'Kouamé Diallo',
  bio: 'Photographe professionnel spécialisé en mariages',
  commune: 'Cocody',
  categories: ['Mariage', 'Portrait'],
  rating: 4.5,
  available: true,
  subscription_plan: 'premium',
  featured: false,
  cover_url: null,
  portfolio_urls: [],
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
}

describe('PhotographerCard', () => {
  it('renders photographer name', () => {
    render(<PhotographerCard photographer={mockPhotographer} />)
    expect(screen.getByText('Kouamé Diallo')).toBeInTheDocument()
  })

  it('shows available badge when photographer is available', () => {
    render(<PhotographerCard photographer={mockPhotographer} />)
    expect(screen.getByText('Disponible')).toBeInTheDocument()
  })

  it('shows unavailable badge when photographer is not available', () => {
    const unavailable = { ...mockPhotographer, available: false }
    render(<PhotographerCard photographer={unavailable} />)
    expect(screen.getByText('Indisponible')).toBeInTheDocument()
  })

  it('shows rating', () => {
    render(<PhotographerCard photographer={mockPhotographer} />)
    expect(screen.getByText('4.5')).toBeInTheDocument()
  })

  it('shows categories as badges', () => {
    render(<PhotographerCard photographer={mockPhotographer} />)
    expect(screen.getByText('Mariage')).toBeInTheDocument()
    expect(screen.getByText('Portrait')).toBeInTheDocument()
  })

  it('shows commune', () => {
    render(<PhotographerCard photographer={mockPhotographer} />)
    expect(screen.getByText('Cocody')).toBeInTheDocument()
  })
})
