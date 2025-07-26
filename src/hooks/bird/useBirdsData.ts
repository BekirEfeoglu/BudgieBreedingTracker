import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Bird } from '@/types';
import { useAuth } from '@/hooks/useAuth';

// Veritabanı verilerini Bird tipine dönüştür
const mapDatabaseBirdToBird = (dbBird: any): Bird => ({
  id: dbBird.id,
  name: dbBird.name || '',
  gender: (dbBird.gender as 'male' | 'female' | 'unknown') || 'unknown',
  color: dbBird.color || undefined,
  birthDate: dbBird.birth_date || undefined,
  ringNumber: dbBird.ring_number || undefined,
  photo: dbBird.photo_url || undefined,
  healthNotes: dbBird.health_notes || undefined,
  status: dbBird.status || undefined,
  motherId: dbBird.mother_id || undefined,
  fatherId: dbBird.father_id || undefined,
});

export const useBirdsData = () => {
  const [birds, setBirds] = useState<Bird[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setBirds([]);
      setLoading(false);
      return;
    }

    const fetchBirds = async () => {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('birds')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false });

        if (error) {
          console.error('Kuşlar yüklenirken hata:', error);
          return;
        }

        setBirds((data || []).map(mapDatabaseBirdToBird));
      } catch (error) {
        console.error('Kuşlar yüklenirken hata:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchBirds();

    // Realtime subscription
    const channel = supabase
      .channel('birds_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'birds',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setBirds(prev => {
              // Check if bird already exists to prevent duplicates
              const exists = prev.some(bird => bird.id === payload.new.id);
              if (exists) {
                // Reduced logging for performance
                return prev;
              }
              return [mapDatabaseBirdToBird(payload.new), ...prev];
            });
          } else if (payload.eventType === 'UPDATE') {
            setBirds(prev => prev.map(bird => 
              bird.id === payload.new.id ? mapDatabaseBirdToBird(payload.new) : bird
            ));
          } else if (payload.eventType === 'DELETE') {
            setBirds(prev => prev.filter(bird => bird.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return { birds, setBirds, loading };
}; 