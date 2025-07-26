// Firebase Firestore tipleri
export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  emailVerified: boolean;
}

export interface Profile {
  id: string;
  first_name: string | null;
  last_name: string | null;
  avatar_url: string | null;
  updated_at: string;
}

export interface Bird {
  id: string;
  user_id: string;
  name: string;
  ring_number: string;
  gender: 'male' | 'female';
  color: string;
  age_months: number;
  breed: string;
  health_status: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface Egg {
  id: string;
  user_id: string;
  bird_id: string;
  incubation_id: string;
  status: 'fertile' | 'infertile' | 'hatched' | 'candling';
  hatch_date: string;
  expected_hatch_date: string;
  actual_hatch_date: string | null;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface Chick {
  id: string;
  user_id: string;
  egg_id: string;
  bird_id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
  color: string;
  health_status: string;
  weight: number;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface Incubation {
  id: string;
  user_id: string;
  start_date: string;
  end_date: string | null;
  temperature: number;
  humidity: number;
  turning_frequency: number;
  notes: string;
  status: 'active' | 'completed' | 'cancelled';
  created_at: string;
  updated_at: string;
}

export interface BreedingPair {
  id: string;
  user_id: string;
  male_bird_id: string;
  female_bird_id: string;
  start_date: string;
  end_date: string | null;
  status: 'active' | 'completed' | 'cancelled';
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface NotificationSettings {
  userId: string;
  eggTurningEnabled: boolean;
  eggTurningInterval: number;
  temperatureAlertsEnabled: boolean;
  temperatureMin: number;
  temperatureMax: number;
  temperatureTolerance: number;
  humidityAlertsEnabled: boolean;
  humidityMin: number;
  humidityMax: number;
  feedingRemindersEnabled: boolean;
  feedingInterval: number;
  doNotDisturbStart: string;
  doNotDisturbEnd: string;
  language: 'tr' | 'en';
  soundEnabled: boolean;
  vibrationEnabled: boolean;
}

// Firestore koleksiyon isimleri
export const COLLECTIONS = {
  USERS: 'users',
  PROFILES: 'profiles',
  BIRDS: 'birds',
  EGGS: 'eggs',
  CHICKS: 'chicks',
  INCUBATIONS: 'incubations',
  BREEDING_PAIRS: 'breeding_pairs',
  NOTIFICATION_SETTINGS: 'notification_settings'
} as const; 