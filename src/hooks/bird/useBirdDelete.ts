import { useToast } from '@/hooks/use-toast';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';

interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  birthDate?: string;
  ringNumber?: string;
  photo?: string;
  healthNotes?: string;
  motherId?: string;
  fatherId?: string;
}

export const useBirdDelete = (
  birds: Bird[],
  setBirds: (fn: (prev: Bird[]) => Bird[]) => void
) => {
  const { toast } = useToast();
  const { deleteRecord } = useSupabaseOperations();
  const { user } = useAuth();

  const deleteBird = async (birdId: string) => {
    try {
      if (!user) {
        toast({
          title: 'Yetkilendirme Hatası',
          description: 'İşlem için giriş yapmalısınız.',
          variant: 'destructive'
        });
        return;
      }

      const birdToDelete = birds.find(b => b.id === birdId);
      
      if (!birdToDelete) {
        toast({
          title: 'Hata',
          description: 'Silinecek kuş bulunamadı.',
          variant: 'destructive'
        });
        return;
      }

      console.log('🗑️ Deleting bird:', birdToDelete.name, 'ID:', birdId);

      // Önce referans eden kayıtları kontrol et ve güncelle
      console.log('🔍 Checking for references to bird:', birdId);
      
      // 1. Bu kuşu anne/baba olarak referans eden kuşları güncelle
      const { error: birdsUpdateError } = await supabase
        .from('birds')
        .update({ 
          mother_id: null,
          father_id: null 
        })
        .or(`mother_id.eq.${birdId},father_id.eq.${birdId}`)
        .eq('user_id', user.id);

      if (birdsUpdateError) {
        console.error('❌ Error updating bird references:', birdsUpdateError);
        toast({
          title: 'Hata',
          description: 'Kuş referansları güncellenirken hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      // 2. Bu kuşu anne/baba olarak referans eden yavruları güncelle
      const { error: chicksUpdateError } = await supabase
        .from('chicks')
        .update({ 
          mother_id: null,
          father_id: null 
        })
        .or(`mother_id.eq.${birdId},father_id.eq.${birdId}`)
        .eq('user_id', user.id);

      if (chicksUpdateError) {
        console.error('❌ Error updating chick references:', chicksUpdateError);
        toast({
          title: 'Hata',
          description: 'Yavru referansları güncellenirken hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      // 3. Bu kuşu kullanılan kuluçkaları güncelle
      const { error: incubationsUpdateError } = await supabase
        .from('incubations')
        .update({ 
          female_bird_id: null,
          male_bird_id: null 
        })
        .or(`female_bird_id.eq.${birdId},male_bird_id.eq.${birdId}`)
        .eq('user_id', user.id);

      if (incubationsUpdateError) {
        console.error('❌ Error updating incubation references:', incubationsUpdateError);
        toast({
          title: 'Hata',
          description: 'Kuluçka referansları güncellenirken hata oluştu.',
          variant: 'destructive'
        });
        return;
      }

      console.log('✅ All references updated, proceeding with deletion');

      // Optimistic update
      setBirds(prev => prev.filter(bird => bird.id !== birdId));
      
      const result = await deleteRecord('birds', birdId);
      
      console.log('🗑️ Delete result:', result);
      
      if (result.success && !result.queued) {
        toast({
          title: 'Başarılı',
          description: `"${birdToDelete.name}" adlı kuş ve tüm referansları başarıyla silindi.`,
        });
      } else if (result.queued) {
        toast({
          title: 'Çevrimdışı Mod',
          description: `"${birdToDelete.name}" çevrimdışı olarak silindi.`,
        });
      } else {
        // Revert optimistic update on failure
        console.log('❌ Delete failed, reverting optimistic update');
        setBirds(prev => [...prev, birdToDelete]);
        toast({
          title: 'Hata',
          description: 'Kuş silinirken bir hata oluştu.',
          variant: 'destructive'
        });
      }
      
    } catch (error) {
      console.error('💥 Exception during bird deletion:', error);
      toast({
        title: 'Hata',
        description: 'Kuş silinirken beklenmeyen bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  return { deleteBird };
};
