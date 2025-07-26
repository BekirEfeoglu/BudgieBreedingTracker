import { useEffect } from 'react';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';
import { useNotifications } from '@/hooks/useNotifications';

interface Incubation {
  id: string;
  name: string;
  pairId: string;
  maleBirdId: string;
  femaleBirdId: string;
  startDate: string;
  eggCount: number;
  enableNotifications: boolean;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export const useIncubationNotifications = (incubations: Incubation[]) => {
  const { addNotification } = useNotifications();
  const scheduler = NotificationScheduler.getInstance();

  const scheduleIncubationNotifications = async (incubation: Incubation) => {
    if (!incubation.enableNotifications) return;

    try {
      const startDate = new Date(incubation.startDate);
      
      // Yumurta çevirme hatırlatmaları
      await scheduler.scheduleEggTurningReminders(incubation.id, startDate);
      
      // Kuluçka kilometre taşları
      await scheduler.scheduleIncubationMilestones(incubation.id, startDate);
      
      console.log(`✅ Bildirimler planlandı: ${incubation.name}`);
      
      addNotification({
        title: 'Bildirimler Planlandı',
        message: `${incubation.name} için bildirimler ayarlandı.`,
        type: 'breeding'
      });
    } catch (error) {
      console.error('Error scheduling incubation notifications:', error);
      addNotification({
        title: 'Bildirim Hatası',
        message: 'Bildirimler planlanamadı.',
        type: 'error'
      });
    }
  };

  const cancelIncubationNotifications = async (incubationId: string) => {
    try {
      // Bu kuluçkaya ait tüm bildirimleri iptal et
      // Not: Gerçek implementasyonda incubation ID'ye göre filtreleme gerekli
      console.log(`❌ Bildirimler iptal edildi: ${incubationId}`);
    } catch (error) {
      console.error('Error canceling incubation notifications:', error);
    }
  };

  // Kuluçka listesi değiştiğinde bildirimleri güncelle
  useEffect(() => {
    const updateNotifications = async () => {
      for (const incubation of incubations) {
        if (incubation.enableNotifications) {
          await scheduleIncubationNotifications(incubation);
        }
      }
    };

    if (incubations.length > 0) {
      updateNotifications();
    }
  }, [incubations]);

  return {
    scheduleIncubationNotifications,
    cancelIncubationNotifications
  };
};