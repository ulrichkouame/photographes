import { Footer } from '@/components/layout/Footer'
import { Header } from '@/components/layout/Header'
import { PortfolioGrid } from '@/components/photographers/PortfolioGrid'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/server'
import { MapPin, Star } from 'lucide-react'
import Image from 'next/image'
import { notFound } from 'next/navigation'

interface Props {
  params: Promise<{ slug: string }>
}

export default async function PhotographerProfilePage({ params }: Props) {
  const { slug } = await params
  const supabase = await createClient()

  // Recherche par id OU par slug (nom converti en slug)
  const { data: photographer } = await supabase
    .from('photographer_profiles')
    .select('*')
    .or(`id.eq.${slug},full_name.ilike.${slug.replace(/-/g, ' ')}`)
    .single()

  if (!photographer) notFound()

  const { data: portfolio } = await supabase
    .from('portfolio_photos')
    .select('*')
    .eq('photographer_id', photographer.id)
    .order('sort_order', { ascending: true })

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1">
        {/* Cover */}
        <div className="relative h-64 md:h-80 bg-muted">
          {photographer.cover_url ? (
            <Image
              src={photographer.cover_url}
              alt={photographer.name}
              fill
              className="object-cover"
              priority
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
              <span className="text-8xl">📷</span>
            </div>
          )}
        </div>

        <div className="container mx-auto px-4 py-8 max-w-4xl">
          {/* Info */}
          <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-8">
            <div>
              <h1 className="text-3xl font-bold mb-2">{photographer.full_name ?? 'Photographe'}</h1>
              <div className="flex flex-wrap items-center gap-3 mb-3">
                {photographer.city && (
                  <span className="text-muted-foreground flex items-center gap-1 text-sm">
                    <MapPin className="h-4 w-4" />
                    {photographer.city}
                  </span>
                )}
                <span className="flex items-center gap-1 text-sm font-medium">
                  <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                  {(photographer.avg_rating ?? 0).toFixed(1)}
                </span>
                {photographer.is_available ? (
                  <Badge variant="success">Disponible</Badge>
                ) : (
                  <Badge variant="secondary">Indisponible</Badge>
                )}
              </div>
              <div className="flex flex-wrap gap-2">
                {photographer.specialties?.map((cat: string) => (
                  <Badge key={cat} variant="outline">{cat}</Badge>
                ))}
              </div>
            </div>
            <Button size="lg" disabled={!photographer.available}>
              {photographer.is_available ? 'Réserver maintenant' : 'Indisponible'}
            </Button>
          </div>

          {/* Bio */}
          {photographer.bio && (
            <div className="mb-8">
              <h2 className="text-xl font-semibold mb-3">À propos</h2>
              <p className="text-muted-foreground leading-relaxed">{photographer.bio}</p>
            </div>
          )}

          {/* Portfolio */}
          <div>
            <h2 className="text-xl font-semibold mb-4">Portfolio</h2>
            <PortfolioGrid items={portfolio ?? []} />
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
