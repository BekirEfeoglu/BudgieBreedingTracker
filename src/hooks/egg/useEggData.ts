import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { EggWithClutch } from '@/types/egg';

export const useEggData = (incubationId: string) => {
  const [eggs, setEggs] = useState<EggWithClutch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const { toast } = useToast();

  // Use refs to avoid circular dependencies in useCallback
  const incubationIdRef = useRef(incubationId);
  const userIdRef = useRef(user?.id);
  const isSubscribedRef = useRef(false);

  // Update refs when values change
  useEffect(() => {
    incubationIdRef.current = incubationId;
  }, [incubationId]);

  useEffect(() => {
    userIdRef.current = user?.id;
  }, [user?.id]);

  // Transform database egg to application egg
  const transformEgg = useCallback((dbEgg: Record<string, unknown>): EggWithClutch => {
    return {
      id: dbEgg.id as string,
      clutchId: dbEgg.incubation_id as string,
      eggNumber: dbEgg.egg_number as number,
      layDate: dbEgg.lay_date as string,
      startDate: new Date(dbEgg.lay_date as string || new Date()),
      status: dbEgg.status as string || 'laid',
      hatchDate: dbEgg.hatch_date as string,
      notes: dbEgg.notes as string || '',
      createdAt: dbEgg.created_at as string,
      updatedAt: dbEgg.updated_at as string
    };
  }, []);

  // Load eggs for incubation - using refs to avoid dependencies issue
  const loadEggs = useCallback(async () => {
    const currentIncubationId = incubationIdRef.current;
    const currentUserId = userIdRef.current;
    
    if (!currentUserId) {
      setEggs([]);
      setLoading(false);
      setError('User not authenticated');
      return;
    }

    if (!currentIncubationId || typeof currentIncubationId !== 'string' || currentIncubationId.trim().length === 0) {
      setEggs([]);
      setLoading(false);
      setError('Invalid incubation ID');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      // Filter out soft-deleted eggs
      const { data, error: queryError } = await supabase
        .from('eggs')
        .select('*')
        .eq('incubation_id', currentIncubationId)
        .eq('user_id', currentUserId)
        .eq('is_deleted', false)
        .order('egg_number', { ascending: true });

      if (queryError) {
        setError(queryError.message);
        toast({
          title: 'Hata',
          description: 'Yumurta verileri yüklenirken bir hata oluştu.',
          variant: 'destructive'
        });
        setEggs([]);
        return;
      }

      const transformedEggs = data ? data.map(transformEgg) : [];
      setEggs(transformedEggs);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Bilinmeyen hata';
      setError(errorMessage);
      toast({
        title: 'Hata',
        description: 'Yumurta verileri yüklenirken bir hata oluştu.',
        variant: 'destructive'
      });
      setEggs([]);
    } finally {
      setLoading(false);
    }
  }, [transformEgg, toast]);

  // Load eggs when hook mounts or key values change
  useEffect(() => {
    loadEggs();
  }, [incubationId, user?.id, loadEggs]);

  // Set up real-time subscription - separate effect to avoid dependency issues
  useEffect(() => {
    if (!user?.id || !incubationId) {
      return;
    }

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      return;
    }
    
    const channelName = `eggs_${incubationId}_${user.id}_${Date.now()}`;
    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',  
          table: 'eggs',
          filter: `incubation_id=eq.${incubationId}`
        },
        (payload) => {
          // Always reload eggs to ensure consistency
          loadEggs();
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          isSubscribedRef.current = true;
        } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
          isSubscribedRef.current = false;
        }
      });

    return () => {
      supabase.removeChannel(channel);
      isSubscribedRef.current = false;
    };
  }, [user?.id, incubationId, loadEggs]);

  return {
    eggs,
    loading,
    error,
    refetch: loadEggs
  };
};
