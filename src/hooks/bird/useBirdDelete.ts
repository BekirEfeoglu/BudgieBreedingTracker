import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Bird } from '@/types';
import { useAuth } from '@/hooks/useAuth';

export const useBirdDelete = (birds: Bird[], setBirds: React.Dispatch<React.SetStateAction<Bird[]>>) => {
  const { user } = useAuth();

  const deleteBird = useCallback(async (birdId: string) => {
    if (!user) return;

    try {
      // Optimistic update
      const birdToDelete = birds.find(bird => bird.id === birdId);
      setBirds(prev => prev.filter(bird => bird.id !== birdId));

      // Supabase'e gönder
      const { error } = await supabase
        .from('birds')
        .delete()
        .eq('id', birdId)
        .eq('user_id', user.id);

      if (error) {
        console.error('Kuş silinirken hata:', error);
        // Hata durumunda optimistic update'i geri al
        if (birdToDelete) {
          setBirds(prev => [...prev, birdToDelete]);
        }
        throw error;
      }
    } catch (error) {
      console.error('Kuş silinirken hata:', error);
      throw error;
    }
  }, [user, setBirds, birds]);

  return { deleteBird };
}; 