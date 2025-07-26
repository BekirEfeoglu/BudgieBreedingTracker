import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Bird } from '@/types';
import { useAuth } from '@/hooks/useAuth';

export const useBirdUpdate = (birds: Bird[], setBirds: React.Dispatch<React.SetStateAction<Bird[]>>) => {
  const { user } = useAuth();

  const editBird = useCallback(async (updatedBird: Bird) => {
    if (!user) return;

    try {
      // Optimistic update
      setBirds(prev => prev.map(bird => 
        bird.id === updatedBird.id ? updatedBird : bird
      ));

      // Supabase'e gönder
      const { error } = await supabase
        .from('birds')
        .update({
          name: updatedBird.name,
          gender: updatedBird.gender,
          color: updatedBird.color || null,
          birth_date: updatedBird.birthDate || null,
          ring_number: updatedBird.ringNumber || null,
          photo_url: updatedBird.photo || null,
          health_notes: updatedBird.healthNotes || null,
          status: updatedBird.status || null,
          mother_id: updatedBird.motherId || null,
          father_id: updatedBird.fatherId || null,
        })
        .eq('id', updatedBird.id)
        .eq('user_id', user.id);

      if (error) {
        console.error('❌ Kuş güncellenirken hata:', error);
        // Hata durumunda optimistic update'i geri al
        setBirds(prev => prev.map(bird => 
          bird.id === updatedBird.id ? birds.find(b => b.id === updatedBird.id)! : bird
        ));
        throw error;
      }

      console.log('✅ Kuş başarıyla güncellendi:', updatedBird);

      if (error) {
        console.error('Kuş güncellenirken hata:', error);
        // Hata durumunda optimistic update'i geri al
        setBirds(prev => prev.map(bird => 
          bird.id === updatedBird.id ? birds.find(b => b.id === updatedBird.id)! : bird
        ));
        throw error;
      }
    } catch (error) {
      console.error('Kuş güncellenirken hata:', error);
      throw error;
    }
  }, [user, setBirds, birds]);

  return { editBird };
}; 