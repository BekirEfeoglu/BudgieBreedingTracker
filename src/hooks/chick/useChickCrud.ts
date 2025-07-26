import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { Chick } from '@/types';

export const useChickCrud = () => {
  const { user } = useAuth();
  const { toast } = useToast();

  const deleteChick = useCallback(async (chickId: string) => {
    if (!user) {
      console.error('❌ deleteChick - Kullanıcı girişi yok');
      return { success: false, error: 'Kullanıcı girişi yok' };
    }
    
    console.log('🗑️ deleteChick - Yavru silme başlıyor:', { chickId, userId: user.id });
    
    try {
      const { error } = await supabase
        .from('chicks')
        .delete()
        .eq('id', chickId)
        .eq('user_id', user.id);

      if (error) {
        console.error('❌ deleteChick - Yavru silme hatası:', error);
        toast({
          title: 'Hata',
          description: `Yavru silinirken bir hata oluştu: ${error.message}`,
          variant: 'destructive'
        });
        return { success: false, error };
      }

      console.log('✅ deleteChick - Yavru başarıyla silindi');
      
      toast({
        title: 'Başarılı',
        description: 'Yavru başarıyla silindi'
      });

      // Force refresh chicks list after deletion since realtime subscription might not work
      setTimeout(() => {
        console.log('🔄 deleteChick - Yavru listesi yenileniyor');
        // This will be handled by the parent component
      }, 500);

      return { success: true };
    } catch (error) {
      console.error('💥 deleteChick - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, toast]);

  const updateChick = useCallback(async (chickId: string, chickData: Partial<Chick>) => {
    if (!user) {
      console.error('❌ updateChick - Kullanıcı girişi yok');
      return { success: false, error: 'Kullanıcı girişi yok' };
    }
    
    console.log('✏️ updateChick - Yavru güncelleme başlıyor:', { chickId, chickData, userId: user.id });
    
    try {
      const { error } = await supabase
        .from('chicks')
        .update(chickData)
        .eq('id', chickId)
        .eq('user_id', user.id);

      if (error) {
        console.error('❌ updateChick - Yavru güncelleme hatası:', error);
        toast({
          title: 'Hata',
          description: `Yavru güncellenirken bir hata oluştu: ${error.message}`,
          variant: 'destructive'
        });
        return { success: false, error };
      }

      console.log('✅ updateChick - Yavru başarıyla güncellendi');
      
      toast({
        title: 'Başarılı',
        description: 'Yavru başarıyla güncellendi'
      });

      return { success: true };
    } catch (error) {
      console.error('💥 updateChick - Beklenmedik hata:', error);
      toast({
        title: 'Hata',
        description: 'Beklenmedik bir hata oluştu',
        variant: 'destructive'
      });
      return { success: false, error };
    }
  }, [user, toast]);

  return {
    deleteChick,
    updateChick
  };
}; 