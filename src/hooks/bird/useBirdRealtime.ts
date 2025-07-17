import { useEffect, useRef, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { transformBird } from '@/utils/birdTransforms';
import { Bird } from '@/types';
import { Database } from '@/integrations/supabase/types';

type DatabaseBird = Database['public']['Tables']['birds']['Row'];

export const useBirdRealtime = (setBirds: React.Dispatch<React.SetStateAction<Bird[]>>) => {
  const { user } = useAuth();
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const isSubscribedRef = useRef(false);
  const processedEventsRef = useRef<Set<string>>(new Set());

  // Memoize subscription cleanup
  const cleanup = useCallback(() => {
    if (channelRef.current && isSubscribedRef.current) {
      console.log('🔌 Cleaning up bird realtime subscription');
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      isSubscribedRef.current = false;
      processedEventsRef.current.clear();
    }
  }, []);

  useEffect(() => {
    if (!user?.id) {
      console.log('👤 No user, skipping bird realtime subscription');
      return;
    }

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      console.log('🔄 Bird realtime subscription already active');
      return;
    }

    console.log('🔌 Setting up bird realtime subscription for user:', user.id);

    const channel = supabase
      .channel(`birds_user_${user.id}_${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'birds',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          try {
            // Create unique event ID to prevent duplicates
            const eventId = `${payload.eventType}_${(payload.old as any)?.id || (payload.new as any)?.id}_${payload.commit_timestamp}`;
            
            if (processedEventsRef.current.has(eventId)) {
              console.log('🔄 Duplicate event ignored:', eventId);
              return;
            }
            
            processedEventsRef.current.add(eventId);
            
            // Clean up old events (keep only last 100)
            if (processedEventsRef.current.size > 100) {
              const eventsArray = Array.from(processedEventsRef.current);
              processedEventsRef.current = new Set(eventsArray.slice(-50));
            }
            
            console.log('🔄 Bird realtime event:', payload.eventType, payload);
            
            if (payload.eventType === 'INSERT' && payload.new) {
              const newBird = transformBird(payload.new as DatabaseBird);
              setBirds(prev => {
                // Sadece ID kontrolü yap, optimistic update ile çakışmayı önle
                const existsById = prev.some(bird => bird.id === newBird.id);
                
                if (existsById) {
                  console.log('🔄 Bird already exists by ID, skipping insert:', newBird.name);
                  return prev;
                }
                
                // Eğer aynı isim ve cinsiyet varsa, muhtemelen optimistic update ile eklenmiş
                const existsByNameAndGender = prev.some(bird => 
                  bird.name === newBird.name && 
                  bird.gender === newBird.gender &&
                  bird.id !== newBird.id // Farklı ID'ler varsa ekle
                );
                
                if (existsByNameAndGender) {
                  console.log('🔄 Bird with same name and gender exists, but different ID, adding:', newBird.name);
                  return [newBird, ...prev];
                }
                
                console.log('🔄 Adding new bird via realtime:', newBird.name);
                return [newBird, ...prev];
              });
            } else if (payload.eventType === 'UPDATE' && payload.new) {
              const updatedBird = transformBird(payload.new as DatabaseBird);
              setBirds(prev => {
                const exists = prev.some(bird => bird.id === updatedBird.id);
                if (!exists) {
                  console.log('🔄 Updated bird not found in local state, adding:', updatedBird.name);
                  return [updatedBird, ...prev];
                }
                console.log('🔄 Updating bird via realtime:', updatedBird.name);
                return prev.map(bird => 
                  bird.id === updatedBird.id ? updatedBird : bird
                );
              });
            } else if (payload.eventType === 'DELETE' && payload.old) {
              console.log('🔄 Deleting bird via realtime:', payload.old.id);
              setBirds(prev => prev.filter(bird => bird.id !== payload.old.id));
            }
          } catch (error) {
            console.error('❌ Error processing bird realtime event:', error);
          }
        }
      )
      .subscribe((status, err) => {
        console.log('🔌 Bird realtime subscription status:', status);
        if (status === 'SUBSCRIBED') {
          isSubscribedRef.current = true;
          console.log('✅ Bird realtime subscription active');
        } else if (status === 'CHANNEL_ERROR') {
          isSubscribedRef.current = false;
          console.error('❌ Bird realtime channel error:', err);
          // Try to reconnect after a delay
          setTimeout(() => {
            if (channelRef.current) {
              cleanup();
            }
          }, 5000);
        } else if (status === 'CLOSED') {
          isSubscribedRef.current = false;
          console.log('🔌 Bird realtime subscription closed');
        }
      });

    channelRef.current = channel;

    return cleanup;
  }, [user?.id, setBirds, cleanup]);
};
