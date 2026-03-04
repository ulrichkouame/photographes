export interface Photographer {
  id: string
  user_id: string
  name: string
  bio: string | null
  commune: string | null
  categories: string[]
  rating: number
  available: boolean
  subscription_plan: 'free' | 'basic' | 'premium'
  featured: boolean
  cover_url: string | null
  portfolio_urls: string[]
  created_at: string
  updated_at: string
}

export interface PortfolioItem {
  id: string
  photographer_id: string
  url: string
  caption: string | null
  featured: boolean
  created_at: string
}

export interface AppSetting {
  id: string
  key: string
  value: string
  updated_at: string
}

export interface PaymentProvider {
  id: string
  name: string
  enabled: boolean
  config_json: Record<string, unknown>
  created_at: string
}

export interface Booking {
  id: string
  photographer_id: string
  client_id: string
  date: string
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed'
  amount: number
  created_at: string
}

export interface Payment {
  id: string
  booking_id: string
  provider: string
  amount: number
  status: 'pending' | 'completed' | 'failed' | 'refunded'
  created_at: string
}

export interface Category {
  id: string
  name: string
  slug: string
}

export interface Commune {
  id: string
  name: string
  slug: string
}

export interface Client {
  id: string
  user_id: string
  name: string
  email: string
  created_at: string
}

export interface User {
  id: string
  email: string
  role: 'admin' | 'photographer' | 'client'
  created_at: string
}
