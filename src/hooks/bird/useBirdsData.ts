
import { useEffect, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useBirdData } from '@/hooks/bird/useBirdData';
import { useBirdRealtime } from '@/hooks/bird/useBirdRealtime';

export const useBirdsData = () => {
  const { user } = useAuth();
  const { birds, setBirds, loading, error, loadBirds } = useBirdData();

  // Memoize loadBirds to prevent unnecessary effect runs
  const memoizedLoadBirds = useCallback(() => {
    if (user?.id) {
      loadBirds();
    }
  }, [user?.id, loadBirds]);

  // Set up real-time subscription
  useBirdRealtime(setBirds);

  // Load data on mount and when user changes
  useEffect(() => {
    memoizedLoadBirds();
  }, [memoizedLoadBirds]);

  return {
    birds,
    setBirds,
    loading,
    error,
    refetch: memoizedLoadBirds
  };
};
