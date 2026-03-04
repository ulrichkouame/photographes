import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Photographes.ci',
  description: 'Trouvez le photographe idéal pour vos événements en Côte d\'Ivoire.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
