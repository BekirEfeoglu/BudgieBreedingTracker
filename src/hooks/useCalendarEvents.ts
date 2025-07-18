import { useMemo, useCallback, useState } from 'react';
import { Event } from '@/types/calendar';
import { useEggsData } from '@/hooks/useEggsData';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { useIncubationData } from '@/hooks/useIncubationData';
import { useBirdsData } from '@/hooks/bird/useBirdsData';

export const useCalendarEvents = () => {
  const { eggs, loading: eggsLoading } = useEggsData();
  const { chicks, loading: chicksLoading } = useChicksData();
  const { incubations, loading: incubationsLoading } = useIncubationData();
  const { birds, loading: birdsLoading } = useBirdsData();

  // State for custom events
  const [customEvents, setCustomEvents] = useState<Event[]>([]);

  // Combine all loading states
  const loading = eggsLoading || chicksLoading || incubationsLoading || birdsLoading;

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

      // Sort events by date
      return eventList.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    } catch (error) {
      console.error('Error processing calendar events:', error);
      return [];
    }
         }, [eggs, chicks, incubations, birds, loading, customEvents]);

  // Memoized function to get events for a specific date
  const getEventsForDate = useCallback((date: string) => {
    if (!date) return [];
    
    return events.filter(event => event.date === date);
  }, [events]);

  // Function to add custom events
  const addEvent = useCallback((newEvent: Omit<Event, 'id'>) => {
    const eventWithId: Event = {
      ...newEvent,
      id: Date.now() // Simple ID generation
    };
    
    setCustomEvents(prev => [...prev, eventWithId]);
  }, []);

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