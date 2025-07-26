export interface SubscriptionPlan {
  id: string;
  name: string;
  display_name: string;
  description?: string;
  price_monthly: number;
  price_yearly: number;
  features: Record<string, any>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserSubscription {
  id: string;
  user_id: string;
  plan_id: string;
  status: 'active' | 'cancelled' | 'expired';
  current_period_start?: string;
  current_period_end?: string;
  trial_start?: string;
  trial_end?: string;
  created_at: string;
  updated_at: string;
}

export interface SubscriptionUsage {
  id: string;
  user_id: string;
  subscription_id: string;
  feature_name: string;
  usage_count: number;
  limit_count: number | null;
  period_start: string;
  period_end: string;
  created_at: string;
  updated_at: string;
}

export interface SubscriptionEvent {
  id: string;
  user_id: string;
  subscription_id: string | null;
  event_type: string;
  event_data: Record<string, any> | null;
  created_at: string;
}

export interface UserProfile {
  id: string;
  first_name?: string;
  last_name?: string;
  avatar_url?: string;
  subscription_status: 'free' | 'premium' | 'trial';
  subscription_plan_id?: string;
  subscription_expires_at?: string;
  trial_ends_at?: string;
  updated_at: string;
}

export interface PremiumFeatures {
  unlimited_birds: boolean;
  unlimited_incubations: boolean;
  unlimited_eggs: boolean;
  unlimited_chicks: boolean;
  cloud_sync: boolean;
  advanced_stats: boolean;
  genealogy: boolean;
  data_export: boolean;
  unlimited_notifications: boolean;
  ad_free: boolean;
  custom_notifications: boolean;
  auto_backup: boolean;
}

export interface BillingCycle {
  id: 'monthly' | 'yearly';
  name: string;
  price: number;
  savings?: number;
  popular?: boolean;
}

export interface PaymentProvider {
  id: string;
  name: string;
  logo: string;
  supported_currencies: string[];
}

export interface SubscriptionLimits {
  birds: number;
  incubations: number;
  eggs: number;
  chicks: number;
  notifications: number;
}

export interface UpgradePrompt {
  feature: string;
  current_usage: number;
  limit: number;
  message: string;
  cta_text: string;
}

export interface TrialInfo {
  is_trial_available: boolean;
  trial_days: number;
  trial_end_date?: string;
  days_remaining: number;
} 