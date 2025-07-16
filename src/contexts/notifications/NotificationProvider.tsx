import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import { useToast } from "@/hooks/use-toast";
import { useLanguage } from '@/contexts/LanguageContext';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';
import { NotificationContext } from './context';
import { type Notification, type NotificationContextType } from './types';

export const NotificationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [permissionStatus, setPermissionStatus] = useState<NotificationPermission>('default');
  const [isNotificationsEnabled, setIsNotificationsEnabled] = useState(true);
  const notificationSchedulerRef = useRef<NotificationScheduler | null>(null);
  const initializedRef = useRef(false);
  const { toast } = useToast();
  const { t } = useLanguage();

  const unreadCount = useMemo(() => notifications.filter(n => !n.read).length, [notifications]);

  const addNotification = useCallback((notification: Omit<Notification, 'id' | 'timestamp' | 'read'>) => {
    // Son 5 bildirimi kontrol et, aynı başlık ve mesaj varsa ekleme
    const isDuplicate = notifications.slice(0, 5).some(n => n.title === notification.title && n.message === notification.message);
    if (isDuplicate) {
      console.log('Aynı bildirim kısa sürede tekrar eklenmeye çalışıldı, engellendi.');
      return;
    }
    const newNotification: Notification = {
      ...notification,
      id: Date.now().toString(),
      timestamp: new Date(),
      read: false
    };
    
    const updatedNotifications = [newNotification, ...notifications];
    setNotifications(updatedNotifications);
    localStorage.setItem('app_notifications', JSON.stringify(updatedNotifications.slice(0, 50)));

    // Tüm bildirimler artık sadece çan üzerinden gösterilecek
    // Toast sadece kritik sistem hataları için kullanılacak
    console.log('📢 Yeni bildirim eklendi:', notification.title);
  }, [notifications]);

  // Initialize notification system
  useEffect(() => {
    if (initializedRef.current) return;
    
    const initNotificationSystem = async () => {
      try {
        const scheduler = NotificationScheduler.getInstance();
        await scheduler.initialize();
        notificationSchedulerRef.current = scheduler;
        
        // Bildirim sistemi başlatıldı
        
        // Web'de bildirim izni kontrol et
        if ('Notification' in window && Notification.permission === 'default') {
          // Toast yerine bildirim çanına ekle
          addNotification({
            title: 'Bildirim İzni',
            message: 'Hatırlatmalar için bildirim iznini ayarlardan verebilirsiniz.',
            type: 'info'
          });
        }
      } catch (error) {
        console.error('Bildirim sistemi başlatma hatası:', error);
      }
    };

    // Load saved notifications
    const savedNotifications = localStorage.getItem('app_notifications');
    if (savedNotifications) {
      try {
        const parsed = JSON.parse(savedNotifications);
        if (Array.isArray(parsed)) {
          setNotifications(parsed);
        }
      } catch (error) {
        console.error('Error loading saved notifications:', error);
      }
    }

    initNotificationSystem();
    initializedRef.current = true;
  }, [addNotification]);

  // Check notification permission status on mount
  useEffect(() => {
    if ('Notification' in window) {
      setPermissionStatus(Notification.permission);
    }
  }, []);

  // Load notification settings from localStorage
  useEffect(() => {
    const savedSetting = localStorage.getItem('notificationsEnabled');
    if (savedSetting !== null) {
      setIsNotificationsEnabled(JSON.parse(savedSetting));
    }
  }, []);

  const hasPermission = permissionStatus === 'granted';

  const requestPermission = async (): Promise<boolean> => {
    if (!('Notification' in window)) {
      console.warn('This browser does not support desktop notifications');
      // Kritik sistem hatası - toast ile göster
      toast({
        title: t('notifications.notSupported.title', 'Bildirimleri Desteklenmiyor'),
        description: t('notifications.notSupported.description', 'Tarayıcınız bildirim özelliğini desteklemiyor.'),
        variant: 'destructive'
      });
      return false;
    }

    if (Notification.permission === 'denied') {
      // Bildirim çanına ekle
      addNotification({
        title: t('notifications.permissionDenied.title', 'Bildirim İzni Reddedildi'),
        message: t('notifications.permissionDenied.description', 'Tarayıcı ayarlarından bildirim izni verebilirsiniz.'),
        type: 'warning'
      });
      return false;
    }

    try {
      const permission = await Notification.requestPermission();
      setPermissionStatus(permission);
      
      if (permission === 'granted') {
        addNotification({
          title: t('notifications.permissionGranted.title', 'Bildirim İzni Verildi'),
          message: t('notifications.permissionGranted.description', 'Artık önemli olaylar için bildirim alacaksınız.'),
          type: 'info'
        });
        return true;
      } else if (permission === 'denied') {
        addNotification({
          title: t('notifications.permissionDenied.title', 'Bildirim İzni Reddedildi'),
          message: t('notifications.permissionDenied.description', 'Tarayıcı ayarlarından bildirim izni verebilirsiniz.'),
          type: 'warning'
        });
        return false;
      } else {
        addNotification({
          title: t('notifications.permissionDismissed.title', 'İzin Talebi İptal Edildi'),
          message: t('notifications.permissionDismissed.description', 'Bildirim izni için daha sonra tekrar deneyebilirsiniz.'),
          type: 'info'
        });
        return false;
      }
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      // Kritik sistem hatası - toast ile göster
      toast({
        title: t('notifications.permissionError.title', 'İzin Talebi Hatası'),
        description: t('notifications.permissionError.description', 'Bildirim izni alınırken bir hata oluştu.'),
        variant: 'destructive'
      });
      return false;
    }
  };

  const updateNotificationSettings = useCallback((enabled: boolean) => {
    setIsNotificationsEnabled(enabled);
    localStorage.setItem('notificationsEnabled', JSON.stringify(enabled));
    
    addNotification({
      title: enabled 
        ? t('notifications.enabled.title', 'Bildirimler Etkinleştirildi')
        : t('notifications.disabled.title', 'Bildirimler Devre Dışı Bırakıldı'),
      message: enabled
        ? t('notifications.enabled.description', 'Önemli olaylar için bildirim alacaksınız.')
        : t('notifications.disabled.description', 'Artık bildirim almayacaksınız.'),
      type: enabled ? 'info' : 'info'
    });
  }, [addNotification, t]);

  const scheduleLocalNotification = useCallback((
    notification: Omit<Notification, 'id' | 'timestamp' | 'read'>, 
    delayMs: number
  ) => {
    if (!isNotificationsEnabled) {
      console.log('Notifications are disabled, skipping notification');
      return;
    }

    if (!hasPermission) {
      console.log('No notification permission, adding to internal list only');
      addNotification(notification);
      return;
    }

    // Show internal notification first
    addNotification(notification);

    // Schedule browser notification
    setTimeout(() => {
      if (document.visibilityState === 'visible') {
        console.log('App is in foreground, skipping browser notification');
        return;
      }

      try {
        const browserNotification = new Notification(notification.title, {
          body: notification.message,
          icon: '/favicon.ico',
          badge: '/favicon.ico',
          tag: notification.type,
          requireInteraction: notification.persistent || false
        });

        browserNotification.onclick = () => {
          window.focus();
          browserNotification.close();
        };

        // Store interaction
        const interactionData = {
          notification_id: Date.now().toString(),
          action: 'scheduled',
          timestamp: new Date().toISOString(),
          metadata: { delayMs, type: notification.type }
        };

        console.log('📬 Browser notification scheduled:', notification.title);
      } catch (error) {
        console.error('Error showing browser notification:', error);
      }
    }, delayMs);
  }, [isNotificationsEnabled, hasPermission, addNotification]);

  const markAsRead = useCallback((notificationId: string) => {
    const updatedNotifications = notifications.map(n => 
      n.id === notificationId ? { ...n, read: true } : n
    );
    setNotifications(updatedNotifications);
    localStorage.setItem('app_notifications', JSON.stringify(updatedNotifications));
  }, [notifications]);

  const deleteNotification = useCallback((notificationId: string) => {
    const notification = notifications.find(n => n.id === notificationId);
    const updatedNotifications = notifications.filter(n => n.id !== notificationId);
    
    setNotifications(updatedNotifications);
    localStorage.setItem('app_notifications', JSON.stringify(updatedNotifications));
    
    if (notification) {
      // Bildirim silme işlemi çok sık olacağı için toast göstermeyelim
      console.log('🗑️ Bildirim silindi:', notification.title);
    }
  }, [notifications]);

  const clearAllNotifications = useCallback(() => {
    const count = notifications.length;
    
    setNotifications([]);
    localStorage.removeItem('app_notifications');
    
    if (count > 0) {
      // Bildirim temizleme işlemi için çana ekle
      addNotification({
        title: t('notifications.cleared.title', 'Tüm bildirimler temizlendi'),
        message: t('notifications.cleared.description', `${count} bildirim başarıyla silindi.`),
        type: 'info'
      });
    }

    console.log('All notifications cleared, total count:', count);
  }, [notifications, addNotification, t]);

  const value: NotificationContextType = {
    notifications,
    unreadCount,
    permissionStatus,
    hasPermission,
    requestPermission,
    markAsRead,
    deleteNotification,
    clearAllNotifications,
    addNotification,
    scheduleLocalNotification,
    updateNotificationSettings,
    isNotificationsEnabled
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
};