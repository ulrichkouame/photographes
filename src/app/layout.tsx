import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "sonner";

export const metadata: Metadata = {
  title: "Photographes.ci - Plateforme pour photographes professionnels",
  description:
    "La plateforme de référence pour les photographes professionnels en Côte d'Ivoire. Gérez votre portfolio, vos clients et développez votre activité.",
  keywords: "photographe, Côte d'Ivoire, portfolio, photographie professionnelle",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr" suppressHydrationWarning>
      <body className="font-sans antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  );
}
