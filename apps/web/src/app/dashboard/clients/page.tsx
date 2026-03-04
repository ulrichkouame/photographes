import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Plus } from "lucide-react";

export default function ClientsPage() {
  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Mes Clients</h1>
          <p className="text-muted-foreground mt-1">
            Gérez vos clients et leurs galeries photos
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Nouveau client
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Liste des clients</CardTitle>
          <CardDescription>0 clients enregistrés</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <Users className="h-16 w-16 text-muted-foreground/20 mb-4" />
            <p className="text-muted-foreground mb-4">
              Vous n&apos;avez pas encore de clients. Ajoutez votre premier client !
            </p>
            <Button variant="outline">
              <Plus className="h-4 w-4 mr-2" />
              Ajouter un client
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
