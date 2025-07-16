import { useEffect, useRef, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { transformChick } from '@/utils/chickTransforms';
import { Chick } from '@/types';
import { Database } from '@/integrations/supabase/types';

type DatabaseChick = Database['public']['Tables']['chicks']['Row'];

export const useChickRealtime = (setChicks: React.Dispatch<React.SetStateAction<Chick[]>>) => {
  const { user } = useAuth();
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const isSubscribedRef = useRef(false);
  const processedDeletesRef = useRef<Set<string>>(new Set());

  // Memoize subscription cleanup
  const cleanup = useCallback(() => {
    if (channelRef.current && isSubscribedRef.current) {
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      isSubscribedRef.current = false;
    }
    // Clear processed deletes
    processedDeletesRef.current.clear();
  }, []);

  useEffect(() => {
    if (!user?.id) {
      return;
    }

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      return;
    }
    
    const channel = supabase
      .channel(`chicks_changes_${user.id}_${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'chicks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          try {
            // Validate payload structure
            if (!payload.new || typeof payload.new !== 'object') {
              return;
            }
            
            const newChick = transformChick(payload.new as DatabaseChick);
            setChicks(prev => {
              const exists = prev.some(chick => chick.id === newChick.id);
              if (exists) {
                return prev;
              }
              return [newChick, ...prev];
            });
          } catch (_error) {
            // Hata sessizce yutuluyor
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'chicks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          try {
            // Validate payload structure
            if (!payload.new || typeof payload.new !== 'object') {
              return;
            }
            
            const updatedChick = transformChick(payload.new as DatabaseChick);
            setChicks(prev => {
              const updated = prev.map(chick => 
                chick.id === updatedChick.id ? updatedChick : chick
              );
              return updated;
            });
          } catch (_error) {
            // Hata sessizce yutuluyor
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'chicks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const chickId = payload.old?.id;
          
          // Prevent duplicate DELETE processing
          if (chickId && processedDeletesRef.current.has(chickId)) {
            return;
          }
          
          if (chickId) {
            processedDeletesRef.current.add(chickId);
            
            // Clean up processed delete after 5 seconds
            setTimeout(() => {
              processedDeletesRef.current.delete(chickId);
            }, 5000);
          }
          
          setChicks(prev => {
            const filtered = prev.filter(chick => chick.id !== chickId);
            return filtered;
          });
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
        } else if (status === 'TIMED_OUT') {
          isSubscribedRef.current = false;
        }
      });

    channelRef.current = channel;

    return cleanup;
  }, [user?.id, setChicks, cleanup]);

  // Manual refresh function (can be called from parent components)
  const refreshChicks = useCallback(async () => {
    if (!user?.id) return;
    
    try {
      const { data, error } = await supabase
        .from('chicks')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
      
      if (error) {
        return;
      }
      
      const transformedChicks = data.map(transformChick);
      setChicks(transformedChicks);
    } catch (_error) {
      // Hata sessizce yutuluyor
    }
  }, [user?.id, setChicks]);

  // Expose refresh function
  return { refreshChicks };
};
