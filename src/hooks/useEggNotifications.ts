
import { useEffect } from 'react';
import { notificationService } from '@/services/notificationService';
import { Breeding } from '@/types';

export const useEggNotifications = (breeding: Breeding[]) => {
  
  const calculateExpectedHatchDate = (eggDateAdded: string): Date => {
    // Muhabbet kuşları için ortalama kuluçka süresi 18 gün
    const eggDate = new Date(eggDateAdded);
    const hatchDate = new Date(eggDate);
    hatchDate.setDate(hatchDate.getDate() + 18);
    return hatchDate;
  };

  const scheduleNotificationsForEgg = async (breedingId: string, nestName: string, egg: any) => {
    if (egg.status === 'hatched' || egg.status === 'infertile') {
      // Cancel any existing notifications for hatched/infertile eggs
      await notificationService.cancelEggNotifications(breedingId, egg.number);
      return;
    }

    const expectedHatchDate = calculateExpectedHatchDate(egg.dateAdded);
    
    // Only schedule if the expected hatch date is in the future
    if (expectedHatchDate > new Date()) {
      await notificationService.scheduleEggHatchingReminders(
        breedingId,
        nestName,
        egg.number,
        expectedHatchDate
      );
    }
  };

  const updateNotifications = async () => {
    console.log('🔔 Updating egg hatching notifications...');
    
    for (const breedingRecord of breeding) {
      if (!breedingRecord.eggs) continue;

      for (const egg of breedingRecord.eggs) {
        await scheduleNotificationsForEgg(breedingRecord.id, breedingRecord.nestName, egg);
      }
    }
  };

  // Update notifications whenever breeding data changes
  useEffect(() => {
    updateNotifications();
  }, [breeding]);

  const scheduleForNewEgg = async (breedingId: string, nestName: string, egg: any) => {
    await scheduleNotificationsForEgg(breedingId, nestName, egg);
  };

  const cancelForEgg = async (breedingId: string, eggNumber: number) => {
    await notificationService.cancelEggNotifications(breedingId, eggNumber);
  };

  return {
    scheduleForNewEgg,
    cancelForEgg,
    updateNotifications
  };
};
