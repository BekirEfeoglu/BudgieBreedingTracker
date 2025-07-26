import { useCallback, useMemo } from 'react';
import { useEggData } from '@/hooks/egg/useEggData';
import { useEggCrud } from '@/hooks/egg/useEggCrud';
import { EggFormData } from '@/types/egg';
import { useToast } from '@/hooks/use-toast';

export const useEggManagement = (clutchId: string) => {
  const { toast } = useToast();
  
  const {
    eggs: allEggs,
    loading,
    refetchEggs
  } = useEggData(clutchId);

  // No need to filter since useEggData now returns only eggs for this breeding
  const eggs = useMemo(() => {
    return allEggs;
  }, [allEggs, clutchId]);

  const { addEgg: addEggCrud, updateEgg: updateEggCrud, deleteEgg: deleteEggCrud } = useEggCrud(refetchEggs);

  const getNextEggNumber = useCallback(() => {
    if (!eggs || eggs.length === 0) {
      return 1;
    }
    const maxNumber = Math.max(...eggs.map(egg => egg.eggNumber));
    const nextNumber = maxNumber + 1;
    return nextNumber;
  }, [eggs]);

  const addEgg = async (eggData: EggFormData): Promise<boolean> => {
    try {
      const result = await addEggCrud({
        ...eggData,
        clutchId: clutchId
      });
      
      if (result.success) {
        return true;
      } else {
        console.error('❌ useEggManagement.addEgg - Yumurta ekleme başarısız:', result.error);
        return false;
      }
    } catch (error) {
      console.error('💥 useEggManagement.addEgg - Beklenmedik hata:', error);
      return false;
    }
  };

  const updateEgg = async (eggId: string, eggData: Partial<EggFormData>): Promise<boolean> => {
    try {
      const result = await updateEggCrud(eggId, eggData);
      if (result.success) {
        return true;
      } else {
        console.error('❌ useEggManagement.updateEgg - Yumurta güncelleme başarısız:', result.error);
        return false;
      }
    } catch (error) {
      console.error('💥 useEggManagement.updateEgg - Beklenmedik hata:', error);
      return false;
    }
  };

  const deleteEgg = async (eggId: string): Promise<boolean> => {
    try {
      const result = await deleteEggCrud(eggId);
      if (result.success) {
        
        // Force refresh eggs after deletion since realtime subscription might not work
        setTimeout(() => {
          if (refetchEggs) {
            refetchEggs();
          }
        }, 500);
        
        return true;
      } else {
        console.error('❌ useEggManagement.deleteEgg - Yumurta silme başarısız:', result.error);
        return false;
      }
    } catch (error) {
      console.error('💥 useEggManagement.deleteEgg - Beklenmedik hata:', error);
      return false;
    }
  };

  const refetch = useCallback(() => {
    if (refetchEggs) {
      refetchEggs();
    }
  }, [refetchEggs]);

  return {
    eggs,
    loading,
    error: null, // useEggData'dan error gelmiyor, bu yüzden null
    addEgg,
    updateEgg,
    deleteEgg,
    getNextEggNumber,
    refetch
  };
};
