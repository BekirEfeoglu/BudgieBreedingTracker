import { useEffect, useRef, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';

export const useEggRealtime = (clutchId: string, onDataChange: () => void) => {
  const { user } = useAuth();
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const isSubscribedRef = useRef(false);

  // Memoize subscription cleanup
  const cleanup = useCallback(() => {
    if (channelRef.current && isSubscribedRef.current) {
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      isSubscribedRef.current = false;
    }
  }, []);

  useEffect(() => {
    if (!user?.id || !clutchId) {
      return;
    }

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      return;
    }
    
    const channel = supabase
      .channel(`eggs_changes_${clutchId}_${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'eggs',
          filter: `incubation_id=eq.${clutchId}`
        },
        () => {
          onDataChange();
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'eggs',
          filter: `incubation_id=eq.${clutchId}`
        },
        () => {
          onDataChange();
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'eggs',
          filter: `incubation_id=eq.${clutchId}`
        },
        () => {
          onDataChange();
        }
      )
      .subscribe((status, err) => {
        if (status === 'SUBSCRIBED') {
          isSubscribedRef.current = true;
        } else if (status === 'CHANNEL_ERROR') {
          isSubscribedRef.current = false;
          // Try to reconnect after a delay
          setTimeout(() => {
            if (channelRef.current) {
              cleanup();
            }
          }, 5000);
        } else if (status === 'CLOSED') {
          isSubscribedRef.current = false;
        }
      });

    channelRef.current = channel;

    return cleanup;
  }, [user?.id, clutchId, onDataChange, cleanup]);
};
