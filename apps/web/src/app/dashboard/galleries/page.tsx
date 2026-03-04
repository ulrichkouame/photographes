import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Camera, Plus } from "lucide-react";

export default function GalleriesPage() {
  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Mes Galeries</h1>
          <p className="text-muted-foreground mt-1">
            Créez et gérez des galeries privées pour vos clients
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Nouvelle galerie
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Galeries clients</CardTitle>
          <CardDescription>0 galeries créées</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <Camera className="h-16 w-16 text-muted-foreground/20 mb-4" />
            <p className="text-muted-foreground mb-4">
              Aucune galerie créée. Créez une galerie pour partager des photos avec vos clients !
            </p>
            <Button variant="outline">
              <Plus className="h-4 w-4 mr-2" />
              Créer une galerie
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
