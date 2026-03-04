import Image from 'next/image'
import type { PortfolioItem } from '@/types/database'

interface PortfolioGridProps {
  items: PortfolioItem[]
}

export function PortfolioGrid({ items }: PortfolioGridProps) {
  if (items.length === 0) {
    return (
      <div className="text-center py-10 text-muted-foreground">
        <p>Aucune photo dans le portfolio</p>
      </div>
    )
  }

  const sorted = [...items].sort((a, b) => (b.featured ? 1 : 0) - (a.featured ? 1 : 0))

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      {sorted.map((item) => (
        <div key={item.id} className="relative aspect-square rounded-md overflow-hidden group">
          <Image
            src={item.url}
            alt={item.caption ?? 'Photo'}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
          {item.caption && (
            <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-2">
              <p className="text-white text-sm line-clamp-2">{item.caption}</p>
            </div>
          )}
          {item.featured && (
            <div className="absolute top-1 right-1 bg-yellow-400 text-yellow-900 text-xs px-1.5 py-0.5 rounded">
              ⭐
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
