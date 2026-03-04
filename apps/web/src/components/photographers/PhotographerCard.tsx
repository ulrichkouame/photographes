import Image from 'next/image'
import Link from 'next/link'
import { MapPin, Star } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import type { Photographer } from '@/types/database'

interface PhotographerCardProps {
  photographer: Photographer
}

const planLabels: Record<string, string> = {
  free: 'Gratuit',
  basic: 'Basic',
  premium: 'Premium',
}

export function PhotographerCard({ photographer }: PhotographerCardProps) {
  const slug = photographer.id
  return (
    <Card className="overflow-hidden hover:shadow-lg transition-shadow group">
      <div className="relative h-48 bg-muted">
        {photographer.cover_url ? (
          <Image
            src={photographer.cover_url}
            alt={photographer.name}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary/20 to-primary/5">
            <span className="text-4xl">📷</span>
          </div>
        )}
        <div className="absolute top-2 right-2 flex gap-1">
          {photographer.featured && (
            <Badge variant="default" className="text-xs">En vedette</Badge>
          )}
          {photographer.available ? (
            <Badge variant="success" className="text-xs">Disponible</Badge>
          ) : (
            <Badge variant="secondary" className="text-xs">Indisponible</Badge>
          )}
        </div>
      </div>
      <CardContent className="p-4">
        <div className="flex items-start justify-between mb-2">
          <div>
            <h3 className="font-semibold text-base line-clamp-1">{photographer.name}</h3>
            {photographer.commune && (
              <p className="text-muted-foreground text-sm flex items-center gap-1 mt-0.5">
                <MapPin className="h-3 w-3" />
                {photographer.commune}
              </p>
            )}
          </div>
          <div className="flex items-center gap-1 text-sm font-medium">
            <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
            <span>{photographer.rating.toFixed(1)}</span>
          </div>
        </div>
        {photographer.bio && (
          <p className="text-muted-foreground text-sm line-clamp-2 mb-3">{photographer.bio}</p>
        )}
        <div className="flex flex-wrap gap-1 mb-3">
          {photographer.categories.slice(0, 3).map((cat) => (
            <Badge key={cat} variant="outline" className="text-xs">{cat}</Badge>
          ))}
        </div>
        <div className="flex items-center justify-between">
          <Badge variant="secondary" className="text-xs">{planLabels[photographer.subscription_plan]}</Badge>
          <Link
            href={`/photographers/${slug}`}
            className="text-primary text-sm font-medium hover:underline"
          >
            Voir le profil →
          </Link>
        </div>
      </CardContent>
    </Card>
  )
}
