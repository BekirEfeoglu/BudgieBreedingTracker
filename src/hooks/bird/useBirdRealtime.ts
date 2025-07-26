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
  const optimisticUpdatesRef = useRef<Set<string>>(new Set()); // Optimistic update'leri takip et

  // Memoize subscription cleanup
  const cleanup = useCallback(() => {
    if (channelRef.current && isSubscribedRef.current) {
      console.log('🔌 Cleaning up bird realtime subscription');
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      isSubscribedRef.current = false;
      processedEventsRef.current.clear();
      optimisticUpdatesRef.current.clear();
      setGlobalSubscriptionActive(false);
    }
  }, []);

  // Optimistic update'leri takip etmek için fonksiyon
  const trackOptimisticUpdate = useCallback((birdId: string) => {
    optimisticUpdatesRef.current.add(birdId);
    // 5 saniye sonra optimistic update'i temizle
    setTimeout(() => {
      optimisticUpdatesRef.current.delete(birdId);
    }, 5000);
  }, []);

  // Optimistic update kontrolü
  const isOptimisticUpdate = useCallback((birdId: string) => {
    return optimisticUpdatesRef.current.has(birdId);
  }, []);

  useEffect(() => {
    if (!user?.id) {
      console.log('👤 No user, skipping bird realtime subscription');
      return;
    }

    // Global subscription kontrolü
    if (globalSubscriptionActive) {
      console.log('🔄 Global subscription already active, skipping');
      return;
    }

    // Prevent duplicate subscriptions
    if (isSubscribedRef.current) {
      console.log('🔄 Bird realtime subscription already active');
      return;
    }

    console.log('🔌 Setting up bird realtime subscription for user:', user.id);
    setGlobalSubscriptionActive(true);

    // Önceki subscription'ı temizle
    if (channelRef.current) {
      console.log('🧹 Cleaning up previous subscription');
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      isSubscribedRef.current = false;
    }

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
            
            // Daha güçlü duplicate kontrolü - son 10 saniyede aynı event'i kontrol et
            const now = Date.now();
            const recentEvents = Array.from(processedEventsRef.current).filter(eventKey => {
              const eventTime = eventKey.split('_').pop(); // timestamp'i al
              if (eventTime) {
                const eventTimestamp = new Date(eventTime).getTime();
                return Math.abs(now - eventTimestamp) < 10000; // 10 saniye
              }
              return false;
            });
            
            // Aynı event tipi ve ID varsa duplicate olarak kabul et
            const sameEventExists = recentEvents.some(eventKey => {
              const eventParts = eventKey.split('_');
              const currentEventParts = eventId.split('_');
              return eventParts[0] === currentEventParts[0] && // event type
                     eventParts[1] === currentEventParts[1];   // ID
            });
            
            if (sameEventExists) {
              console.log('🔄 Recent duplicate event detected, ignoring:', eventId);
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
              
              // Optimistic update kontrolü
              if (isOptimisticUpdate(newBird.id)) {
                console.log('🔄 Optimistic update detected for bird:', newBird.name, 'skipping realtime insert');
                return;
              }
              
              setBirds(prev => {
                // ID kontrolü - en güvenli yöntem
                const existsById = prev.some(bird => bird.id === newBird.id);
                
                if (existsById) {
                  console.log('🔄 Bird already exists by ID, skipping insert:', newBird.name);
                  return prev;
                }
                
                // İsim ve cinsiyet kontrolü - aynı anda eklenen kuşları önle
                const existsByNameAndGender = prev.some(bird => 
                  bird.name.toLowerCase() === newBird.name.toLowerCase() && 
                  bird.gender === newBird.gender
                );
                
                if (existsByNameAndGender) {
                  console.log('🔄 Bird with same name and gender already exists, skipping:', newBird.name);
                  return prev;
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
          
          // Binding uyumsuzluğu hatası için özel işlem
          if (err?.message?.includes('mismatch between server and client bindings')) {
            console.log('🔄 Binding mismatch detected, cleaning up and retrying...');
            // Tüm subscription'ları temizle ve yeniden başlat
            setTimeout(() => {
              cleanup();
              // Component yeniden mount olacak ve subscription tekrar başlayacak
            }, 2000);
          } else {
            // Diğer hatalar için normal retry
            setTimeout(() => {
              if (channelRef.current) {
                cleanup();
              }
            }, 5000);
          }
        } else if (status === 'CLOSED') {
          isSubscribedRef.current = false;
          console.log('🔌 Bird realtime subscription closed');
        }
      });

    channelRef.current = channel;

    return cleanup;
  }, [user?.id, setBirds, cleanup]);
};

// Optimistic update'leri takip etmek için global fonksiyon
let optimisticUpdateTracker: ((birdId: string) => void) | null = null;
let globalSubscriptionActive = false;

export const setOptimisticUpdateTracker = (tracker: (birdId: string) => void) => {
  optimisticUpdateTracker = tracker;
};

export const trackBirdOptimisticUpdate = (birdId: string) => {
  if (optimisticUpdateTracker) {
    optimisticUpdateTracker(birdId);
  }
};

// Global subscription kontrolü
export const isGlobalSubscriptionActive = () => globalSubscriptionActive;
export const setGlobalSubscriptionActive = (active: boolean) => {
  globalSubscriptionActive = active;
};
