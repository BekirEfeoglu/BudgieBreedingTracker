import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Chick } from '@/types';
import { useAuth } from '@/hooks/useAuth';

// Veritabanı verilerini Chick tipine dönüştür
const mapDatabaseChickToChick = (dbChick: any): Chick => ({
  id: dbChick.id,
  name: dbChick.name || '',
  breedingId: dbChick.breeding_id || '',
  eggId: dbChick.egg_id || undefined,
  egg_id: dbChick.egg_id || undefined,
  incubationId: dbChick.incubation_id || undefined,
  incubation_id: dbChick.incubation_id || undefined,
  incubationName: dbChick.incubation_name || undefined,
  eggNumber: dbChick.egg_number || undefined,
  hatchDate: dbChick.hatch_date || '',
  hatch_date: dbChick.hatch_date || '',
  gender: (dbChick.gender as 'male' | 'female' | 'unknown') || 'unknown',
  color: dbChick.color || undefined,
  ringNumber: dbChick.ring_number || undefined,
  ring_number: dbChick.ring_number || undefined,
  photo: dbChick.photo_url || undefined,
  healthNotes: dbChick.health_notes || undefined,
  health_notes: dbChick.health_notes || undefined,
  motherId: dbChick.mother_id || undefined,
  mother_id: dbChick.mother_id || undefined,
  fatherId: dbChick.father_id || undefined,
  father_id: dbChick.father_id || undefined,
});

export const useChicksData = () => {
  const [chicks, setChicks] = useState<Chick[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  // Optimistic add function for instant UI feedback
  const optimisticAdd = (newChick: Chick) => {
    setChicks(prev => {
      // Check if chick already exists to prevent duplicates
      const exists = prev.some(chick => chick.id === newChick.id);
      if (exists) {
        return prev; // Already exists, don't add again
      }
      return [newChick, ...prev];
    });
  };

  const fetchChicks = async () => {
    if (!user) {
      console.error('❌ fetchChicks - Kullanıcı girişi yok');
      return;
    }
    
    try {
      setLoading(true);
      // Reduced logging for performance
      
      const { data, error } = await supabase
        .from('chicks')
        .select('*')
        .eq('user_id', user.id)
        .order('hatch_date', { ascending: false });

      if (error) {
        console.error('❌ Civcivler yüklenirken hata:', error);
        return;
      }

      const mappedChicks = (data || []).map(mapDatabaseChickToChick);
      // Reduced logging for performance
      
      setChicks(mappedChicks);
    } catch (error) {
      console.error('❌ Civcivler yüklenirken hata:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!user) {
      setChicks([]);
      setLoading(false);
      return;
    }

    fetchChicks();

    // Realtime subscription
    const channel = supabase
      .channel('chicks_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'chicks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          // Reduced logging for performance
          
          if (payload.eventType === 'INSERT') {
            setChicks(prev => {
              const newChick = mapDatabaseChickToChick(payload.new);
              // Check if chick already exists to prevent duplicates
              const exists = prev.some(chick => chick.id === newChick.id);
              if (exists) {
                return prev; // Already exists, don't add again
              }
              return [newChick, ...prev];
            });
          } else if (payload.eventType === 'UPDATE') {
            setChicks(prev => prev.map(chick => 
              chick.id === payload.new.id ? mapDatabaseChickToChick(payload.new) : chick
            ));
          } else if (payload.eventType === 'DELETE') {
            setChicks(prev => prev.filter(chick => chick.id !== payload.old?.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return { chicks, setChicks, loading, refetchChicks: fetchChicks, optimisticAdd };
}; 