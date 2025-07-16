export interface NotificationSchedule {
  id: string;
  type: 'egg_turning' | 'temperature_alert' | 'humidity_alert' | 'incubation_reminder' | 'feeding_schedule' | 'health_check';
  title: string;
  body: string;
  scheduledAt: Date;
  isRecurring: boolean;
  intervalMinutes?: number;
  relatedEntityId?: string;
  priority: 'low' | 'normal' | 'high' | 'critical';
  metadata?: Record<string, any>;
}

export interface NotificationSettings {
  userId: string;
  eggTurningEnabled: boolean;
  eggTurningInterval: number; // minutes
  temperatureAlertsEnabled: boolean;
  temperatureMin: number;
  temperatureMax: number;
  temperatureTolerance: number;
  humidityAlertsEnabled: boolean;
  humidityMin: number;
  humidityMax: number;
  feedingRemindersEnabled: boolean;
  feedingInterval: number; // hours
  doNotDisturbStart?: string; // HH:mm format
  doNotDisturbEnd?: string; // HH:mm format
  language: 'tr' | 'en';
  soundEnabled: boolean;
  vibrationEnabled: boolean;
}

export interface DatabaseNotificationSettings {
  user_id: string;
  egg_turning_enabled: boolean;
  egg_turning_interval: number;
  temperature_alerts_enabled: boolean;
  temperature_min: number;
  temperature_max: number;
  temperature_tolerance: number;
  humidity_alerts_enabled: boolean;
  humidity_min: number;
  humidity_max: number;
  feeding_reminders_enabled: boolean;
  feeding_interval: number;
  do_not_disturb_start?: string;
  do_not_disturb_end?: string;
  language: string;
  sound_enabled: boolean;
  vibration_enabled: boolean;
}