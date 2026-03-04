import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Camera, Star, Users, Image, ArrowRight, CheckCircle } from "lucide-react";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Camera className="h-6 w-6" />
            <span className="font-bold text-lg">Photographes.ci</span>
          </div>
          <div className="hidden md:flex items-center gap-6">
            <Link href="#features" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Fonctionnalités
            </Link>
            <Link href="#pricing" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Tarifs
            </Link>
            <Link href="#testimonials" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Témoignages
            </Link>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="ghost" asChild>
              <Link href="/auth/login">Connexion</Link>
            </Button>
            <Button asChild>
              <Link href="/auth/register">Commencer gratuitement</Link>
            </Button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto text-center max-w-4xl">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Star className="h-4 w-4" />
            La plateforme #1 pour les photographes ivoiriens
          </div>
          <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6">
            Développez votre activité de{" "}
            <span className="text-primary">photographie professionnelle</span>
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Gérez votre portfolio, vos clients, vos réservations et votre facturation en un seul endroit.
            Conçu spécialement pour les photographes en Côte d&apos;Ivoire.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" asChild>
              <Link href="/auth/register">
                Créer mon compte gratuit
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
            <Button size="lg" variant="outline" asChild>
              <Link href="/portfolio/demo">Voir une démo</Link>
            </Button>
          </div>
          <p className="text-sm text-muted-foreground mt-4">
            Aucune carte de crédit requise • 14 jours d&apos;essai gratuit
          </p>
        </div>
      </section>

      {/* Stats */}
      <section className="py-12 bg-muted/50">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            {[
              { value: "500+", label: "Photographes actifs" },
              { value: "10K+", label: "Photos partagées" },
              { value: "2K+", label: "Clients satisfaits" },
              { value: "98%", label: "Taux de satisfaction" },
            ].map((stat) => (
              <div key={stat.label}>
                <div className="text-3xl font-bold">{stat.value}</div>
                <div className="text-sm text-muted-foreground mt-1">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20 px-4">
        <div className="container mx-auto max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">Tout ce dont vous avez besoin</h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Une suite complète d&apos;outils pour gérer votre activité photographique du début à la fin.
            </p>
          </div>
          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: Image,
                title: "Portfolio professionnel",
                description: "Créez un portfolio en ligne élégant pour présenter vos meilleures œuvres à vos clients potentiels.",
              },
              {
                icon: Users,
                title: "Gestion des clients",
                description: "Gérez vos contacts clients, suivez les projets et maintenez l'historique de vos collaborations.",
              },
              {
                icon: Camera,
                title: "Galeries privées",
                description: "Partagez vos photos avec vos clients via des galeries sécurisées avec protection par mot de passe.",
              },
            ].map((feature) => (
              <div key={feature.title} className="p-6 rounded-xl border bg-card">
                <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                  <feature.icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="font-semibold text-lg mb-2">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="py-20 px-4 bg-muted/50">
        <div className="container mx-auto max-w-5xl">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">Tarifs simples et transparents</h2>
            <p className="text-muted-foreground">Choisissez le plan qui correspond à votre activité.</p>
          </div>
          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                name: "Starter",
                price: "Gratuit",
                description: "Pour débuter",
                features: ["5 GB de stockage", "1 portfolio", "10 galeries clients", "Support email"],
                cta: "Commencer gratuitement",
                featured: false,
              },
              {
                name: "Pro",
                price: "15 000 FCFA/mois",
                description: "Pour les professionnels",
                features: ["50 GB de stockage", "Portfolios illimités", "Galeries illimitées", "Domaine personnalisé", "Analytics avancés", "Support prioritaire"],
                cta: "Essayer 14 jours gratuit",
                featured: true,
              },
              {
                name: "Studio",
                price: "35 000 FCFA/mois",
                description: "Pour les studios",
                features: ["200 GB de stockage", "Multi-utilisateurs", "API access", "Intégrations CRM", "Support dédié", "Formation incluse"],
                cta: "Contacter les ventes",
                featured: false,
              },
            ].map((plan) => (
              <div
                key={plan.name}
                className={`p-8 rounded-xl border ${plan.featured ? "bg-primary text-primary-foreground border-primary shadow-lg scale-105" : "bg-card"}`}
              >
                <h3 className="font-bold text-xl mb-1">{plan.name}</h3>
                <p className={`text-sm mb-4 ${plan.featured ? "text-primary-foreground/70" : "text-muted-foreground"}`}>
                  {plan.description}
                </p>
                <div className="text-2xl font-bold mb-6">{plan.price}</div>
                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-center gap-2 text-sm">
                      <CheckCircle className="h-4 w-4 flex-shrink-0" />
                      {feature}
                    </li>
                  ))}
                </ul>
                <Button
                  className="w-full"
                  variant={plan.featured ? "secondary" : "default"}
                  asChild
                >
                  <Link href="/auth/register">{plan.cta}</Link>
                </Button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-12 px-4">
        <div className="container mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <Camera className="h-5 w-5" />
              <span className="font-semibold">Photographes.ci</span>
            </div>
            <p className="text-sm text-muted-foreground">
              © 2024 Photographes.ci. Tous droits réservés.
            </p>
            <div className="flex gap-4 text-sm text-muted-foreground">
              <Link href="/legal/privacy" className="hover:text-foreground">Confidentialité</Link>
              <Link href="/legal/terms" className="hover:text-foreground">CGU</Link>
              <Link href="/contact" className="hover:text-foreground">Contact</Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
