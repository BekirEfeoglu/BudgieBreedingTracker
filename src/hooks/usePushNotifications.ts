import { useState, useEffect, useCallback } from 'react';
import pushNotificationService, { 
  NotificationData, 
  IncubationReminder, 
  FeedingReminder, 
  VeterinaryReminder, 
  BreedingReminder, 
  EventReminder 
} from '@/services/notification/PushNotificationService';

export const usePushNotifications = () => {
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [permission, setPermission] = useState<NotificationPermission>('default');
  const [isSupported, setIsSupported] = useState(false);

  // Bildirimleri yükle
  const loadNotifications = useCallback(() => {
    const activeNotifications = pushNotificationService.getNotifications();
    setNotifications(activeNotifications);
  }, []);

  // İzin durumunu kontrol et
  const checkPermission = useCallback(async () => {
    const currentPermission = pushNotificationService.getPermissionStatus();
    setPermission(currentPermission);
    setIsSupported(pushNotificationService.isNotificationSupported());
  }, []);

  // İzin iste
  const requestPermission = useCallback(async () => {
    const granted = await pushNotificationService.requestPermission();
    if (granted) {
      setPermission('granted');
      loadNotifications();
    }
    return granted;
  }, [loadNotifications]);

  // Kuluçka hatırlatıcısı oluştur
  const createIncubationReminder = useCallback((reminder: IncubationReminder) => {
    const id = pushNotificationService.createIncubationReminder(reminder);
    loadNotifications();
    return id;
  }, [loadNotifications]);

  // Beslenme hatırlatıcısı oluştur
  const createFeedingReminder = useCallback((reminder: FeedingReminder) => {
    const id = pushNotificationService.createFeedingReminder(reminder);
    loadNotifications();
    return id;
  }, [loadNotifications]);

  // Veteriner hatırlatıcısı oluştur
  const createVeterinaryReminder = useCallback((reminder: VeterinaryReminder) => {
    const id = pushNotificationService.createVeterinaryReminder(reminder);
    loadNotifications();
    return id;
  }, [loadNotifications]);

  // Üreme hatırlatıcısı oluştur
  const createBreedingReminder = useCallback((reminder: BreedingReminder) => {
    const id = pushNotificationService.createBreedingReminder(reminder);
    loadNotifications();
    return id;
  }, [loadNotifications]);

  // Etkinlik hatırlatıcısı oluştur
  const createEventReminder = useCallback((reminder: EventReminder) => {
    const id = pushNotificationService.createEventReminder(reminder);
    loadNotifications();
    return id;
  }, [loadNotifications]);

  // Bildirim sil
  const deleteNotification = useCallback((notificationId: string) => {
    pushNotificationService.deleteNotification(notificationId);
    loadNotifications();
  }, [loadNotifications]);

  // Bildirim durumunu değiştir
  const toggleNotification = useCallback((notificationId: string) => {
    pushNotificationService.toggleNotification(notificationId);
    loadNotifications();
  }, [loadNotifications]);

  // Tüm bildirimleri temizle
  const clearAllNotifications = useCallback(() => {
    pushNotificationService.clearAllNotifications();
    loadNotifications();
  }, [loadNotifications]);

  // Bildirimleri kategorilere ayır
  const getNotificationsByType = useCallback((type: NotificationData['type']) => {
    return notifications.filter(n => n.type === type);
  }, [notifications]);

  // Yaklaşan bildirimleri getir (24 saat içinde)
  const getUpcomingNotifications = useCallback(() => {
    const now = Date.now();
    const dayInMs = 24 * 60 * 60 * 1000;
    
    return notifications.filter(n => {
      const timeUntil = n.scheduledFor.getTime() - now;
      return timeUntil > 0 && timeUntil <= dayInMs;
    });
  }, [notifications]);

  // Geçmiş bildirimleri getir
  const getPastNotifications = useCallback(() => {
    const now = Date.now();
    return notifications.filter(n => n.scheduledFor.getTime() < now);
  }, [notifications]);

  // Bildirim sayısını getir
  const getNotificationCount = useCallback(() => {
    return notifications.length;
  }, [notifications]);

  // Kategori bazında bildirim sayısı
  const getNotificationCountByType = useCallback((type: NotificationData['type']) => {
    return notifications.filter(n => n.type === type).length;
  }, [notifications]);

  useEffect(() => {
    checkPermission();
    loadNotifications();
    
    // Her 30 saniyede bir bildirimleri güncelle
    const interval = setInterval(loadNotifications, 30000);
    
    return () => clearInterval(interval);
  }, [checkPermission, loadNotifications]);

  return {
    // State
    notifications,
    permission,
    isSupported,
    
    // Actions
    requestPermission,
    createIncubationReminder,
    createFeedingReminder,
    createVeterinaryReminder,
    createBreedingReminder,
    createEventReminder,
    deleteNotification,
    toggleNotification,
    clearAllNotifications,
    
    // Queries
    getNotificationsByType,
    getUpcomingNotifications,
    getPastNotifications,
    getNotificationCount,
    getNotificationCountByType,
    
    // Utilities
    loadNotifications
  };
}; 