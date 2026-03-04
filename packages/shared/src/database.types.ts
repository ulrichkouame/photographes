// ─────────────────────────────────────────────────────────────────────────────
// Types de base de données Supabase — Photographes.ci
// Format compatible avec le client Supabase TypeScript généré.
// ─────────────────────────────────────────────────────────────────────────────

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          avatar_url: string | null;
          role: 'client' | 'photographer' | 'admin';
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          avatar_url?: string | null;
          role?: 'client' | 'photographer' | 'admin';
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          full_name?: string | null;
          avatar_url?: string | null;
          role?: 'client' | 'photographer' | 'admin';
          updated_at?: string;
        };
      };
      photographers: {
        Row: {
          id: string;
          profile_id: string;
          bio: string | null;
          city: string | null;
          specialties: string[] | null;
          price_per_hour: number | null;
          is_available: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          profile_id: string;
          bio?: string | null;
          city?: string | null;
          specialties?: string[] | null;
          price_per_hour?: number | null;
          is_available?: boolean;
          created_at?: string;
        };
        Update: {
          bio?: string | null;
          city?: string | null;
          specialties?: string[] | null;
          price_per_hour?: number | null;
          is_available?: boolean;
        };
      };
      bookings: {
        Row: {
          id: string;
          client_id: string | null;
          photographer_id: string | null;
          event_date: string;
          duration_hours: number;
          service_type: string | null;
          location: string | null;
          message: string | null;
          status: string;
          total_price: number | null;
          contact_cost: number;
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          client_id?: string | null;
          photographer_id?: string | null;
          event_date: string;
          duration_hours: number;
          service_type?: string | null;
          location?: string | null;
          message?: string | null;
          status?: string;
          total_price?: number | null;
          contact_cost?: number;
          notes?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          status?: string;
          total_price?: number | null;
          notes?: string | null;
          updated_at?: string;
        };
      };
      portfolio_photos: {
        Row: {
          id: string;
          photographer_id: string;
          url: string;
          caption: string | null;
          category: string | null;
          is_cover: boolean;
          sort_order: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          photographer_id: string;
          url: string;
          caption?: string | null;
          category?: string | null;
          is_cover?: boolean;
          sort_order?: number;
          created_at?: string;
        };
        Update: {
          caption?: string | null;
          category?: string | null;
          is_cover?: boolean;
          sort_order?: number;
        };
      };
      reviews: {
        Row: {
          id: string;
          booking_id: string;
          client_id: string;
          photographer_id: string;
          rating: number;
          comment: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          booking_id: string;
          client_id: string;
          photographer_id: string;
          rating: number;
          comment?: string | null;
          created_at?: string;
        };
        Update: {
          rating?: number;
          comment?: string | null;
        };
      };
      chat_rooms: {
        Row: {
          id: string;
          booking_id: string | null;
          client_id: string;
          photographer_id: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          booking_id?: string | null;
          client_id: string;
          photographer_id: string;
          created_at?: string;
        };
        Update: Record<string, never>;
      };
      messages: {
        Row: {
          id: string;
          room_id: string;
          sender_id: string;
          content: string;
          is_read: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          room_id: string;
          sender_id: string;
          content: string;
          is_read?: boolean;
          created_at?: string;
        };
        Update: {
          is_read?: boolean;
        };
      };
      payments: {
        Row: {
          id: string;
          booking_id: string | null;
          client_id: string | null;
          amount: number;
          currency: string;
          operator: string;
          phone_number: string | null;
          status: string;
          transaction_id: string | null;
          provider_ref: string | null;
          metadata: Json | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          booking_id?: string | null;
          client_id?: string | null;
          amount: number;
          currency?: string;
          operator: string;
          phone_number?: string | null;
          status?: string;
          transaction_id?: string | null;
          provider_ref?: string | null;
          metadata?: Json | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          status?: string;
          transaction_id?: string | null;
          provider_ref?: string | null;
          metadata?: Json | null;
          updated_at?: string;
        };
      };
      services: {
        Row: {
          id: string;
          photographer_id: string;
          name: string;
          description: string | null;
          price: number;
          duration_hours: number | null;
          is_active: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          photographer_id: string;
          name: string;
          description?: string | null;
          price: number;
          duration_hours?: number | null;
          is_active?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          name?: string;
          description?: string | null;
          price?: number;
          duration_hours?: number | null;
          is_active?: boolean;
          updated_at?: string;
        };
      };
      subscriptions: {
        Row: {
          id: string;
          photographer_id: string;
          plan: string;
          status: string;
          started_at: string;
          expires_at: string | null;
          monthly_price: number;
          features: Json;
          payment_id: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          photographer_id: string;
          plan?: string;
          status?: string;
          started_at?: string;
          expires_at?: string | null;
          monthly_price?: number;
          features?: Json;
          payment_id?: string | null;
          created_at?: string;
        };
        Update: {
          plan?: string;
          status?: string;
          expires_at?: string | null;
          monthly_price?: number;
          features?: Json;
        };
      };
      notifications: {
        Row: {
          id: string;
          user_id: string;
          type: string;
          title: string;
          body: string | null;
          data: Json | null;
          is_read: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          type: string;
          title: string;
          body?: string | null;
          data?: Json | null;
          is_read?: boolean;
          created_at?: string;
        };
        Update: {
          is_read?: boolean;
        };
      };
      app_settings: {
        Row: {
          user_id: string;
          language: string;
          dark_mode: boolean;
          notifications_push: boolean;
          notifications_email: boolean;
          notifications_sms: boolean;
          currency: string;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          language?: string;
          dark_mode?: boolean;
          notifications_push?: boolean;
          notifications_email?: boolean;
          notifications_sms?: boolean;
          currency?: string;
          updated_at?: string;
        };
        Update: {
          language?: string;
          dark_mode?: boolean;
          notifications_push?: boolean;
          notifications_email?: boolean;
          notifications_sms?: boolean;
          currency?: string;
          updated_at?: string;
        };
      };
      availability: {
        Row: {
          id: string;
          photographer_id: string;
          date: string;
          is_available: boolean;
          slots_remaining: number;
          note: string | null;
        };
        Insert: {
          id?: string;
          photographer_id: string;
          date: string;
          is_available?: boolean;
          slots_remaining?: number;
          note?: string | null;
        };
        Update: {
          is_available?: boolean;
          slots_remaining?: number;
          note?: string | null;
        };
      };
    };
    Views: {
      photographer_profiles: {
        Row: {
          id: string;
          profile_id: string;
          full_name: string | null;
          avatar_url: string | null;
          bio: string | null;
          city: string | null;
          specialties: string[] | null;
          price_per_hour: number | null;
          is_available: boolean;
          average_rating: number;
          review_count: number;
          portfolio_count: number;
          created_at: string;
        };
      };
    };
    Functions: Record<string, never>;
    Enums: Record<string, never>;
  };
};

/** Helper pour extraire le type d'une ligne de table. */
export type TableRow<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];
