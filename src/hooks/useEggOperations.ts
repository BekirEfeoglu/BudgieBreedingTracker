
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

  const handleEggStatusChange = async (breedingId: string, eggId: string, newStatus: string) => {
    console.log('🥚 Yumurta durumu değişiyor - breedingId:', breedingId, 'eggId:', eggId, 'newStatus:', newStatus);
    
    const breedingRecord = breeding.find(b => b.id === breedingId);
    const egg = breedingRecord?.eggs?.find((e: any) => e.id === eggId);
    
    if (!breedingRecord || !egg) {
      console.error('❌ Kuluçka kaydı veya yumurta bulunamadı:', { breedingRecord, egg });
      toast({
        title: 'Hata',
        description: 'Kuluçka kaydı veya yumurta bulunamadı.',
        variant: 'destructive'
      });
      return;
    }

    console.log('🔍 Bulunan kuluçka kaydı:', breedingRecord);
    console.log('🔍 Bulunan yumurta:', egg);
    console.log('🦜 Mevcut kuşlar:', birds);

    // Cancel existing notifications for this egg
    await notificationService.cancelEggNotifications(breedingId, egg.number);

    if (newStatus === 'hatched') {
      // Anne ve baba kuşlarını bul
      const femaleBird = birds.find(b => b.name === breedingRecord.femaleBird);
      const maleBird = birds.find(b => b.name === breedingRecord.maleBird);
      
      console.log('👩 Anne kuş:', femaleBird);
      console.log('👨 Baba kuş:', maleBird);
      
      const newChick: Chick = {
        id: `chick_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: `Yavru ${egg.number} (${breedingRecord.nestName})`,
        hatchDate: new Date().toISOString().split('T')[0],
        breedingId: breedingId,
        eggId: eggId,
        gender: 'unknown',
        color: '',
        ringNumber: '',
        healthNotes: `${breedingRecord.nestName} yuvasından çıktı`,
        motherId: femaleBird?.id,
        fatherId: maleBird?.id
      };
      
      console.log('🐣 Yeni yavru oluşturuluyor:', newChick);
      console.log('📋 Mevcut yavrular (önce):', chicks);
      
      // Yavruyu ekle
      setChicks(prev => {
        const newChicks = [...prev, newChick];
        console.log('✅ Yavrular listesi güncellendi (sonra):', newChicks);
        return newChicks;
      });
      
      // Yumurtayı sil (çıktığı için artık yumurta listesinde kalmamalı)
      setBreeding(prev => prev.map(b => {
        if (b.id === breedingId) {
          const updatedBreeding = {
            ...b,
            eggs: b.eggs?.filter((e: any) => e.id !== eggId) || []
          };
          console.log('🗑️ Yumurta silindi, güncellenmiş kuluçka:', updatedBreeding);
          return updatedBreeding;
        }
        return b;
      }));
      
      toast({
        title: 'Başarılı! 🐣',
        description: `${egg.number}. yumurta çıktı ve yavrular sekmesine eklendi!`,
      });
      
    } else if (newStatus === 'infertile') {
      // Boş yumurtalar istatistiklerde gösterilmemek üzere özel işaretlenir
      // Ancak takvimde gri ikonla gösterilmek üzere kayıtta tutulur
      setBreeding(prev => prev.map(b => {
        if (b.id === breedingId) {
          return {
            ...b,
            eggs: b.eggs?.map((e: any) => 
              e.id === eggId ? { 
                ...e, 
                status: 'infertile',
                excludeFromStats: true // İstatistiklerden hariç tut
              } : e
            ) || []
          };
        }
        return b;
      }));
      
      toast({
        title: 'Bilgilendirme',
        description: `${egg.number}. yumurta boş olarak işaretlendi. Takvimde gri ikonla gösterilecek.`,
      });
    } else {
      // Diğer durumlar için normal güncelleme ve bildirim programla
      setBreeding(prev => prev.map(b => {
        if (b.id === breedingId) {
          const updatedBreeding = {
            ...b,
            eggs: b.eggs?.map((e: any) => 
              e.id === eggId ? { ...e, status: newStatus } : e
            ) || []
          };
          
          // Schedule notifications for the updated egg if it's fertile/unknown
          if (newStatus === 'fertile' || newStatus === 'unknown') {
            const updatedEgg = updatedBreeding.eggs?.find((e: any) => e.id === eggId);
            if (updatedEgg) {
              const expectedHatchDate = new Date(updatedEgg.dateAdded);
              expectedHatchDate.setDate(expectedHatchDate.getDate() + 18);
              
              if (expectedHatchDate > new Date()) {
                notificationService.scheduleEggHatchingReminders(
                  breedingId,
                  breedingRecord.nestName,
                  updatedEgg.number,
                  expectedHatchDate
                ).catch(console.error);
              }
            }
          }
          
          return updatedBreeding;
        }
        return b;
      }));
      
      toast({
        title: 'Güncellendi',
        description: `${egg.number}. yumurta durumu güncellendi.`,
      });
    }
  };

  return {
    handleAddEgg,
    handleEditEgg,
    handleDeleteEgg,
    handleEggStatusChange
  };
};
