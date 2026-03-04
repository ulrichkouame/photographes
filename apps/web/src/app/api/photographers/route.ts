import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  const supabase = await createClient()
  const { searchParams } = new URL(req.url)

  const category = searchParams.get('category')
  const commune = searchParams.get('commune')
  const minRating = searchParams.get('min_rating')
  const available = searchParams.get('available')
  const page = parseInt(searchParams.get('page') ?? '1')
  const limit = parseInt(searchParams.get('limit') ?? '12')
  const search = searchParams.get('search')
  const offset = (page - 1) * limit

  const budgetMin = searchParams.get('budget_min')
  const budgetMax = searchParams.get('budget_max')

  // Utilise la vue photographer_profiles qui agrège profil + note moyenne + compteurs
  let query = supabase
    .from('photographer_profiles')
    .select('*', { count: 'exact' })

  if (search) {
    query = query.or(`full_name.ilike.%${search}%,bio.ilike.%${search}%`)
  }
  if (category) {
    query = query.contains('specialties', [category])
  }
  if (commune) {
    query = query.eq('city', commune)
  }
  if (minRating) {
    query = query.gte('avg_rating', parseFloat(minRating))
  }
  if (available === 'true') {
    query = query.eq('is_available', true)
  }
  if (budgetMin) {
    query = query.gte('price_per_hour', parseFloat(budgetMin))
  }
  if (budgetMax) {
    query = query.lte('price_per_hour', parseFloat(budgetMax))
  }

  query = query.range(offset, offset + limit - 1).order('avg_rating', { ascending: false })

  const { data, error, count } = await query

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ photographers: data ?? [], total: count ?? 0 })
}
