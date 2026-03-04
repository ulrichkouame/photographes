# Schéma de base de données

Toutes les tables sont préfixées par `photographes_`.

## photographes_users
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| email | text | Email unique |
| role | text | 'admin', 'photographer', 'client' |
| created_at | timestamptz | Date de création |

## photographes_photographers
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| user_id | uuid | Référence users.id |
| name | text | Nom complet |
| bio | text | Biographie |
| commune | text | Commune d'exercice |
| categories | text[] | Spécialités |
| rating | numeric | Note moyenne (0-5) |
| available | boolean | Disponibilité |
| subscription_plan | text | 'free', 'basic', 'premium' |
| featured | boolean | Mis en vedette |
| cover_url | text | URL photo de couverture |
| portfolio_urls | text[] | URLs des photos portfolio |
| created_at | timestamptz | Date de création |
| updated_at | timestamptz | Dernière mise à jour |

## photographes_clients
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| user_id | uuid | Référence users.id |
| name | text | Nom complet |
| email | text | Email |
| created_at | timestamptz | Date de création |

## photographes_bookings
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| photographer_id | uuid | Référence photographers.id |
| client_id | uuid | Référence clients.id |
| date | timestamptz | Date de la séance |
| status | text | 'pending', 'confirmed', 'cancelled', 'completed' |
| amount | numeric | Montant en XOF |
| created_at | timestamptz | Date de création |

## photographes_payments
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| booking_id | uuid | Référence bookings.id |
| provider | text | Prestataire de paiement |
| amount | numeric | Montant en XOF |
| status | text | 'pending', 'completed', 'failed', 'refunded' |
| created_at | timestamptz | Date de création |

## photographes_portfolio
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| photographer_id | uuid | Référence photographers.id |
| url | text | URL de l'image |
| caption | text | Légende |
| featured | boolean | Photo mise en avant |
| created_at | timestamptz | Date de création |

## photographes_app_settings
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| key | text | Clé unique du paramètre |
| value | text | Valeur |
| updated_at | timestamptz | Dernière mise à jour |

## photographes_categories
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| name | text | Nom de la catégorie |
| slug | text | Slug URL |

## photographes_communes
| Colonne | Type | Description |
|---------|------|-------------|
| id | uuid | Clé primaire |
| name | text | Nom de la commune |
| slug | text | Slug URL |
