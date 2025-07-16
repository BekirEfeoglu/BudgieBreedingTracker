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

export const useBirdCreate = (
  setBirds: (fn: (prev: Bird[]) => Bird[]) => void
) => {
  const { toast } = useToast();
  const { insertRecord } = useSupabaseOperations();

  const addBird = async (birdData: Omit<Bird, 'id'>) => {
    try {
      // Validation
      const validation = validateBirdData(birdData);
      if (!validation.isValid) {
        toast({
          title: 'Hata',
          description: validation.error,
          variant: 'destructive'
        });
        return;
      }

      // Generate unique ID and create new bird
      const newBirdId = crypto.randomUUID();
      const newBird: Bird = {
        ...birdData,
        id: newBirdId,
        name: birdData.name.trim()
      };
      
      // Prepare database data
      const dbData = prepareBirdForDatabase(newBird);

      // Optimistic update - immediately add to local state
      setBirds(prev => {
        const updated = [newBird, ...prev];
        return updated;
      });

      const result = await insertRecord('birds', dbData);
      
      if (result.success && !result.queued) {
        toast({
          title: 'Başarılı',
          description: `"${birdData.name}" adlı kuş başarıyla eklendi.`,
        });
      } else if (result.queued) {
        toast({
          title: 'Çevrimdışı Mod',
          description: `"${birdData.name}" çevrimdışı olarak kaydedildi ve bağlantı kurulduğunda senkronize edilecek.`,
        });
      } else {
        // Revert optimistic update on failure
        setBirds(prev => prev.filter(bird => bird.id !== newBird.id));
        toast({
          title: 'Hata',
          description: 'Kuş eklenirken bir hata oluştu. Tekrar deneyin.',
          variant: 'destructive'
        });
      }
      
    } catch (_error) {
      toast({
        title: 'Hata',
        description: 'Kuş eklenirken beklenmeyen bir hata oluştu.',
        variant: 'destructive'
      });
    }
  };

  return { addBird };
};
