import { supabase } from '@/integrations/supabase/client';

export interface NotificationSchedule {
  id: string;
  userId: string;
  type: 'egg' | 'chick' | 'breeding' | 'health' | 'custom';
  title: string;
  message: string;
  scheduledAt: string;
  isActive: boolean;
  metadata?: Record<string, any>;
}

export interface NotificationSettings {
  language: 'tr' | 'en';
  soundEnabled: boolean;
  vibrationEnabled: boolean;
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
  doNotDisturbStart: string | null;
  doNotDisturbEnd: string | null;
}

export class NotificationScheduler {
  private static instance: NotificationScheduler;
  private settings: NotificationSettings = {
    language: 'tr',
    soundEnabled: true,
    vibrationEnabled: true,
    eggTurningEnabled: false,
    eggTurningInterval: 240,
    temperatureAlertsEnabled: false,
    temperatureMin: 37,
    temperatureMax: 38,
    temperatureTolerance: 0.5,
    humidityAlertsEnabled: false,
    humidityMin: 55,
    humidityMax: 65,
    feedingRemindersEnabled: false,
    feedingInterval: 720,
    doNotDisturbStart: null,
    doNotDisturbEnd: null,
  };

  static getInstance(): NotificationScheduler {
    if (!NotificationScheduler.instance) {
      NotificationScheduler.instance = new NotificationScheduler();
    }
    return NotificationScheduler.instance;
  }

  async initialize(): Promise<void> {
    try {
      // Mock implementation - gerçek veritabanından ayarları yükle
      console.log('NotificationScheduler başlatıldı');
      // Gerçek uygulamada burada veritabanından ayarları yüklerdik
    } catch (error) {
      console.error('NotificationScheduler başlatma hatası:', error);
    }
  }

  getSettings(): NotificationSettings {
    return { ...this.settings };
  }

  async updateSettings(updates: Partial<NotificationSettings>): Promise<void> {
    try {
      this.settings = { ...this.settings, ...updates };
      console.log('Bildirim ayarları güncellendi:', updates);
      // Gerçek uygulamada burada veritabanına kaydederdik
    } catch (error) {
      console.error('Bildirim ayarları güncelleme hatası:', error);
      throw error;
    }
  }

  async scheduleNotification(schedule: Omit<NotificationSchedule, 'id'>): Promise<{ success: boolean; id?: string; error?: any }> {
    try {
      // Mock implementation - gerçek veritabanı tablosu yok
      const mockId = crypto.randomUUID();
      console.log('Mock bildirim planlandı:', { id: mockId, ...schedule });
      return { success: true, id: mockId };
    } catch (error) {
      console.error('Bildirim planlama hatası:', error);
      return { success: false, error };
    }
  }

  async getScheduledNotifications(userId: string): Promise<{ success: boolean; data?: NotificationSchedule[]; error?: any }> {
    try {
      // Mock implementation
      console.log('Mock bildirimler getiriliyor:', userId);
      return { success: true, data: [] };
    } catch (error) {
      console.error('Planlanmış bildirimler getirme hatası:', error);
      return { success: false, error };
    }
  }

  async cancelNotification(notificationId: string): Promise<{ success: boolean; error?: any }> {
    try {
      // Mock implementation
      console.log('Mock bildirim iptal edildi:', notificationId);
      return { success: true };
    } catch (error) {
      console.error('Bildirim iptal hatası:', error);
      return { success: false, error };
    }
  }

  async updateNotification(notificationId: string, updates: Partial<NotificationSchedule>): Promise<{ success: boolean; error?: any }> {
    try {
      // Mock implementation
      console.log('Mock bildirim güncellendi:', notificationId, updates);
      return { success: true };
    } catch (error) {
      console.error('Bildirim güncelleme hatası:', error);
      return { success: false, error };
    }
  }

  // Özel bildirim türleri için yardımcı metodlar
  async scheduleEggNotification(userId: string, eggId: string, scheduledAt: string): Promise<{ success: boolean; id?: string; error?: any }> {
    return this.scheduleNotification({
      userId,
      type: 'egg',
      title: 'Yumurta Hatırlatması',
      message: 'Yumurta kontrolü zamanı geldi',
      scheduledAt,
      isActive: true,
      metadata: { eggId },
    });
  }

  async scheduleChickNotification(userId: string, chickId: string, scheduledAt: string): Promise<{ success: boolean; id?: string; error?: any }> {
    return this.scheduleNotification({
      userId,
      type: 'chick',
      title: 'Civciv Bakım Hatırlatması',
      message: 'Civciv bakımı zamanı geldi',
      scheduledAt,
      isActive: true,
      metadata: { chickId },
    });
  }

  async scheduleBreedingNotification(userId: string, breedingId: string, scheduledAt: string): Promise<{ success: boolean; id?: string; error?: any }> {
    return this.scheduleNotification({
      userId,
      type: 'breeding',
      title: 'Üretim Hatırlatması',
      message: 'Üretim kontrolü zamanı geldi',
      scheduledAt,
      isActive: true,
      metadata: { breedingId },
    });
  }
} 