import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { EggWithClutch } from '@/types/egg';

export const useEggData = (breedingId?: string) => {
  const { user } = useAuth();
  const [eggs, setEggs] = useState<EggWithClutch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const subscriptionRef = useRef<any>(null);

  const fetchEggs = useCallback(async () => {
    if (!user) {
      setEggs([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      let query = supabase
        .from('eggs')
        .select(`
          *,
          incubations (
            id,
            name,
            start_date,
            female_bird_id,
            male_bird_id,
            notes
          )
        `)
        .eq('user_id', user.id)
        .or('is_deleted.is.null,is_deleted.eq.false'); // Get non-deleted eggs

      // If breedingId is provided, filter by that specific breeding
      if (breedingId) {
        query = query.eq('incubation_id', breedingId);
      }

      const { data, error } = await query.order('created_at', { ascending: false });

      if (error) {
        setError(error.message);
        setEggs([]);
      } else {
        const mappedEggs = (data || []).map(egg => ({
          id: egg.id,
          clutchId: egg.incubation_id || '',
          eggNumber: egg.egg_number || 0,
          startDate: egg.hatch_date || '',
          status: egg.status || 'laid',
          notes: egg.notes || '',
          createdAt: egg.created_at || '',
          updatedAt: egg.updated_at || '',
          clutch: egg.incubations ? {
            id: egg.incubations.id,
            name: egg.incubations.name || '',
            startDate: egg.incubations.start_date || '',
            femaleBirdId: egg.incubations.female_bird_id || '',
            maleBirdId: egg.incubations.male_bird_id || '',
            notes: egg.incubations.notes || ''
          } : null
        }));

        setEggs(mappedEggs);
      }
    } catch (err) {
      setError('Yumurtalar yüklenirken bir hata oluştu');
      setEggs([]);
    } finally {
      setLoading(false);
    }
  }, [user, breedingId]);

  const refetchEggs = useCallback(() => {
    fetchEggs();
  }, [fetchEggs]);

  useEffect(() => {
    fetchEggs();
  }, [fetchEggs]);

  // Realtime subscription
  useEffect(() => {
    if (!user) {
      return;
    }

    // Clean up existing subscription
    if (subscriptionRef.current) {
      supabase.removeChannel(subscriptionRef.current);
    }

            const channel = supabase
          .channel('eggs_changes')
          .on(
            'postgres_changes',
            {
              event: '*',
              schema: 'public',
              table: 'eggs',
              filter: breedingId 
                ? `user_id=eq.${user.id} AND incubation_id=eq.${breedingId} AND (is_deleted=is.null OR is_deleted=eq.false)`
                : `user_id=eq.${user.id} AND (is_deleted=is.null OR is_deleted=eq.false)`
            },
        (payload) => {
          if (payload.eventType === 'INSERT' && payload.new) {
            setEggs(prev => {
              const newEgg: EggWithClutch = {
                id: payload.new.id,
                clutchId: payload.new.incubation_id || '',
                eggNumber: payload.new.egg_number || 0,
                startDate: payload.new.hatch_date || '',
                status: payload.new.status || 'laid',
                notes: payload.new.notes || undefined,
                createdAt: payload.new.created_at || '',
                updatedAt: payload.new.updated_at || '',
                clutch: null // Clutch bilgisi ayrıca yüklenmeli
              };
              return [newEgg, ...prev];
            });
          } else if (payload.eventType === 'UPDATE' && payload.new) {
            setEggs(prev => prev.map(egg => 
              egg.id === payload.new.id ? {
                ...egg,
                clutchId: payload.new.incubation_id || egg.clutchId,
                eggNumber: payload.new.egg_number || egg.eggNumber,
                startDate: payload.new.hatch_date || egg.startDate,
                status: payload.new.status || egg.status,
                notes: payload.new.notes || egg.notes,
                updatedAt: payload.new.updated_at || egg.updatedAt
              } : egg
            ));
          } else if (payload.eventType === 'DELETE' && payload.old) {
            setEggs(prev => prev.filter(egg => egg.id !== payload.old?.id));
          }
        }
      )
      .subscribe();

    subscriptionRef.current = channel;

    return () => {
      if (subscriptionRef.current) {
        supabase.removeChannel(subscriptionRef.current);
        subscriptionRef.current = null;
      }
    };
  }, [user, breedingId]);

  return {
    eggs,
    loading,
    error,
    refetchEggs
  };
}; 