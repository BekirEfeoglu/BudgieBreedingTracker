import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { supabase } from '@/integrations/supabase/client';

export const useIncubationOperations = () => {
  const [isDeleting, setIsDeleting] = useState(false);
  const { user } = useAuth();
  const { toast } = useToast();
  const { deleteRecord } = useSupabaseOperations();

  const deleteIncubation = async (incubationId: string): Promise<boolean> => {
    if (!user) {
      console.error('❌ No user found for incubation deletion');
      return false;
    }

    if (!incubationId) {
      console.error('❌ No incubation ID provided');
      return false;
    }

    setIsDeleting(true);
    console.log('🗑️ Starting incubation deletion:', incubationId);

    try {
      // 1. İlk olarak bu kuluçkaya ait yavruları sil
      const { error: chicksError } = await supabase
        .from('chicks')
        .delete()
        .eq('incubation_id', incubationId)
        .eq('user_id', user.id);

      if (chicksError) {
        console.error('❌ Failed to delete chicks:', chicksError);
        toast({
          title: 'Hata',
          description: 'Yavrular silinirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      console.log('✅ Chicks deleted successfully');

      // 2. Şimdi bu kuluçkaya ait yumurtaları sil
      const { error: eggsError } = await supabase
        .from('eggs')
        .delete()
        .eq('incubation_id', incubationId)
        .eq('user_id', user.id);

      if (eggsError) {
        console.error('❌ Failed to delete eggs:', eggsError);
        toast({
          title: 'Hata',
          description: 'Yumurtalar silinirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      console.log('✅ Eggs deleted successfully');

      // 3. Son olarak kuluçkayı sil
      const { error: incubationError } = await supabase
        .from('incubations')
        .delete()
        .eq('id', incubationId)
        .eq('user_id', user.id);

      if (incubationError) {
        console.error('❌ Failed to delete incubation:', incubationError);
        toast({
          title: 'Hata',
          description: 'Kuluçka silinirken bir hata oluştu.',
          variant: 'destructive'
        });
        return false;
      }

      console.log('✅ Incubation deleted successfully');
      toast({
        title: 'Başarılı',
        description: 'Kuluçka, yumurtalar ve yavrular başarıyla silindi.'
      });

      return true;

    } catch (error) {
      console.error('💥 Exception during incubation deletion:', error);
      toast({
        title: 'Hata',
        description: 'Kuluçka silinirken beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
      return false;
    } finally {
      setIsDeleting(false);
    }
  };

  return {
    deleteIncubation,
    isDeleting
  };
};
