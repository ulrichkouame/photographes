import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Camera, Image, Users, Eye } from "lucide-react";

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  const stats = [
    { title: "Photos uploadées", value: "0", icon: Image, description: "Total de vos photos" },
    { title: "Galeries", value: "0", icon: Camera, description: "Galeries créées" },
    { title: "Clients", value: "0", icon: Users, description: "Clients enregistrés" },
    { title: "Vues ce mois", value: "0", icon: Eye, description: "Visites de votre portfolio" },
  ];

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">
          Bonjour, {user?.user_metadata?.full_name || user?.email} 👋
        </h1>
        <p className="text-muted-foreground mt-1">
          Voici un aperçu de votre activité
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-8">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <CardDescription className="text-xs mt-1">{stat.description}</CardDescription>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Démarrez votre portfolio</CardTitle>
            <CardDescription>
              Suivez ces étapes pour configurer votre présence en ligne
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {[
                "Complétez votre profil photographe",
                "Uploadez vos premières photos",
                "Créez votre première galerie client",
                "Personnalisez votre portfolio public",
              ].map((step, index) => (
                <div key={step} className="flex items-center gap-3 text-sm">
                  <div className="w-6 h-6 rounded-full bg-muted flex items-center justify-center text-xs font-medium">
                    {index + 1}
                  </div>
                  <span className="text-muted-foreground">{step}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Activité récente</CardTitle>
            <CardDescription>Vos dernières actions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <Camera className="h-12 w-12 text-muted-foreground/30 mb-3" />
              <p className="text-sm text-muted-foreground">
                Aucune activité récente. Commencez par uploader des photos !
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
