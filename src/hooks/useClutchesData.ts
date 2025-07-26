import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Breeding } from '@/types';
import { useAuth } from '@/hooks/useAuth';

// Veritabanı verilerini Breeding tipine dönüştür
const mapDatabaseBreedingToBreeding = (dbBreeding: any): Breeding => ({
  id: dbBreeding.id,
  maleBirdId: dbBreeding.male_bird_id || '',
  femaleBirdId: dbBreeding.female_bird_id || '',
  pairDate: dbBreeding.pair_date || '',
  expectedHatchDate: dbBreeding.expected_hatch_date || undefined,
  notes: dbBreeding.notes || undefined,
  eggs: dbBreeding.eggs || undefined,
  maleBird: dbBreeding.male_bird || undefined,
  femaleBird: dbBreeding.female_bird || undefined,
  nestName: dbBreeding.nest_name || undefined,
  nestId: dbBreeding.nest_id || undefined,
});

export const useClutchesData = () => {
  const [clutches, setClutches] = useState<Breeding[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setClutches([]);
      setLoading(false);
      return;
    }

    const fetchClutches = async () => {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('clutches')
          .select('*')
          .eq('user_id', user.id)
          .order('pair_date', { ascending: false });

        if (error) {
          console.error('Kuluçkalar yüklenirken hata:', error);
          return;
        }

        setClutches((data || []).map(mapDatabaseBreedingToBreeding));
      } catch (error) {
        console.error('Kuluçkalar yüklenirken hata:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchClutches();

    // Realtime subscription
    const channel = supabase
      .channel('clutches_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'clutches',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setClutches(prev => [mapDatabaseBreedingToBreeding(payload.new), ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            setClutches(prev => prev.map(clutch => 
              clutch.id === payload.new.id ? mapDatabaseBreedingToBreeding(payload.new) : clutch
            ));
          } else if (payload.eventType === 'DELETE') {
            setClutches(prev => prev.filter(clutch => clutch.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return { clutches, setClutches, loading };
}; 