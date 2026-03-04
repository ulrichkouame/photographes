'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard, Users, Camera, CreditCard, Settings, BarChart2, ShieldCheck, Menu
} from 'lucide-react'
import { cn } from '@/lib/utils'

const links = [
  { href: '/admin', label: 'Tableau de bord', icon: LayoutDashboard },
  { href: '/admin/photographers', label: 'Photographes', icon: Camera },
  { href: '/admin/clients', label: 'Clients', icon: Users },
  { href: '/admin/payments', label: 'Paiements', icon: CreditCard },
  { href: '/admin/analytics', label: 'Analytiques', icon: BarChart2 },
  { href: '/admin/moderation', label: 'Modération', icon: ShieldCheck },
  { href: '/admin/settings', label: 'Paramètres', icon: Settings },
]

export function AdminSidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-64 min-h-screen border-r bg-muted/30 flex flex-col">
      <div className="p-6 border-b">
        <Link href="/admin" className="font-bold text-lg flex items-center gap-2">
          <Camera className="h-5 w-5 text-primary" />
          Admin
        </Link>
      </div>
      <nav className="flex-1 p-4 space-y-1">
        {links.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              'flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors',
              pathname === href
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground'
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </Link>
        ))}
      </nav>
    </aside>
  )
}
