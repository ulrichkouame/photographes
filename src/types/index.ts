export interface User {
  id: string;
  email: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  location?: string;
  website?: string;
  slug?: string;
  created_at: string;
  updated_at: string;
}

export interface Photo {
  id: string;
  user_id: string;
  title?: string;
  description?: string;
  url: string;
  key: string;
  size: number;
  width?: number;
  height?: number;
  tags?: string[];
  is_featured: boolean;
  created_at: string;
  updated_at: string;
}

export interface Gallery {
  id: string;
  user_id: string;
  client_id?: string;
  title: string;
  description?: string;
  slug: string;
  cover_photo_id?: string;
  is_private: boolean;
  password?: string;
  expires_at?: string;
  created_at: string;
  updated_at: string;
  photos?: Photo[];
}

export interface Client {
  id: string;
  user_id: string;
  name: string;
  email?: string;
  phone?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}
