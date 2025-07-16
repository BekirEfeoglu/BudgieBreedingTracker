import { toast } from '@/hooks/use-toast';

export interface NotificationData {
  id: string;
  type: 'incubation' | 'feeding' | 'veterinary' | 'breeding' | 'event';
  title: string;
  message: string;
  scheduledFor: Date;
  repeatInterval?: 'daily' | 'weekly' | 'monthly' | 'once' | 'twice_daily';
  data?: any;
  isActive: boolean;
  createdAt: Date;
}

export interface IncubationReminder {
  breedingId: string;
  eggCount: number;
  startDate: Date;
  expectedHatchDate: Date;
  temperatureCheck: boolean;
  humidityCheck: boolean;
  eggTurning: boolean;
}

export interface FeedingReminder {
  chickId?: string;
  birdId?: string;
  foodType: string;
  frequency: 'daily' | 'twice_daily' | 'weekly';
  time: string;
  notes?: string;
}

export interface VeterinaryReminder {
  birdId?: string;
  appointmentType: 'checkup' | 'vaccination' | 'treatment' | 'emergency';
  date: Date;
  vetName?: string;
  notes?: string;
}

export interface BreedingReminder {
  breedingId: string;
  pairName: string;
  cycleType: 'preparation' | 'mating' | 'egg_laying' | 'incubation' | 'hatching';
  dueDate: Date;
}

export interface EventReminder {
  eventId: string;
  eventType: 'competition' | 'exhibition' | 'show' | 'meeting' | 'custom';
  title: string;
  date: Date;
  location?: string;
  description?: string;
}

class PushNotificationService {
  private notifications: NotificationData[] = [];
  private isSupported: boolean;
  private permission: NotificationPermission = 'default';

  constructor() {
    this.isSupported = 'Notification' in window;
    this.loadNotifications();
    this.requestPermission();
    this.startNotificationScheduler();
  }

  // İzin isteme
  async requestPermission(): Promise<boolean> {
    if (!this.isSupported) {
      console.warn('Push notifications are not supported in this browser');
      return false;
    }

    if (this.permission === 'granted') {
      return true;
    }

    try {
      const permission = await Notification.requestPermission();
      this.permission = permission;
      return permission === 'granted';
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      return false;
    }
  }

