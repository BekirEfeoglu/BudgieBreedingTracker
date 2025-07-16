import { useAuth } from '@/hooks/useAuth';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { useToast } from '@/hooks/use-toast';
import { EggFormData } from '@/types/egg';

export const useEggCrud = () => {
  const { user } = useAuth();
  const { insertRecord, updateRecord, deleteRecord } = useSupabaseOperations();
  const { toast } = useToast();

  const addEgg = async (eggData: EggFormData, incubationId: string): Promise<boolean> => {
    if (!user) {
      return false;
    }

    try {
      // Validate required fields
      if (!eggData.eggNumber || !eggData.startDate || !eggData.status) {
        toast({
          title: 'Hata',
          description: 'Gerekli alanlar eksik.',
          variant: 'destructive'
        });
        return false;
      }
      
      const dbEggData = {
        incubation_id: incubationId,
        egg_number: eggData.eggNumber,
        lay_date: eggData.startDate.toISOString().split('T')[0],
        estimated_hatch_date: eggData.startDate.toISOString().split('T')[0],
        status: eggData.status,
        notes: eggData.notes || null,
        user_id: user.id
      };

      const result = await insertRecord('eggs', dbEggData);
      
      if (result.success) {
        toast({
          title: 'Başarılı',
          description: `${eggData.eggNumber}. yumurta başarıyla eklendi.`
        });
        return true;
      } else {
        toast({
          title: 'Hata',
          description: typeof result.error === 'string' ? result.error : 'Yumurta eklenirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }
      
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Yumurta eklenirken bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    }
  };

  const updateEgg = async (eggId: string, eggData: Partial<EggFormData>): Promise<boolean> => {
    if (!user) {
      return false;
    }

    try {
      const dbEggData: Record<string, unknown> = {
        id: eggId,
        user_id: user.id
      };

      if (eggData.eggNumber !== undefined) dbEggData.egg_number = eggData.eggNumber;
      if (eggData.startDate) {
        dbEggData.lay_date = eggData.startDate.toISOString().split('T')[0];
        dbEggData.estimated_hatch_date = eggData.startDate.toISOString().split('T')[0];
      }
      if (eggData.status) dbEggData.status = eggData.status;
      if (eggData.notes !== undefined) dbEggData.notes = eggData.notes || null;

      const result = await updateRecord('eggs', dbEggData);
      
      if (result.success) {
        toast({
          title: 'Başarılı',
          description: 'Yumurta başarıyla güncellendi.'
        });
        return true;
      }
      
      return false;
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Yumurta güncellenirken bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    }
  };

  const deleteEgg = async (eggId: string): Promise<boolean> => {
    if (!user) {
      return false;
    }

    try {
      const result = await deleteRecord('eggs', eggId);
      
      if (result.success) {
        toast({
          title: 'Başarılı',
          description: 'Yumurta başarıyla silindi.'
        });
        return true;
      }
      
      return false;
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Yumurta silinirken bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    }
  };

  return {
    addEgg,
    updateEgg,
    deleteEgg
  };
};
