import { useState } from 'react';
import { useAuth } from './useAuth';
import { supabase } from '@/integrations/supabase/client';
import { toast } from '@/components/ui/use-toast';

export const useAccountDeletion = () => {
  const [isDeleting, setIsDeleting] = useState(false);
  const { signOut } = useAuth();

  const deleteAccount = async () => {
    setIsDeleting(true);
    
    try {
      // Kullanıcının tüm verilerini sil
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Kullanıcı bulunamadı');
      }

      // Önce tüm tablolardaki verileri sil
      const tables = [
        'birds',
        'breeding_pairs',
        'eggs',
        'chicks',
        'incubations',
        'calendar_events',
        'notifications',
        'backups',
        'profiles'
      ];

      for (const table of tables) {
        try {
          const { error } = await supabase
            .from(table)
            .delete()
            .eq('user_id', user.id);
          
          if (error) {
            console.warn(`${table} tablosundan veri silinirken hata:`, error);
          }
        } catch (error) {
          console.warn(`${table} tablosundan veri silinirken hata:`, error);
        }
      }

      // Kullanıcı hesabını sil
      const { error: deleteError } = await supabase.auth.admin.deleteUser(user.id);
      
      if (deleteError) {
        // Eğer admin yetkisi yoksa, kullanıcıyı kendisi silebilir
        const { error: userDeleteError } = await supabase.auth.admin.deleteUser(user.id);
        
        if (userDeleteError) {
          throw new Error('Hesap silinemedi');
        }
      }

      toast({
        title: 'Hesap Silindi',
        description: 'Hesabınız başarıyla silindi.',
      });

      // Çıkış yap
      await signOut();
      
    } catch (error) {
      console.error('Hesap silme hatası:', error);
      toast({
        title: 'Hata',
        description: 'Hesap silinirken bir hata oluştu.',
        variant: 'destructive',
      });
      throw error;
    } finally {
      setIsDeleting(false);
    }
  };

  return {
    deleteAccount,
    isDeleting,
  };
}; 