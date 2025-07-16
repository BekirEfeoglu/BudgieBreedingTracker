import { useToast } from '@/hooks/use-toast';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { validateBirdData, prepareBirdForDatabase } from '@/utils/birdValidation';

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

export const useBirdUpdate = (
  birds: Bird[],
  setBirds: (fn: (prev: Bird[]) => Bird[]) => void
) => {
  const { toast } = useToast();
  const { updateRecord } = useSupabaseOperations();

  const editBird = async (updatedBird: Bird) => {
    try {
      // Validation
      const validation = validateBirdData(updatedBird);
      if (!validation.isValid) {
        toast({
          title: 'Hata',
          description: validation.error,
          variant: 'destructive'
        });
        return;
      }

      const dbData = prepareBirdForDatabase(updatedBird);

      // Optimistic update
      const previousBird = birds.find(b => b.id === updatedBird.id);
      setBirds(prev => prev.map(bird => 
        bird.id === updatedBird.id ? updatedBird : bird
      ));

      const result = await updateRecord('birds', dbData);
      
      if (result.success && !result.queued) {
        toast({
          title: 'Başarılı',
          description: `"${updatedBird.name}" adlı kuş başarıyla güncellendi.`,
        });
      } else if (result.queued) {
        toast({
          title: 'Çevrimdışı Mod',
          description: `"${updatedBird.name}" çevrimdışı olarak güncellendi.`,
        });
      } else {
        // Revert optimistic update on failure
        if (previousBird) {
          setBirds(prev => prev.map(bird => 
            bird.id === updatedBird.id ? previousBird : bird
          ));
        }
        toast({
          title: 'Hata',
          description: 'Kuş güncellenirken bir hata oluştu.',
          variant: 'destructive'
        });
      }
      
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Kuş güncellenirken beklenmeyen bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  return { editBird };
};
