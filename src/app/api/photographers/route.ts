import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

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

  let query = supabase
    .from('photographes_photographers')
    .select('*', { count: 'exact' })

  if (search) {
    query = query.or(`name.ilike.%${search}%,bio.ilike.%${search}%`)
  }
  if (category) {
    query = query.contains('categories', [category])
  }
  if (commune) {
    query = query.eq('commune', commune)
  }
  if (minRating) {
    query = query.gte('rating', parseFloat(minRating))
  }
  if (available === 'true') {
    query = query.eq('available', true)
  }

  query = query.range(offset, offset + limit - 1).order('featured', { ascending: false }).order('rating', { ascending: false })

  const { data, error, count } = await query

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ photographers: data ?? [], total: count ?? 0 })
}
