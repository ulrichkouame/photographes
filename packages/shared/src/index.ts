// Types partagés entre les applications web et mobile (via codegen)

export type UserRole = 'client' | 'photographer' | 'admin';

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed';

export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  role: UserRole;
  created_at: string;
  updated_at: string;
}

export interface Photographer {
  id: string;
  profile_id: string;
  bio: string | null;
  city: string | null;
  specialties: string[] | null;
  price_per_hour: number | null;
  is_available: boolean;
  created_at: string;
}

export interface Booking {
  id: string;
  client_id: string | null;
  photographer_id: string | null;
  event_date: string;
  duration_hours: number;
  status: BookingStatus;
  total_price: number | null;
  notes: string | null;
  created_at: string;
}
