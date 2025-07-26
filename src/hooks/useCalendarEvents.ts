import { useMemo, useCallback, useState, useEffect } from 'react';
import { Event } from '@/types/calendar';
import { useEggsData } from '@/hooks/useEggsData';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { useIncubationData } from '@/hooks/useIncubationData';
import { useBirdsData } from '@/hooks/bird/useBirdsData';
import { useBackupOperations } from '@/hooks/backup/useBackupOperations';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';

export const useCalendarEvents = () => {
  const { eggs, loading: eggsLoading } = useEggsData();
  const { chicks, loading: chicksLoading } = useChicksData();
  const { incubations, loading: incubationsLoading } = useIncubationData();
  const { birds, loading: birdsLoading } = useBirdsData();
  const { getBackupList } = useBackupOperations();
  const { user } = useAuth();

  // State for custom events
  const [customEvents, setCustomEvents] = useState<Event[]>([]);
  const [backupEvents, setBackupEvents] = useState<Event[]>([]);
  const [supabaseEvents, setSupabaseEvents] = useState<Event[]>([]);
  const [loadingSupabaseEvents, setLoadingSupabaseEvents] = useState(false);

  // Combine all loading states
  const loading = eggsLoading || chicksLoading || incubationsLoading || birdsLoading || loadingSupabaseEvents;

  // Load backup events
  useEffect(() => {
    const loadBackupEvents = async () => {
      try {
        const result = await getBackupList();
        if (result.success && result.data) {
          const events: Event[] = [];
          result.data.forEach((backup: any, index: number) => {
            if (backup.date) {
              const backupDate = new Date(backup.date).toISOString().split('T')[0];
              if (backupDate) {
                events.push({
                  id: Date.now() + index,
                  date: backupDate,
                  title: `Veri Yedeklemesi - ${backup.name}`,
                  description: `${backup.size} boyutunda ${backup.type === 'auto' ? 'otomatik' : 'manuel'} yedekleme`,
                  type: 'backup',
                  icon: '💾',
                  color: 'bg-blue-100 text-blue-800 border-blue-200',
                  status: 'completed'
                });
              }
            }
          });
          setBackupEvents(events);
        }
      } catch (error) {
        console.error('Backup events yüklenirken hata:', error);
      }
    };

    loadBackupEvents();
  }, [getBackupList]);

  // Load Supabase calendar events
  useEffect(() => {
    const loadSupabaseEvents = async () => {
      if (!user) return;
      
      setLoadingSupabaseEvents(true);
      try {
        const { data, error } = await supabase
          .from('calendar')
          .select('*')
          .eq('user_id', user.id)
          .order('event_date', { ascending: true });

        if (error) {
          console.error('Supabase calendar events yüklenirken hata:', error);
          return;
        }

        const events: Event[] = (data || []).map((item, index) => ({
          id: Date.now() + index + 10000, // Unique ID for Supabase events
          date: item.date || '',
          title: item.title || '',
          description: item.description || '',
          type: (item.type as Event['type']) || 'custom',
          icon: item.icon || '📅',
          color: item.color || 'bg-gray-100 text-gray-800 border-gray-200',
          status: 'completed'
        }));

        setSupabaseEvents(events);
      } catch (error) {
        console.error('Supabase calendar events yüklenirken hata:', error);
      } finally {
        setLoadingSupabaseEvents(false);
      }
    };

    loadSupabaseEvents();
  }, [user]);

  // Memoized events calculation
  const events = useMemo(() => {
    // Return empty array if still loading
    if (loading) {
      return [];
    }

    const eventList: Event[] = [];
    let eventId = 1;

    try {
      // Process egg events
    eggs.forEach(egg => {
      const incubation = incubations.find(inc => inc.id === egg.breedingId);
      const maleBird = birds.find(bird => bird.id === incubation?.maleBirdId);
      const femaleBird = birds.find(bird => bird.id === incubation?.femaleBirdId);
      
      const parentNames = maleBird && femaleBird 
        ? `${femaleBird.name} (Anne) & ${maleBird.name} (Baba)`
        : incubation?.name || 'Bilinmiyor';

        // Laying date event
        if (egg.layDate) {
          const event: Event = {
        id: eventId++,
        date: egg.layDate,
        title: `Yumurta #${egg.number} - ${egg.status === 'hatched' ? 'Çıktı' : egg.status === 'infertile' ? 'Boş' : 'Yumurta'}`,
        description: egg.notes || `${egg.number}. yumurta için etkinlik`,
        type: 'egg',
        icon: egg.status === 'hatched' ? '🐣' : '🥚',
        color: egg.status === 'hatched' ? 'bg-green-100 text-green-800 border-green-200' :
               egg.status === 'infertile' ? 'bg-gray-100 text-gray-600 border-gray-300' :
               'bg-blue-100 text-blue-800 border-blue-200',
        status: egg.status,
        parentNames
          };
          
          if (incubation?.name) {
            event.birdName = incubation.name;
          }
          
          if (egg.number) {
            event.eggNumber = egg.number;
          }
          
          eventList.push(event);
        }

        // Hatching date event (if applicable)
      if (egg.hatchDate && egg.status === 'hatched') {
          const hatchEvent: Event = {
          id: eventId++,
          date: egg.hatchDate,
          title: `Yumurta #${egg.number} - Çıkış`,
          description: `${egg.number}. yumurta başarıyla çıktı`,
          type: 'hatching',
          icon: '🐣',
          color: 'bg-green-100 text-green-800 border-green-200',
          status: 'hatched',
          parentNames
          };
          
          if (incubation?.name) {
            hatchEvent.birdName = incubation.name;
          }
          
          if (egg.number) {
            hatchEvent.eggNumber = egg.number;
          }
          
          eventList.push(hatchEvent);
      }
    });

      // Process chick events
    chicks.forEach(chick => {
      const incubation = incubations.find(inc => inc.id === chick.breedingId);
      const maleBird = birds.find(bird => bird.id === chick.fatherId);
      const femaleBird = birds.find(bird => bird.id === chick.motherId);
      
      const parentNames = maleBird && femaleBird 
        ? `${femaleBird.name} (Anne) & ${maleBird.name} (Baba)`
        : 'Bilinmiyor';

        if (chick.hatchDate) {
      eventList.push({
        id: eventId++,
        date: chick.hatchDate,
        title: `${chick.name} - Çıkış`,
        description: `${chick.name} yavrumuz çıktı`,
        type: 'chick',
        icon: '🐤',
        color: 'bg-yellow-100 text-yellow-800 border-yellow-200',
        birdName: chick.name,
        status: 'healthy',
        parentNames
      });
        }
      });

      // Add custom events
      customEvents.forEach(customEvent => {
        eventList.push({
          ...customEvent,
          id: eventId++
        });
      });

      // Add backup events
      backupEvents.forEach(backupEvent => {
        eventList.push({
          ...backupEvent,
          id: eventId++
        });
      });

      // Add Supabase events
      supabaseEvents.forEach(supabaseEvent => {
        eventList.push({
          ...supabaseEvent,
          id: eventId++
        });
      });

      // Sort events by date
      return eventList.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    } catch (error) {
      console.error('Error processing calendar events:', error);
      return [];
    }
         }, [eggs, chicks, incubations, birds, loading, customEvents, backupEvents, supabaseEvents]);

  // Memoized function to get events for a specific date
  const getEventsForDate = useCallback((date: string) => {
    if (!date) return [];
    
    return events.filter(event => event.date === date);
  }, [events]);

  // Function to add custom events
  const addEvent = useCallback(async (newEvent: Omit<Event, 'id'>) => {
    if (!user) {
      console.error('Kullanıcı girişi gerekli');
      return;
    }

    try {
      // Supabase'e kaydet
      const { data, error } = await supabase
        .from('calendar')
        .insert({
          user_id: user.id,
          title: newEvent.title || '',
          description: newEvent.description || null,
          date: newEvent.date,
          type: newEvent.type,
          icon: newEvent.icon || '📅',
          color: newEvent.color || 'bg-gray-100 text-gray-800 border-gray-200'
        })
        .select()
        .single();

      if (error) {
        console.error('Supabase event ekleme hatası:', error);
        // Hata durumunda local state'e ekle
        const eventWithId: Event = {
          ...newEvent,
          id: Date.now()
        };
        setCustomEvents(prev => [...prev, eventWithId]);
        return;
      }

      // Başarılı ise Supabase'den gelen veriyi kullan
      const eventWithId: Event = {
        ...newEvent,
        id: Date.now()
      };
      
      setCustomEvents(prev => [...prev, eventWithId]);
    } catch (error) {
      console.error('Event ekleme hatası:', error);
      // Hata durumunda local state'e ekle
      const eventWithId: Event = {
        ...newEvent,
        id: Date.now()
      };
      setCustomEvents(prev => [...prev, eventWithId]);
    }
  }, [user]);

  // Function to remove custom events
  const removeEvent = useCallback((eventId: number) => {
    setCustomEvents(prev => prev.filter(event => event.id !== eventId));
  }, []);

  // Function to update custom events
  const updateEvent = useCallback((eventId: number, updatedEvent: Partial<Event>) => {
    setCustomEvents(prev => prev.map(event => 
      event.id === eventId ? { ...event, ...updatedEvent } : event
    ));
  }, []);

  return {
    events,
    getEventsForDate,
    loading,
    error: null,
    addEvent,
    removeEvent,
    updateEvent
  };
};