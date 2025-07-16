import { useCallback } from 'react';
import { useEggData } from '@/hooks/egg/useEggData';
import { useEggCrud } from '@/hooks/egg/useEggCrud';
import { EggFormData } from '@/types/egg';
import { useToast } from '@/hooks/use-toast';

export const useEggManagement = (clutchId: string) => {
  const { toast } = useToast();
  
  const {
    eggs,
    loading,
    error,
    refetch
  } = useEggData(clutchId);

  const { addEgg: addEggCrud, updateEgg: updateEggCrud, deleteEgg: deleteEggCrud } = useEggCrud();

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
      const success = await addEggCrud({
        ...eggData,
        clutchId: clutchId
      }, clutchId);
      
      if (success) {
        await refetch();
        return true;
      }
      return false;
    } catch (_error) {
      return false;
    }
  };

  const updateEgg = async (eggId: string, eggData: Partial<EggFormData>): Promise<boolean> => {
    try {
      const success = await updateEggCrud(eggId, eggData);
      if (success) {
        await refetch();
        return true;
      }
      return false;
    } catch (_error) {
      return false;
    }
  };

  const deleteEgg = async (eggId: string): Promise<boolean> => {
    try {
      const success = await deleteEggCrud(eggId);
      if (success) {
        await refetch();
        return true;
      }
      return false;
    } catch (_error) {
      return false;
    }
  };

  return {
    eggs,
    loading,
    error,
    addEgg,
    updateEgg,
    deleteEgg,
    getNextEggNumber,
    refetch
  };
};
