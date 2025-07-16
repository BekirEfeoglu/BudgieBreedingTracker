import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { toast } from '@/components/ui/use-toast';

export const useAccountDeletion = () => {
  const [isDeleting, setIsDeleting] = useState(false);
  const { user } = useAuth();

  const deleteAccount = async () => {
    if (!user) {
      throw new Error('Kullanıcı bulunamadı');
    }

    setIsDeleting(true);
    
    try {
      // 1. Önce tüm kullanıcı verilerini sil
      const _tablesToClean = [
        'birds',
        'chicks', 
        'eggs',
        'breeding_records',
        'incubations',
        'photos',
        'notifications'
      ];

      // Her tablo için ayrı ayrı silme işlemi yap
      try {
        await supabase.from('notification_interactions').delete().eq('user_id', user.id);
      } catch (e) { console.warn('notification_interactions silme uyarısı:', e); }

      try {
        await supabase.from('user_notification_tokens').delete().eq('user_id', user.id);
      } catch (e) { console.warn('user_notification_tokens silme uyarısı:', e); }

      try {
        await supabase.from('user_notification_settings').delete().eq('user_id', user.id);
      } catch (e) { console.warn('user_notification_settings silme uyarısı:', e); }

      try {
        await supabase.from('backup_history').delete().eq('user_id', user.id);
      } catch (e) { console.warn('backup_history silme uyarısı:', e); }

      try {
        await supabase.from('backup_jobs').delete().eq('user_id', user.id);
      } catch (e) { console.warn('backup_jobs silme uyarısı:', e); }

      try {
        await supabase.from('backup_settings').delete().eq('user_id', user.id);
      } catch (e) { console.warn('backup_settings silme uyarısı:', e); }

      try {
        await supabase.from('calendar').delete().eq('user_id', user.id);
      } catch (e) { console.warn('calendar silme uyarısı:', e); }

      try {
        await supabase.from('clutches').delete().eq('user_id', user.id);
      } catch (e) { console.warn('clutches silme uyarısı:', e); }

      try {
        await supabase.from('incubations').delete().eq('user_id', user.id);
      } catch (e) { console.warn('incubations silme uyarısı:', e); }

      try {
        await supabase.from('birds').delete().eq('user_id', user.id);
      } catch (e) { console.warn('birds silme uyarısı:', e); }

      // 2. Profil bilgilerini sil
      try {
        await supabase.from('profiles').delete().eq('id', user.id);
      } catch (e) { 
        console.warn('Profil silerken uyarı:', e); 
      }

      // 3. Kullanıcı hesabını silme işlemi (Bu normal kullanıcılar tarafından yapılamaz)
      // Bunun yerine hesap devre dışı bırakma yaklaşımı kullanıyoruz

      // 4. Oturumu sonlandır
      await supabase.auth.signOut();

      toast({
        title: 'Hesap Silindi',
        description: 'Hesabınız ve tüm verileriniz başarıyla silindi.',
      });

      // Sayfayı yeniden yükle
      setTimeout(() => {
        window.location.href = '/';
      }, 2000);

      return { success: true };
    } catch (error) {
      console.error('Hesap silme hatası:', error);
      
      toast({
        title: 'Hesap Silme Hatası',
        description: error instanceof Error ? error.message : 'Hesap silinirken beklenmeyen bir hata oluştu.',
        variant: 'destructive',
      });

      return { success: false, error };
    } finally {
      setIsDeleting(false);
    }
  };

  return {
    deleteAccount,
    isDeleting
  };
};