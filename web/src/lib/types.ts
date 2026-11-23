// Formes des réponses de l'API /api/v1 utilisées par le site.
// À remplacer par des types générés depuis docs/openapi.json (tâche 7.0).

export interface CareCategory {
  slug: string;
  name: string;
  icon: string | null;
  services_count: number;
}

export interface CareService {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  duration_minutes: number;
  price: { amount: number; currency: string };
  requires_prescription: boolean;
  allows_series: boolean;
  category: { slug: string; name: string };
  professional_category: string | null;
  /** `home` : à domicile ; `remote` : téléconsultation, réservable dans l'application seulement. */
  delivery_mode: 'home' | 'remote';
}

export interface AppUser {
  id: string;
  name: string | null;
  phone: string;
  locale: string | null;
}

export interface PatientProfile {
  id: string;
  first_name: string;
  last_name: string;
  relationship: 'self' | 'parent' | 'child' | 'spouse' | 'other';
}

export interface PatientAddress {
  id: string;
  label: string;
  line: string;
  city: string | null;
  is_covered: boolean;
}

export interface BookingDay {
  slots: string[];
  immediate_available: boolean;
}

export interface PriceQuote {
  base: number;
  surcharges: { label: string; amount: number }[];
  total: number;
}

export interface Booking {
  id: string;
  reference: string;
  status: string;
  scheduled_date: string;
  scheduled_time: string;
}

/** Format d'erreur unique de l'API. */
export interface ApiError {
  code: string;
  message: string;
  status: number;
  errors?: Record<string, string[]>;
  retry_after?: number;
}

/** Majoration annoncée par l'API : soir ou nuit, jour férié. */
export interface Surcharge {
  type: 'night' | 'holiday';
  name: string;
  mode: 'fixed' | 'percent';
  /** Centimes de dirham si `fixed`, pourcentage si `percent`. */
  value: number;
  starts_at: string | null;
  ends_at: string | null;
}
