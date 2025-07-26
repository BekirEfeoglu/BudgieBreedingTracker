
import { toast } from '@/hooks/use-toast';
import { Bird, Chick, Breeding } from '@/types';
import { notificationService } from '@/services/notificationService';

export const useEggOperations = (
  breeding: Breeding[],
  setBreeding: (fn: (prev: Breeding[]) => Breeding[]) => void,
  setEditingBreeding: (breeding: any) => void,
  setEditingEgg: (egg: any) => void,
  setIsBreedingFormOpen: (open: boolean) => void,
  birds: Bird[],
  chicks: Chick[],
  setChicks: (fn: (prev: Chick[]) => Chick[]) => void
) => {
  const handleAddEgg = (breedingId: string) => {
    console.log('Yumurta ekleme:', breedingId);
    const breedingRecord = breeding.find(b => b.id === breedingId);
    if (breedingRecord) {
      setEditingBreeding(breedingRecord);
      setIsBreedingFormOpen(true);
    }
  };

  const handleEditEgg = (breedingId: string, egg: any) => {
    console.log('Yumurta düzenleme:', breedingId, egg);
    const breedingRecord = breeding.find(b => b.id === breedingId);
    if (breedingRecord) {
      setEditingBreeding(breedingRecord);
      setEditingEgg(egg);
      setIsBreedingFormOpen(true);
    }
  };

  const handleDeleteEgg = async (breedingId: string, eggId: string) => {
    const breedingRecord = breeding.find(b => b.id === breedingId);
    const egg = breedingRecord?.eggs?.find((e: any) => e.id === eggId);
    
    if (egg) {
      // Cancel notifications for this egg
      await notificationService.cancelEggNotifications(breedingId, egg.number);
    }

    setBreeding(prev => prev.map(b => {
      if (b.id === breedingId) {
        return {
          ...b,
          eggs: b.eggs?.filter((egg: any) => egg.id !== eggId) || []
        };
      }
      return b;
    }));
  };

  const handleEggStatusChange = (breedingId: string, eggId: string, newStatus: string) => {
    setBreeding(prev => prev.map(b => {
      if (b.id === breedingId) {
        return {
          ...b,
          eggs: b.eggs?.map((egg: any) => 
            egg.id === eggId ? { ...egg, status: newStatus } : egg
          ) || []
        };
      }
      return b;
    }));
  };

  return {
    handleAddEgg,
    handleEditEgg,
    handleDeleteEgg,
    handleEggStatusChange
  };
};
