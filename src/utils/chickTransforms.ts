import { Chick } from '@/types';
import { Database } from '@/integrations/supabase/types';

type DatabaseChick = Database['public']['Tables']['chicks']['Row'];

export const transformChick = (dbChick: DatabaseChick): Chick => ({
  id: dbChick.id,
  name: dbChick.name || 'İsimsiz Yavru',
  breedingId: dbChick.incubation_id || dbChick.clutch_id || '',
  hatchDate: dbChick.hatch_date || '',
  gender: (dbChick.gender as 'male' | 'female' | 'unknown') || 'unknown',
  ...(dbChick.egg_id && { eggId: dbChick.egg_id }),
  ...(dbChick.color && { color: dbChick.color }),
  ...(dbChick.ring_number && { ringNumber: dbChick.ring_number }),
  ...(dbChick.photo_url && { photo: dbChick.photo_url }),
  ...(dbChick.health_notes && { healthNotes: dbChick.health_notes }),
  ...(dbChick.mother_id && { motherId: dbChick.mother_id }),
  ...(dbChick.father_id && { fatherId: dbChick.father_id }),
});
