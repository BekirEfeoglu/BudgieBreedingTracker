import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { EggFormData } from '@/types/egg';
import { toast } from '@/hooks/use-toast';

export const useEggCrud = (onSuccess?: () => void) => {
  const { user } = useAuth();

  const addEgg = useCallback(async (eggData: EggFormData) => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive'
      });
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      // Veri dönüşümü
      const mappedData = {
        incubation_id: eggData.clutchId,
        egg_number: eggData.eggNumber,
        hatch_date: eggData.startDate instanceof Date 
          ? eggData.startDate.toISOString().slice(0, 10)
          : eggData.startDate,
        status: eggData.status,
        notes: eggData.notes || null,
        user_id: user.id
      };

      const { data, error } = await supabase
        .from('eggs')
        .insert([mappedData])
        .select()
        .single();

      if (error) {
        toast({
          title: 'Hata',
          description: 'Yumurta eklenirken bir hata oluştu',
          variant: 'destructive'
        });
        return { success: false, error };
      }
      
      // Success callback
      if (onSuccess) {
        onSuccess();
      }

      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla eklendi'
      });

      return { success: true, data };
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Yumurta eklenirken bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, onSuccess, toast]);

  const updateEgg = useCallback(async (eggId: string, eggData: Partial<EggFormData>) => {
    console.log('✏️ updateEgg - Yumurta güncelleme başlıyor:', {
      eggId,
      eggData,
      userId: user?.id
    });

    if (!user) {
      console.error('❌ updateEgg - Kullanıcı girişi yok');
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive'
      });
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      // Veri dönüşümü
      const mappedData: any = {};
      
      if (eggData.eggNumber !== undefined) mappedData.number = eggData.eggNumber;
      if (eggData.startDate !== undefined) {
        mappedData.hatch_date = eggData.startDate instanceof Date 
          ? eggData.startDate.toISOString().slice(0, 10)
          : eggData.startDate;
      }
      if (eggData.status !== undefined) mappedData.status = eggData.status;
      if (eggData.notes !== undefined) mappedData.notes = eggData.notes || null;

      console.log('📤 updateEgg - Supabase\'e gönderilecek veri:', mappedData);

      const { data, error } = await supabase
        .from('eggs')
        .update(mappedData)
        .eq('id', eggId)
        .eq('user_id', user.id)
        .select()
        .single();

      if (error) {
        console.error('❌ updateEgg - Yumurta güncelleme hatası:', error);
        toast({
          title: 'Hata',
          description: 'Yumurta güncellenirken bir hata oluştu',
          variant: 'destructive'
        });
        return { success: false, error };
      }

      console.log('✅ updateEgg - Yumurta başarıyla güncellendi:', data);
      
      // Success callback
      if (onSuccess) {
        console.log('🔄 updateEgg - onSuccess callback çağrılıyor');
        onSuccess();
      }

      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla güncellendi'
      });

      return { success: true, data };
    } catch (error) {
      console.error('💥 updateEgg - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Yumurta güncellenirken bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, toast]);

  const deleteEgg = useCallback(async (eggId: string) => {
    console.log('🗑️ deleteEgg - Yumurta silme başlıyor:', {
      eggId,
      userId: user?.id
    });

    if (!user) {
      console.error('❌ deleteEgg - Kullanıcı girişi yok');
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive'
      });
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      const { error } = await supabase
        .from('eggs')
        .delete()
        .eq('id', eggId)
        .eq('user_id', user.id);

      if (error) {
        console.error('❌ deleteEgg - Yumurta silme hatası:', error);
        toast({
          title: 'Hata',
          description: 'Yumurta silinirken bir hata oluştu',
          variant: 'destructive'
        });
      return { success: false, error };
    }

      console.log('✅ deleteEgg - Yumurta başarıyla silindi');
      
      // Realtime subscription will handle the UI update automatically
      // No need to call onSuccess callback

      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla silindi'
      });

      return { success: true };
    } catch (error) {
      console.error('💥 deleteEgg - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Yumurta silinirken bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, onSuccess, toast]);

  return {
    addEgg,
    updateEgg,
    deleteEgg
  };
}; 