import { NotificationSettings } from './types';

export const getLocalizedText = (key: string, defaultText: string, language?: 'tr' | 'en'): string => {
  const translations: Record<string, Record<string, string>> = {
    tr: {
      egg_turning_title: 'Yumurta Çevirme Zamanı! 🥚',
      egg_turning_body: 'Kuluçka makinesindeki yumurtaları çevirme zamanı geldi.',
      temp_alert_low_title: '🥶 Sıcaklık Düşük!',
      temp_alert_high_title: '🔥 Sıcaklık Yüksek!'
    },
    en: {
      egg_turning_title: 'Time to Turn Eggs! 🥚',
      egg_turning_body: 'It\'s time to turn the eggs in the incubator.',
      temp_alert_low_title: '🥶 Temperature Too Low!',
      temp_alert_high_title: '🔥 Temperature Too High!'
    }
  };

  const lang = language || 'tr';
  return translations[lang]?.[key] || defaultText;
};

export const isInDoNotDisturbPeriod = (date: Date, settings?: NotificationSettings): boolean => {
  if (!settings?.doNotDisturbStart || !settings?.doNotDisturbEnd) return false;

  const time = date.toTimeString().slice(0, 5); // HH:mm format
  const start = settings.doNotDisturbStart;
  const end = settings.doNotDisturbEnd;

  if (start <= end) {
    return time >= start && time <= end;
  } else {
    // Gece geçişi (örn: 22:00 - 08:00)
    return time >= start || time <= end;
  }
};

export const getDefaultSettings = (userId: string): NotificationSettings => {
  return {
    userId,
    eggTurningEnabled: true,
    eggTurningInterval: 240, // 4 saat
    temperatureAlertsEnabled: true,
    temperatureMin: 37.5,
    temperatureMax: 37.8,
    temperatureTolerance: 0.5,
    humidityAlertsEnabled: true,
    humidityMin: 55,
    humidityMax: 65,
    feedingRemindersEnabled: true,
    feedingInterval: 8, // 8 saat
    language: 'tr',
    soundEnabled: true,
    vibrationEnabled: true
  };
};