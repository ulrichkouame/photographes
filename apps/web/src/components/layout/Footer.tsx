import Link from 'next/link'
import { Camera } from 'lucide-react'

export function Footer() {
  return (
    <footer className="border-t bg-muted/50">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="md:col-span-2">
            <Link href="/" className="flex items-center gap-2 font-bold text-lg mb-4">
              <Camera className="h-6 w-6 text-primary" />
              <span>Photographes.ci</span>
            </Link>
            <p className="text-muted-foreground text-sm max-w-xs">
              La plateforme de référence pour les photographes professionnels en Côte d&apos;Ivoire.
            </p>
          </div>
          <div>
            <h3 className="font-semibold mb-4">Navigation</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              <li><Link href="/photographers" className="hover:text-foreground">Photographes</Link></li>
              <li><Link href="/auth/login" className="hover:text-foreground">Connexion</Link></li>
              <li><Link href="/auth/register" className="hover:text-foreground">Inscription</Link></li>
            </ul>
          </div>
          <div>
            <h3 className="font-semibold mb-4">Contact</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              <li>contact@photographes.ci</li>
              <li>Abidjan, Côte d&apos;Ivoire</li>
            </ul>
          </div>
        </div>
        <div className="border-t mt-8 pt-8 text-center text-sm text-muted-foreground">
          © {new Date().getFullYear()} Photographes.ci — Tous droits réservés
        </div>
      </div>
    </footer>
  )
}
