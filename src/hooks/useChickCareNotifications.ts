import { useEffect } from 'react';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';
import { useToast } from '@/hooks/use-toast';

interface Chick {
  id: string;
  name: string;
  hatch_date: string;
}

export const useChickCareNotifications = (chicks: Chick[]) => {
  const { toast } = useToast();
  const scheduler = NotificationScheduler.getInstance();

  const scheduleChickCareNotifications = async (chick: Chick) => {
    try {
      const hatchDate = new Date(chick.hatch_date);
      
      // Yavru bakım hatırlatmaları
      await scheduler.scheduleChickCareReminders(chick.id, hatchDate);
      
      console.log(`🐤 Yavru bakım bildirimleri planlandı: ${chick.name}`);
      
      toast({
        title: 'Yavru Bakım Bildirimleri',
        description: `${chick.name} için bakım hatırlatmaları ayarlandı.`,
      });
    } catch (error) {
      console.error('Error scheduling chick care notifications:', error);
      toast({
        title: 'Bildirim Hatası',
        description: 'Yavru bakım bildirimleri planlanamadı.',
        variant: 'destructive'
      });
    }
  };

  // Yavru listesi değiştiğinde bildirimleri güncelle
  useEffect(() => {
    const updateNotifications = async () => {
      for (const chick of chicks) {
        await scheduleChickCareNotifications(chick);
      }
    };

    if (chicks.length > 0) {
      updateNotifications();
    }
  }, [chicks]);

  return {
    scheduleChickCareNotifications
  };
};