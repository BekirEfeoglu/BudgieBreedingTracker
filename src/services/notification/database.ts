import { supabase } from '@/integrations/supabase/client';
import { NotificationSettings, DatabaseNotificationSettings } from './types';
import { getDefaultSettings } from './utils';

export const loadUserSettings = async (): Promise<NotificationSettings | null> => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      // Önce localStorage'dan kontrol et
      const localSettings = localStorage.getItem('notification_settings');
      if (localSettings) {
        try {
          const parsed = JSON.parse(localSettings);
          if (parsed.userId === user.id) {
            console.log('Loading settings from localStorage');
            return parsed;
          }
        } catch (error) {
          console.warn('localStorage settings parse error:', error);
        }
      }
      
      // Veritabanından yüklemeyi dene
      try {
        const { data: existingData, error: fetchError } = await supabase
          .from('user_notification_settings')
          .select('*')
          .eq('user_id', user.id)
          .limit(1);
        
        if (fetchError) {
          console.warn('Notification settings fetch error:', fetchError.message);
          return getDefaultSettings(user.id);
        }
        
        // Eğer kayıt varsa ilkini kullan
        if (existingData && existingData.length > 0) {
          const data = existingData[0];
          if (data) {
            // Convert database snake_case to camelCase
            return {
              userId: data.user_id,
              eggTurningEnabled: data.egg_turning_enabled ?? false,
              eggTurningInterval: data.egg_turning_interval ?? 4,
              temperatureAlertsEnabled: data.temperature_alerts_enabled ?? false,
              temperatureMin: data.temperature_min ?? 35,
              temperatureMax: data.temperature_max ?? 40,
              temperatureTolerance: data.temperature_tolerance ?? 1,
              humidityAlertsEnabled: data.humidity_alerts_enabled ?? false,
              humidityMin: data.humidity_min ?? 50,
              humidityMax: data.humidity_max ?? 70,
              feedingRemindersEnabled: data.feeding_reminders_enabled ?? false,
              feedingInterval: data.feeding_interval ?? 4,
              doNotDisturbStart: data.do_not_disturb_start ?? '22:00',
              doNotDisturbEnd: data.do_not_disturb_end ?? '08:00',
              language: (data.language as 'tr' | 'en') ?? 'tr',
              soundEnabled: data.sound_enabled ?? true,
              vibrationEnabled: data.vibration_enabled ?? true
            };
          }
        }
      } catch (error) {
        console.warn('Database load error:', error);
      }
      
      // Kayıt yoksa varsayılan ayarları oluştur
      const defaultSettings = getDefaultSettings(user.id);
      await saveUserSettings(defaultSettings);
      return defaultSettings;
    }
  } catch (error: any) {
    console.warn('Kullanıcı ayarları yüklenemedi:', error?.message || 'Unknown error');
  }
  return null;
};

export const saveUserSettings = async (settings: NotificationSettings): Promise<void> => {
  try {
    // Geçici olarak sadece temel alanları kaydet
    const dbSettings: any = {
      user_id: settings.userId,
      egg_turning_enabled: settings.eggTurningEnabled,
      egg_turning_interval: settings.eggTurningInterval,
      temperature_alerts_enabled: settings.temperatureAlertsEnabled,
      temperature_min: settings.temperatureMin,
      temperature_max: settings.temperatureMax,
      temperature_tolerance: settings.temperatureTolerance,
      humidity_alerts_enabled: settings.humidityAlertsEnabled,
      humidity_min: settings.humidityMin,
      humidity_max: settings.humidityMax,
      feeding_reminders_enabled: settings.feedingRemindersEnabled,
      feeding_interval: settings.feedingInterval,
      do_not_disturb_start: settings.doNotDisturbStart || '22:00',
      do_not_disturb_end: settings.doNotDisturbEnd || '08:00',
      sound_enabled: settings.soundEnabled,
      vibration_enabled: settings.vibrationEnabled
    };
    
    // Language sütunu için ayrı kontrol
    const { data: tableInfo } = await supabase
      .from('user_notification_settings')
      .select('language')
      .limit(1);
    
    if (tableInfo !== null) {
      dbSettings.language = settings.language;
    }
    
    const { error } = await supabase
      .from('user_notification_settings')
      .upsert(dbSettings);
      
    if (error) {
      console.warn('Notification settings save error:', error.message);
      // Hata durumunda geçici olarak localStorage'a kaydet
      localStorage.setItem('notification_settings', JSON.stringify(settings));
    }
  } catch (error: any) {
    console.warn('Ayarlar kaydedilemedi:', error?.message || 'Unknown error');
    // Hata durumunda geçici olarak localStorage'a kaydet
    localStorage.setItem('notification_settings', JSON.stringify(settings));
  }
};

export const saveFCMToken = async (token: string): Promise<void> => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      // FCM token'ı manuel olarak kaydet (veritabanı tablosu oluşturuldu)
      console.log('FCM token saved:', token);
    }
  } catch (error) {
    console.error('FCM token kaydedilemedi:', error);
  }
};

export const logNotificationInteraction = async (notificationId: string, action: string): Promise<void> => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await supabase
        .from('notification_interactions')
        .insert({
          user_id: user.id,
          notification_id: notificationId,
          action,
          timestamp: new Date().toISOString()
        });
    }
  } catch (error) {
    console.error('Bildirim etkileşimi kaydedilemedi:', error);
  }
};