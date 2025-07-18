import { LocalNotifications } from '@capacitor/local-notifications';
import { supabase } from '@/integrations/supabase/client';
import { NotificationSettings, NotificationSchedule } from './types';
import { loadUserSettings, saveUserSettings, logNotificationInteraction } from './database';
import { getLocalizedText, isInDoNotDisturbPeriod } from './utils';
import { 
  getIncubationMilestones, 
  getChickCareSchedule, 
  getDefaultSchedule,
  analyzeHourlyActivity,
  findOptimalNotificationHours,
  generateSmartSchedule 
} from './templates';

export class NotificationScheduler {
  private static instance: NotificationScheduler;
  private settings: NotificationSettings | null = null;
  private scheduledNotifications: Map<string, any> = new Map();

  static getInstance(): NotificationScheduler {
    if (!NotificationScheduler.instance) {
      NotificationScheduler.instance = new NotificationScheduler();
    }
    return NotificationScheduler.instance;
  }

  async initialize() {
    // İzinleri kontrol et ve iste
    await this.requestPermissions();
    
    // Kullanıcı ayarlarını yükle
    this.settings = await loadUserSettings();
    
    // Mevcut zamanlı bildirimleri yükle
    await this.loadScheduledNotifications();
  }

  private async requestPermissions(): Promise<boolean> {
    try {
      // Local notifications izni
      const localPermissions = await LocalNotifications.requestPermissions();
      return localPermissions.display === 'granted';
    } catch (error) {
      console.error('Bildirim izinleri alınamadı:', error);
      return false;
    }
  }

  // 1. Yumurta Çevirme Hatırlatmaları
  async scheduleEggTurningReminders(incubationId: string, startDate: Date, interval: number = 240) {
    if (!this.settings?.eggTurningEnabled) return;

    const endDate = new Date(startDate.getTime() + (18 * 24 * 60 * 60 * 1000)); // 18 gün
    const notifications: any[] = [];
    
    let currentDate = new Date(startDate);
    let notificationId = 1;

    while (currentDate < endDate) {
      if (!isInDoNotDisturbPeriod(currentDate, this.settings)) {
        notifications.push({
          id: Date.now() + notificationId,
          title: getLocalizedText('egg_turning_title', 'Yumurta Çevirme Zamanı! 🥚', this.settings.language),
          body: getLocalizedText('egg_turning_body', 'Kuluçka makinesindeki yumurtaları çevirme zamanı geldi.', this.settings.language),
          schedule: { at: currentDate },
          actionTypeId: 'egg_turning',
          extra: {
            incubationId,
            type: 'egg_turning',
            interval
          }
        });
      }
      
      currentDate = new Date(currentDate.getTime() + (interval * 60 * 1000));
      notificationId++;
    }

    await LocalNotifications.schedule({ notifications });
    console.log(`${notifications.length} yumurta çevirme hatırlatması planlandı`);
  }

  // 2. Sıcaklık ve Nem Uyarıları
  async sendTemperatureAlert(currentTemp: number, targetMin: number, targetMax: number) {
    if (!this.settings?.temperatureAlertsEnabled) return;

    const tolerance = this.settings.temperatureTolerance || 2;
    const isOutOfRange = currentTemp < (targetMin - tolerance) || currentTemp > (targetMax + tolerance);

    if (isOutOfRange && !isInDoNotDisturbPeriod(new Date(), this.settings)) {
      const alertType = currentTemp < targetMin ? 'low' : 'high';
      const title = getLocalizedText(`temp_alert_${alertType}_title`, 
        alertType === 'low' ? '🥶 Sıcaklık Düşük!' : '🔥 Sıcaklık Yüksek!', this.settings.language);
      
      await this.sendImmediateNotification({
        title,
        body: `Mevcut sıcaklık: ${currentTemp}°C (Hedef: ${targetMin}-${targetMax}°C)`,
        priority: 'critical',
        type: 'temperature_alert',
        metadata: { currentTemp, targetMin, targetMax }
      });
    }
  }

