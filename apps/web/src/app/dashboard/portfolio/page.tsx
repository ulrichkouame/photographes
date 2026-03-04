"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Upload, Image as ImageIcon } from "lucide-react";
import { toast } from "sonner";

export default function PortfolioPage() {
  const [isUploading, setIsUploading] = useState(false);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setIsUploading(true);
    try {
      // Upload logic will be implemented with R2
      toast.success(`${files.length} photo(s) uploadée(s) avec succès`);
    } catch {
      toast.error("Erreur lors de l'upload");
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Mon Portfolio</h1>
        <p className="text-muted-foreground mt-1">
          Gérez vos photos et organisez votre portfolio
        </p>
      </div>

      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Uploader des photos</CardTitle>
            <CardDescription>
              Ajoutez des photos à votre portfolio. Formats acceptés: JPG, PNG, WebP (max 20MB par photo)
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="border-2 border-dashed rounded-lg p-8 text-center">
              <ImageIcon className="h-12 w-12 text-muted-foreground/30 mx-auto mb-4" />
              <p className="text-sm text-muted-foreground mb-4">
                Glissez vos photos ici ou cliquez pour sélectionner
              </p>
              <Label htmlFor="photo-upload" className="cursor-pointer">
                <Button variant="secondary" disabled={isUploading} asChild>
                  <span>
                    <Upload className="h-4 w-4 mr-2" />
                    {isUploading ? "Upload en cours..." : "Sélectionner des photos"}
                  </span>
                </Button>
              </Label>
              <Input
                id="photo-upload"
                type="file"
                accept="image/*"
                multiple
                className="hidden"
                onChange={handleUpload}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Vos photos</CardTitle>
            <CardDescription>0 photos dans votre portfolio</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <ImageIcon className="h-16 w-16 text-muted-foreground/20 mb-4" />
              <p className="text-muted-foreground">
                Votre portfolio est vide. Commencez par uploader vos premières photos !
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
