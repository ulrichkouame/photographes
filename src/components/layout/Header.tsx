import Link from 'next/link'
import { Camera } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2 font-bold text-lg">
          <Camera className="h-6 w-6 text-primary" />
          <span>Photographes.ci</span>
        </Link>
        <nav className="hidden md:flex items-center gap-6 text-sm">
          <Link href="/photographers" className="text-muted-foreground hover:text-foreground transition-colors">
            Trouver un photographe
          </Link>
          <Link href="/auth/login" className="text-muted-foreground hover:text-foreground transition-colors">
            Connexion
          </Link>
          <Button asChild size="sm">
            <Link href="/auth/register">Inscription</Link>
          </Button>
        </nav>
      </div>
    </header>
  )
}
