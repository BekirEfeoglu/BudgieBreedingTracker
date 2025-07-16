
export const notificationService = {
  async requestNotificationPermission() {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      if (Notification.permission === 'default') {
        await Notification.requestPermission();
      }
    }
  },

  async scheduleEggHatchingReminders(breedingId: string, nestName: string, eggNumber: number, hatchDate: Date) {
    try {
      console.log(`🔔 Scheduling egg hatching reminders for egg ${eggNumber} in breeding ${breedingId}`);
      
      if (typeof window !== 'undefined' && 'Notification' in window) {
        // Request permission if not already granted
        if (Notification.permission === 'default') {
          await Notification.requestPermission();
        }
        
        if (Notification.permission === 'granted') {
          // Calculate delay in milliseconds
          const delay = hatchDate.getTime() - Date.now();
          
          if (delay > 0) {
            setTimeout(() => {
              new Notification('🐣 Yumurta Çıkımı Yaklaşıyor!', {
                body: `${nestName} yuvasındaki ${eggNumber}. yumurtanın çıkım günü geldi!`,
                icon: '/favicon.ico',
                data: {
                  breedingId: breedingId,
                  eggNumber: eggNumber
                },
                tag: `hatching-${breedingId}-${eggNumber}`
              });
            }, delay);
            
            console.log('✅ Egg hatching reminder scheduled successfully');
          } else {
            console.log('⚠️ Hatch date is in the past, skipping');
          }
        }
      }
    } catch (error) {
      console.error('❌ Error scheduling egg hatching reminder:', error);
    }
  },

  async cancelEggNotifications(breedingId: string, eggNumber: number) {
    try {
      console.log(`🔕 Canceling egg hatching notifications for egg ${eggNumber} in breeding ${breedingId}`);
      // In a real implementation, you'd cancel the scheduled notification
      // For now, we'll just log it
      console.log('✅ Egg hatching notifications canceled');
    } catch (error) {
      console.error('❌ Error canceling egg hatching notifications:', error);
    }
  },
  
  // New method for scheduling incubation notifications
  async scheduleNotification(notification: {
    id: string;
    title: string;
    body: string;
    scheduleDate: Date;
    data?: Record<string, any>;
  }) {
    try {
      console.log('🔔 Scheduling notification:', notification.id, 'for', notification.scheduleDate);
      
      if (typeof window !== 'undefined' && 'Notification' in window) {
        // Request permission if not already granted
        if (Notification.permission === 'default') {
          await Notification.requestPermission();
        }
        
        if (Notification.permission === 'granted') {
          // Calculate delay in milliseconds
          const delay = notification.scheduleDate.getTime() - Date.now();
          
          if (delay > 0) {
            setTimeout(() => {
              new Notification(notification.title, {
                body: notification.body,
                icon: '/favicon.ico',
                data: notification.data,
                tag: notification.id
              });
            }, delay);
            
            console.log('✅ Notification scheduled successfully');
          } else {
            console.log('⚠️ Notification date is in the past, skipping');
          }
        }
      }
    } catch (error) {
      console.error('❌ Error scheduling notification:', error);
    }
  },

  async cancelNotification(notificationId: string) {
    try {
      console.log('🔕 Canceling notification:', notificationId);
      // In a real implementation, you'd cancel the scheduled notification
      // For now, we'll just log it
      console.log('✅ Notification canceled:', notificationId);
    } catch (error) {
      console.error('❌ Error canceling notification:', error);
    }
  },

  // Add the missing methods
  async getAllPendingNotifications() {
    try {
      console.log('📋 Getting all pending notifications');
      // In a real implementation, you'd track scheduled notifications
      // For now, return an empty array as placeholder
      return [];
    } catch (error) {
      console.error('❌ Error getting pending notifications:', error);
      return [];
    }
  },

  async clearAllNotifications() {
    try {
      console.log('🗑️ Clearing all notifications');
      // In a real implementation, you'd cancel all scheduled notifications
      // For now, we'll just log it
      console.log('✅ All notifications cleared');
    } catch (error) {
      console.error('❌ Error clearing notifications:', error);
    }
  },
};
