import { Bird } from '@/types';
import { Database } from '@/integrations/supabase/types';

type DatabaseBird = Database['public']['Tables']['birds']['Row'];

export const transformBird = (dbBird: DatabaseBird): Bird => {
  try {
    const transformed: Bird = {
      id: dbBird.id,
      name: dbBird.name || 'İsimsiz Kuş',
      gender: (dbBird.gender as 'male' | 'female' | 'unknown') || 'unknown',
      ...(dbBird.color && { color: dbBird.color }),
      ...(dbBird.birth_date && { birthDate: dbBird.birth_date }),
      ...(dbBird.ring_number && { ringNumber: dbBird.ring_number }),
      ...(dbBird.photo_url && { photo: dbBird.photo_url }),
      ...(dbBird.health_notes && { healthNotes: dbBird.health_notes }),
      ...(dbBird.mother_id && { motherId: dbBird.mother_id }),
      ...(dbBird.father_id && { fatherId: dbBird.father_id }),
    };
    
    return transformed;
  } catch (error) {
    // Log error in development only
    if (typeof window !== 'undefined' && window.location.hostname === 'localhost') {
      console.error('Error transforming bird:', error, dbBird);
    }
    
    return {
      id: dbBird.id || crypto.randomUUID(),
      name: 'Hatalı Kuş',
      gender: 'unknown'
    };
  }
};