  // Kuluçka hatırlatıcısı oluşturma
  createIncubationReminder(reminder: IncubationReminder): string {
    const id = `incubation_${Date.now()}`;
    
    // Sıcaklık kontrolü hatırlatıcısı (günlük)
    if (reminder.temperatureCheck) {
      this.scheduleNotification({
        id: `${id}_temp`,
        type: 'incubation',
        title: '🌡️ Kuluçka Sıcaklık Kontrolü',
        message: `${reminder.eggCount} yumurta için sıcaklık kontrolü yapılmalı.`,
        scheduledFor: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 saat sonra
        repeatInterval: 'daily',
        data: { breedingId: reminder.breedingId, checkType: 'temperature' }
      });
    }

    // Nem kontrolü hatırlatıcısı (günlük)
    if (reminder.humidityCheck) {
      this.scheduleNotification({
        id: `${id}_humidity`,
        type: 'incubation',
        title: '💧 Kuluçka Nem Kontrolü',
        message: `${reminder.eggCount} yumurta için nem kontrolü yapılmalı.`,
        scheduledFor: new Date(Date.now() + 24 * 60 * 60 * 1000),
        repeatInterval: 'daily',
        data: { breedingId: reminder.breedingId, checkType: 'humidity' }
      });
    }

    // Yumurta çevirme hatırlatıcısı (günde 3 kez)
    if (reminder.eggTurning) {
      const turningTimes = ['08:00', '14:00', '20:00'];
      turningTimes.forEach((time, index) => {
        const [hours, minutes] = time.split(':').map(Number);
        const scheduledTime = new Date();
        scheduledTime.setHours(hours || 0, minutes || 0, 0, 0);
        
        // Eğer bugünün saati geçtiyse, yarına ayarla
        if (scheduledTime.getTime() < Date.now()) {
          scheduledTime.setDate(scheduledTime.getDate() + 1);
        }

        this.scheduleNotification({
          id: `${id}_turning_${index}`,
          type: 'incubation',
          title: '🥚 Yumurta Çevirme Zamanı',
          message: `${reminder.eggCount} yumurtayı çevirmeyi unutmayın.`,
          scheduledFor: scheduledTime,
          repeatInterval: 'daily',
          data: { breedingId: reminder.breedingId, checkType: 'turning' }
        });
      });
    }

    // Çıkım tarihi hatırlatıcısı
    const daysUntilHatch = Math.ceil((reminder.expectedHatchDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    
    if (daysUntilHatch > 0) {
      // 3 gün önce uyarı
      if (daysUntilHatch >= 3) {
        this.scheduleNotification({
          id: `${id}_hatch_warning`,
          type: 'incubation',
          title: '🐣 Çıkım Yaklaşıyor',
          message: `${daysUntilHatch} gün sonra yumurtalar çıkacak. Hazırlık yapın.`,
          scheduledFor: new Date(reminder.expectedHatchDate.getTime() - 3 * 24 * 60 * 60 * 1000),
          repeatInterval: 'once',
          data: { breedingId: reminder.breedingId, checkType: 'hatch_warning' }
        });
      }

      // Çıkım günü hatırlatıcısı
      this.scheduleNotification({
        id: `${id}_hatch_day`,
        type: 'incubation',
        title: '🎉 Çıkım Günü!',
        message: `${reminder.eggCount} yumurta bugün çıkabilir. Kontrol edin.`,
        scheduledFor: reminder.expectedHatchDate,
        repeatInterval: 'once',
        data: { breedingId: reminder.breedingId, checkType: 'hatch_day' }
      });
    }

    return id;
  }

  // Beslenme hatırlatıcısı oluşturma
  createFeedingReminder(reminder: FeedingReminder): string {
    const id = `feeding_${Date.now()}`;
    const [hours, minutes] = reminder.time.split(':').map(Number);
    
    let repeatInterval: 'daily' | 'twice_daily' | 'weekly' = 'daily';
    let frequencyText = 'günlük';
    
    switch (reminder.frequency) {
      case 'twice_daily':
        repeatInterval = 'twice_daily';
        frequencyText = 'günde 2 kez';
        break;
      case 'weekly':
        repeatInterval = 'weekly';
        frequencyText = 'haftalık';
        break;
    }

    const scheduledTime = new Date();
    scheduledTime.setHours(hours || 0, minutes || 0, 0, 0);
    
    // Eğer bugünün saati geçtiyse, yarına ayarla
    if (scheduledTime.getTime() < Date.now()) {
      scheduledTime.setDate(scheduledTime.getDate() + 1);
    }

    this.scheduleNotification({
      id,
      type: 'feeding',
      title: '🍽️ Beslenme Zamanı',
      message: `${reminder.foodType} ${frequencyText} besleme zamanı. ${reminder.notes || ''}`,
      scheduledFor: scheduledTime,
      repeatInterval,
      data: { 
        chickId: reminder.chickId, 
        birdId: reminder.birdId, 
        foodType: reminder.foodType,
        frequency: reminder.frequency
      }
    });

    return id;
  }

  // Veteriner hatırlatıcısı oluşturma
  createVeterinaryReminder(reminder: VeterinaryReminder): string {
    const id = `veterinary_${Date.now()}`;
    
    const appointmentTypes = {
      checkup: 'Kontrol',
      vaccination: 'Aşılama',
      treatment: 'Tedavi',
      emergency: 'Acil'
    };

    const typeText = appointmentTypes[reminder.appointmentType] || 'Randevu';
    
    // 1 gün önce hatırlatıcı
    const dayBefore = new Date(reminder.date.getTime() - 24 * 60 * 60 * 1000);
    if (dayBefore.getTime() > Date.now()) {
      this.scheduleNotification({
        id: `${id}_day_before`,
        type: 'veterinary',
        title: '🏥 Veteriner Randevusu Yarın',
        message: `${typeText} randevunuz yarın ${reminder.date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} saatinde.`,
        scheduledFor: dayBefore,
        repeatInterval: 'once',
        data: { 
          birdId: reminder.birdId, 
          appointmentType: reminder.appointmentType,
          vetName: reminder.vetName
        }
      });
    }

    // Randevu günü hatırlatıcısı
    this.scheduleNotification({
      id: `${id}_appointment`,
      type: 'veterinary',
      title: '🏥 Veteriner Randevusu Bugün',
      message: `${typeText} randevunuz bugün ${reminder.date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} saatinde.`,
      scheduledFor: reminder.date,
      repeatInterval: 'once',
      data: { 
        birdId: reminder.birdId, 
        appointmentType: reminder.appointmentType,
        vetName: reminder.vetName
      }
    });

    return id;
  }

  // Üreme döngüsü hatırlatıcısı oluşturma
  createBreedingReminder(reminder: BreedingReminder): string {
    const id = `breeding_${Date.now()}`;
    
    const cycleTypes = {
      preparation: 'Hazırlık',
      mating: 'Çiftleşme',
      egg_laying: 'Yumurtlama',
      incubation: 'Kuluçka',
      hatching: 'Çıkım'
    };

    const typeText = cycleTypes[reminder.cycleType] || 'Üreme';
    
    this.scheduleNotification({
      id,
      type: 'breeding',
      title: '❤️ Üreme Döngüsü',
      message: `${reminder.pairName} çifti için ${typeText} aşaması yaklaşıyor.`,
      scheduledFor: reminder.dueDate,
      repeatInterval: 'once',
      data: { 
        breedingId: reminder.breedingId, 
        cycleType: reminder.cycleType,
        pairName: reminder.pairName
      }
    });

    return id;
  }

  // Etkinlik hatırlatıcısı oluşturma
  createEventReminder(reminder: EventReminder): string {
    const id = `event_${Date.now()}`;
    
    const eventTypes = {
      competition: 'Yarışma',
      exhibition: 'Sergi',
      show: 'Gösteri',
      meeting: 'Toplantı',
      custom: 'Etkinlik'
    };

    const typeText = eventTypes[reminder.eventType] || 'Etkinlik';
    
    // 1 hafta önce hatırlatıcı
    const weekBefore = new Date(reminder.date.getTime() - 7 * 24 * 60 * 60 * 1000);
    if (weekBefore.getTime() > Date.now()) {
      this.scheduleNotification({
        id: `${id}_week_before`,
        type: 'event',
        title: `📅 ${typeText} 1 Hafta Kaldı`,
        message: `${reminder.title} etkinliği 1 hafta sonra. ${reminder.location ? `Yer: ${reminder.location}` : ''}`,
        scheduledFor: weekBefore,
        repeatInterval: 'once',
        data: { 
          eventId: reminder.eventId, 
          eventType: reminder.eventType,
          title: reminder.title
        }
      });
    }

    // 1 gün önce hatırlatıcı
    const dayBefore = new Date(reminder.date.getTime() - 24 * 60 * 60 * 1000);
    if (dayBefore.getTime() > Date.now()) {
      this.scheduleNotification({
        id: `${id}_day_before`,
        type: 'event',
        title: `📅 ${typeText} Yarın`,
        message: `${reminder.title} etkinliği yarın ${reminder.date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} saatinde.`,
        scheduledFor: dayBefore,
        repeatInterval: 'once',
        data: { 
          eventId: reminder.eventId, 
          eventType: reminder.eventType,
          title: reminder.title
        }
      });
    }

    // Etkinlik günü hatırlatıcısı
    this.scheduleNotification({
      id: `${id}_event_day`,
      type: 'event',
      title: `📅 ${typeText} Bugün`,
      message: `${reminder.title} etkinliği bugün ${reminder.date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} saatinde.`,
      scheduledFor: reminder.date,
      repeatInterval: 'once',
      data: { 
        eventId: reminder.eventId, 
        eventType: reminder.eventType,
        title: reminder.title
      }
    });

    return id;
  }

  // Bildirim zamanlama
  private scheduleNotification(notification: Omit<NotificationData, 'isActive' | 'createdAt'>): void {
    const fullNotification: NotificationData = {
      ...notification,
      isActive: true,
      createdAt: new Date()
    };
    
    this.notifications.push(fullNotification);
    this.saveNotifications();
    
    // Eğer izin varsa, hemen zamanla
    if (this.permission === 'granted') {
      this.scheduleNotificationInternal(fullNotification);
    }
  }

  // İç bildirim zamanlama
  private scheduleNotificationInternal(notification: NotificationData): void {
    const timeUntilNotification = notification.scheduledFor.getTime() - Date.now();
    
    if (timeUntilNotification <= 0) {
      // Zamanı geçmiş, hemen göster
      this.showNotification(notification);
    } else {
      // Gelecekte, zamanla
      setTimeout(() => {
        this.showNotification(notification);
        this.handleRepeatingNotification(notification);
      }, timeUntilNotification);
    }
  }

  // Tekrarlayan bildirimleri işle
  private handleRepeatingNotification(notification: NotificationData): void {
    if (!notification.repeatInterval || notification.repeatInterval === 'once') {
      return;
    }

    let nextTime: number;
    const now = Date.now();

    switch (notification.repeatInterval) {
      case 'daily':
        nextTime = now + 24 * 60 * 60 * 1000;
        break;
      case 'weekly':
        nextTime = now + 7 * 24 * 60 * 60 * 1000;
        break;
      case 'monthly':
        nextTime = now + 30 * 24 * 60 * 60 * 1000;
        break;
      case 'twice_daily':
        nextTime = now + 12 * 60 * 60 * 1000;
        break;
      default:
        return;
    }

    const nextNotification = {
      ...notification,
      id: `${notification.id}_${Date.now()}`,
      scheduledFor: new Date(nextTime)
    };

    this.scheduleNotificationInternal(nextNotification);
  }

  // Bildirim gösterme
  private showNotification(notification: NotificationData): void {
    if (this.permission === 'granted' && this.isSupported) {
      // Native notification
      new Notification(notification.title, {
        body: notification.message,
        icon: '/favicon.ico',
        badge: '/favicon.ico',
        tag: notification.id,
        data: notification.data
      });
    }

    // Toast notification (her zaman göster)
    toast({
      title: notification.title,
      description: notification.message,
      duration: 5000
    });

    // Bildirimi arşivle
    this.archiveNotification(notification.id);
  }

  // Bildirim arşivleme
  private archiveNotification(notificationId: string): void {
    this.notifications = this.notifications.filter(n => n.id !== notificationId);
    this.saveNotifications();
  }

  // Bildirimleri yükleme
  private loadNotifications(): void {
    try {
      const saved = localStorage.getItem('budgieNotifications');
      if (saved) {
        this.notifications = JSON.parse(saved).map((n: any) => ({
          ...n,
          scheduledFor: new Date(n.scheduledFor)
        }));
      }
    } catch (error) {
      console.error('Error loading notifications:', error);
    }
  }

  // Bildirimleri kaydetme
  private saveNotifications(): void {
    try {
      localStorage.setItem('budgieNotifications', JSON.stringify(this.notifications));
    } catch (error) {
      console.error('Error saving notifications:', error);
    }
  }

  // Bildirim zamanlayıcısını başlat
  private startNotificationScheduler(): void {
    // Her dakika kontrol et
    setInterval(() => {
      const now = Date.now();
      this.notifications
        .filter(n => n.isActive && n.scheduledFor.getTime() <= now)
        .forEach(n => this.showNotification(n));
    }, 60 * 1000);
  }

  // Bildirimleri listeleme
  getNotifications(): NotificationData[] {
    return this.notifications.filter(n => n.isActive);
  }

  // Bildirim silme
  deleteNotification(notificationId: string): void {
    this.notifications = this.notifications.filter(n => n.id !== notificationId);
    this.saveNotifications();
  }

  // Bildirim durumunu değiştirme
  toggleNotification(notificationId: string): void {
    const notification = this.notifications.find(n => n.id === notificationId);
    if (notification) {
      notification.isActive = !notification.isActive;
      this.saveNotifications();
    }
  }

  // Tüm bildirimleri temizleme
  clearAllNotifications(): void {
    this.notifications = [];
    this.saveNotifications();
  }

  // İzin durumunu kontrol etme
  getPermissionStatus(): NotificationPermission {
    return this.permission;
  }

  // Desteklenip desteklenmediğini kontrol etme
  isNotificationSupported(): boolean {
    return this.isSupported;
  }
}

// Singleton instance
export const pushNotificationService = new PushNotificationService();
export default pushNotificationService; 