  // 3. Kuluçka Bildirimleri
  async scheduleIncubationMilestones(incubationId: string, startDate: Date) {
    const milestones = getIncubationMilestones();

    const notifications = milestones.map((milestone, index) => ({
      id: Date.now() + index,
      title: milestone.title,
      body: milestone.body,
      schedule: { at: new Date(startDate.getTime() + (milestone.day * 24 * 60 * 60 * 1000)) },
      actionTypeId: 'incubation_milestone',
      extra: {
        incubationId,
        day: milestone.day,
        type: 'incubation_milestone'
      }
    }));

    await LocalNotifications.schedule({ notifications });
  }

  // 4. Yavru Bakım Hatırlatmaları
  async scheduleChickCareReminders(chickId: string, hatchDate: Date) {
    const careSchedule = getChickCareSchedule();

    const notifications = careSchedule.map((care, index) => ({
      id: Date.now() + index + 1000,
      title: care.title,
      body: care.body,
      schedule: { at: new Date(hatchDate.getTime() + (care.hours * 60 * 60 * 1000)) },
      actionTypeId: 'chick_care',
      extra: {
        chickId,
        careType: care.title.includes('Kontrol') ? 'check' : 'feeding',
        priority: care.priority
      }
    }));

    await LocalNotifications.schedule({ notifications });
  }

  // 5. Akıllı Bildirim Zamanlaması (AI Önerileri)
  async suggestOptimalSchedule(userId: string): Promise<NotificationSchedule[]> {
    try {
      // Kullanıcının geçmiş davranışlarını analiz et
      const { data: history } = await supabase
        .from('notification_interactions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(100);

      if (!history || history.length === 0) {
        return getDefaultSchedule();
      }

      // En aktif saatleri hesapla
      const hourlyActivity = analyzeHourlyActivity(history);
      const optimalHours = findOptimalNotificationHours(hourlyActivity);

      return generateSmartSchedule(optimalHours);
    } catch (error) {
      console.error('Akıllı zamanlama analizi hatası:', error);
      return getDefaultSchedule();
    }
  }

  private async sendImmediateNotification(notification: {
    title: string;
    body: string;
    priority: string;
    type: string;
    metadata?: any;
  }) {
    await LocalNotifications.schedule({
      notifications: [{
        id: Date.now(),
        title: notification.title,
        body: notification.body,
        schedule: { at: new Date(Date.now() + 1000) }, // 1 saniye sonra
        sound: this.settings?.soundEnabled ? 'beep.wav' : undefined,
        extra: notification.metadata
      }]
    });
  }

  private async loadScheduledNotifications() {
    try {
      const pending = await LocalNotifications.getPending();
      pending.notifications.forEach(notification => {
        this.scheduledNotifications.set(notification.id.toString(), notification);
      });
    } catch (error) {
      console.error('Planlanmış bildirimler yüklenemedi:', error);
    }
  }

  private handleIncomingNotification(notification: any) {
    // Gelen bildirimi veritabanına kaydet
    logNotificationInteraction(notification.id, 'received');
  }

  private handleNotificationAction(notification: any) {
    // Bildirim aksiyonunu kaydet
    logNotificationInteraction(notification.notification.id, 'clicked');
  }

  // Public API metodları
  async updateSettings(newSettings: Partial<NotificationSettings>) {
    if (this.settings) {
      this.settings = { ...this.settings, ...newSettings };
      await saveUserSettings(this.settings);
    }
  }

  async cancelNotification(notificationId: string) {
    await LocalNotifications.cancel({ notifications: [{ id: parseInt(notificationId) }] });
    this.scheduledNotifications.delete(notificationId);
  }

  async cancelAllNotifications() {
    const pending = await LocalNotifications.getPending();
    if (pending.notifications.length > 0) {
      await LocalNotifications.cancel({ 
        notifications: pending.notifications.map(n => ({ id: n.id })) 
      });
    }
    this.scheduledNotifications.clear();
  }

  getSettings(): NotificationSettings | null {
    return this.settings;
  }
}