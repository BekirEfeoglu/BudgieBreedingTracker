import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';

export interface Incubation {
  id: string;
  name: string;
  startDate: string;
  endDate?: string;
  status: 'active' | 'completed' | 'cancelled';
  notes?: string;
  userId: string;
  maleBirdId?: string;
  femaleBirdId?: string;
}

// Veritabanı verilerini Incubation tipine dönüştür
const mapDatabaseIncubationToIncubation = (dbIncubation: any): Incubation => ({
  id: dbIncubation.id,
  name: dbIncubation.name || '',
  startDate: dbIncubation.start_date || '',
  endDate: dbIncubation.end_date || undefined,
  status: (dbIncubation.status as 'active' | 'completed' | 'cancelled') || 'active',
  notes: dbIncubation.notes || undefined,
  userId: dbIncubation.user_id || '',
  maleBirdId: dbIncubation.male_bird_id || undefined,
  femaleBirdId: dbIncubation.female_bird_id || undefined,
});

export const useIncubationData = () => {
  const [incubations, setIncubations] = useState<Incubation[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  // Reduced logging for performance

  useEffect(() => {
    if (!user) {
      // Reduced logging for performance
      setIncubations([]);
      setLoading(false);
      return;
    }

    const fetchIncubations = async () => {
      // Reduced logging for performance
      try {
        setLoading(true);
        const { data, error } = await supabase
          .from('incubations')
          .select('*')
          .eq('user_id', user.id)
          .order('start_date', { ascending: false });

        if (error) {
          console.error('❌ useIncubationData.fetchIncubations - Veri yükleme hatası:', error);
          return;
        }

        // Reduced logging for performance

        setIncubations((data || []).map(mapDatabaseIncubationToIncubation));
      } catch (error) {
        console.error('💥 useIncubationData.fetchIncubations - Beklenmedik hata:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchIncubations();

    // Realtime subscription
    // Reduced logging for performance
    const channel = supabase
      .channel('incubations_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'incubations',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          // Reduced logging for performance

          if (payload.eventType === 'INSERT' && payload.new) {
            // Reduced logging for performance
            setIncubations(prev => [mapDatabaseIncubationToIncubation(payload.new), ...prev]);
          } else if (payload.eventType === 'UPDATE' && payload.new) {
            // Reduced logging for performance
            setIncubations(prev => prev.map(incubation => 
              incubation.id === payload.new.id ? mapDatabaseIncubationToIncubation(payload.new) : incubation
            ));
          } else if (payload.eventType === 'DELETE' && payload.old && 'id' in payload.old) {
            // Reduced logging for performance
            setIncubations(prev => {
              // Check if incubation already removed to prevent unnecessary re-renders
              const exists = prev.some(incubation => incubation.id === (payload.old as { id: string }).id);
              if (!exists) {
                return prev; // Already removed, no need to filter again
              }
              return prev.filter(incubation => incubation.id !== (payload.old as { id: string }).id);
            });
          }
        }
      )
      .subscribe((status) => {
        // Reduced logging for performance
      });

    return () => {
      // Reduced logging for performance
      supabase.removeChannel(channel);
    };
  }, [user]);

  // Optimistic delete function for instant UI feedback
  const optimisticDelete = useCallback((incubationId: string) => {
    setIncubations(prev => prev.filter(incubation => incubation.id !== incubationId));
  }, []);

  return { incubations, setIncubations, loading, optimisticDelete };
}; 