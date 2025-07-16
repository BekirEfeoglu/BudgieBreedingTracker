import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { transformChick } from '@/utils/chickTransforms';
import { Chick } from '@/types';
import { useChickRealtime } from './useChickRealtime';

export const useChicksData = () => {
  const [chicks, setChicks] = useState<Chick[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();

  // Fetch chicks data
  const fetchChicks = useCallback(async () => {
    if (!user?.id) {
      setChicks([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const { data, error: fetchError } = await supabase
        .from('chicks')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (fetchError) {
        setError(fetchError.message);
        return;
      }

      const transformedChicks = data.map(transformChick);
      setChicks(transformedChicks);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Beklenmeyen bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }, [user?.id]);

  // Initial data fetch
  useEffect(() => {
    fetchChicks();
  }, [fetchChicks]);

  // Set up real-time subscription
  useChickRealtime(setChicks);

  // Manual refresh function
  const refreshChicks = useCallback(async () => {
    await fetchChicks();
  }, [fetchChicks]);

  return {
    chicks,
    loading,
    error,
    refreshChicks,
    setChicks
  };
};
