import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Egg } from '@/types';
import { useAuth } from '@/hooks/useAuth';

// Veritabanı verilerini Egg tipine dönüştür
const mapDatabaseEggToEgg = (dbEgg: any): Egg => ({
  id: dbEgg.id,
  breedingId: dbEgg.breeding_id || '',
  nestId: dbEgg.nest_id || undefined,
  layDate: dbEgg.hatch_date || '',
  status: (dbEgg.status as 'unknown' | 'laid' | 'fertile' | 'infertile' | 'hatched') || 'unknown',
  hatchDate: dbEgg.hatch_date || undefined,
  notes: dbEgg.notes || undefined,
  chickId: dbEgg.chick_id || undefined,
  number: dbEgg.number || 0,
  motherId: dbEgg.mother_id || undefined,
  fatherId: dbEgg.father_id || undefined,
  dateAdded: dbEgg.date_added || undefined,
});

export const useEggsData = () => {
  const [eggs, setEggs] = useState<Egg[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setEggs([]);
      setLoading(false);
      return;
    }

    const fetchEggs = async () => {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('eggs')
          .select('*')
          .eq('user_id', user.id)
          .order('hatch_date', { ascending: false });

        if (error) {
          console.error('Yumurtalar yüklenirken hata:', error);
          return;
        }

        setEggs((data || []).map(mapDatabaseEggToEgg));
      } catch (error) {
        console.error('Yumurtalar yüklenirken hata:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchEggs();

    // Realtime subscription
    const channel = supabase
      .channel('eggs_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'eggs',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setEggs(prev => [mapDatabaseEggToEgg(payload.new), ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            setEggs(prev => prev.map(egg => 
              egg.id === payload.new.id ? mapDatabaseEggToEgg(payload.new) : egg
            ));
          } else if (payload.eventType === 'DELETE') {
            setEggs(prev => prev.filter(egg => egg.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  return { eggs, setEggs, loading };
}; 