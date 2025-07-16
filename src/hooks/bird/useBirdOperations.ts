
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { useBirdCreate } from '@/hooks/bird/useBirdCreate';
import { useBirdUpdate } from '@/hooks/bird/useBirdUpdate';
import { useBirdDelete } from '@/hooks/bird/useBirdDelete';

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

export const useBirdOperations = (
  birds: Bird[],
  setBirds: (fn: (prev: Bird[]) => Bird[]) => void
) => {
  const { isOnline } = useSupabaseOperations();
  
  // Use the specialized hooks
  const { addBird } = useBirdCreate(setBirds);
  const { editBird } = useBirdUpdate(birds, setBirds);
  const { deleteBird } = useBirdDelete(birds, setBirds);

  return {
    addBird,
    editBird,
    deleteBird,
    isOnline
  };
};
