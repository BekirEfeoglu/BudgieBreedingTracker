import { useState, useCallback, useMemo, memo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Calendar, Plus, Loader2, AlertCircle } from 'lucide-react';
import { Event } from '@/types/calendar';
import { useCalendarEvents } from '@/hooks/useCalendarEvents';
import { useLanguage } from '@/contexts/LanguageContext';
import { CalendarGrid } from '@/components/calendar/CalendarGrid';
import { EventList } from '@/components/calendar/EventList';
import { DailyEventsModal } from '@/components/calendar/DailyEventsModal';
import { EventDetailModal } from '@/components/calendar/EventDetailModal';
import EventForm from '@/components/calendar/EventForm';

const CalendarView = memo(() => {
  const { t } = useLanguage();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedDateEvents, setSelectedDateEvents] = useState<Event[]>([]);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [isEventDetailModalOpen, setIsEventDetailModalOpen] = useState(false);
  const [isEventFormOpen, setIsEventFormOpen] = useState(false);
  const [currentMonth, setCurrentMonth] = useState(new Date());

  const { events, getEventsForDate, loading, addEvent } = useCalendarEvents();

  // Memoized navigation handler
  const navigateMonth = useCallback((direction: 'prev' | 'next') => {
    setCurrentMonth(prev => {
      const newMonth = new Date(prev);
    if (direction === 'prev') {
      newMonth.setMonth(newMonth.getMonth() - 1);
    } else {
      newMonth.setMonth(newMonth.getMonth() + 1);
    }
      return newMonth;
    });
  }, []);

  // Memoized date click handler
  const handleDateClick = useCallback((day: number) => {
    const clickedDate = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day);
    const dateString = clickedDate.toISOString().split('T')[0];
    if (dateString) {
    const dayEvents = getEventsForDate(dateString);
    
    setSelectedDate(clickedDate);
    setSelectedDateEvents(dayEvents);
    setIsDetailModalOpen(true);
    }
  }, [currentMonth, getEventsForDate]);

  // Memoized event click handler
  const handleEventClick = useCallback((event: Event) => {
    setSelectedEvent(event);
    setIsEventDetailModalOpen(true);
  }, []);

  // Memoized event form handlers
  const handleEventFormClose = useCallback(() => {
    setIsEventFormOpen(false);
  }, []);

  const handleEventFormSuccess = useCallback((newEvent: Omit<Event, 'id'>) => {
    if (addEvent) {
      addEvent(newEvent);
    }
    setIsEventFormOpen(false);
  }, [addEvent]);

  const handleAddEvent = useCallback(() => {
    setIsEventFormOpen(true);
  }, []);

  // Memoized upcoming events (only show next 5 events)
  const upcomingEvents = useMemo(() => {
    const today = new Date();
    const todayString = today.toISOString().split('T')[0];
    
    if (!todayString) return [];
    
    return events
      .filter(event => event.date && event.date >= todayString)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
      .slice(0, 5);
  }, [events]);

  // Loading state
  if (loading) {
    return (
      <div className="space-y-4 sm:space-y-6 min-w-0">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 min-w-0">
          <h2 className="text-xl sm:text-2xl md:text-3xl font-bold enhanced-text-primary flex items-center gap-2 min-w-0">
            <Calendar className="w-5 h-5 sm:w-6 sm:h-6 text-primary flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">{t('calendar.title', 'Takvim')}</span>
          </h2>
        </div>
        <div className="flex items-center justify-center min-h-[400px] min-w-0">
          <div className="text-center space-y-4 min-w-0">
            <Loader2 className="w-8 h-8 animate-spin text-primary mx-auto flex-shrink-0" />
            <p className="text-sm enhanced-text-secondary truncate max-w-full min-w-0">
              {t('calendar.loading', 'Takvim yükleniyor...')}
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Error handling will be handled by parent ErrorBoundary

  return (
    <div className="space-y-4 sm:space-y-6 min-w-0">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 min-w-0">
        <h2 className="text-xl sm:text-2xl md:text-3xl font-bold enhanced-text-primary flex items-center gap-2 min-w-0">
          <Calendar className="w-5 h-5 sm:w-6 sm:h-6 text-primary flex-shrink-0" />
          <span className="truncate max-w-full min-w-0">{t('calendar.title', 'Takvim')}</span>
        </h2>
        {/* Masaüstü için buton */}
        <div className="hidden sm:block min-w-0 flex-shrink-0">
          <Button 
            className="enhanced-button-primary min-h-[44px] w-full sm:w-auto min-w-0"
            aria-label={t('calendar.addEvent', 'Etkinlik Ekle')}
            onClick={handleAddEvent}
          >
            <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">{t('calendar.addEvent', 'Etkinlik Ekle')}</span>
          </Button>
        </div>
      </div>

      {/* Mobil için floating action button */}
      <div className="sm:hidden">
        <Button
          className="fixed bottom-5 right-5 z-50 rounded-full w-14 h-14 sm:w-16 sm:h-16 shadow-lg bg-primary text-white flex items-center justify-center text-lg min-w-0"
          style={{ boxShadow: '0 4px 24px rgba(0,0,0,0.15)' }}
          aria-label={t('calendar.addEvent', 'Etkinlik Ekle')}
          onClick={handleAddEvent}
        >
          <Plus className="w-6 h-6 sm:w-7 sm:h-7 flex-shrink-0" />
        </Button>
      </div>

      {/* Calendar Grid */}
      <Card className="enhanced-card min-w-0">
        <CardHeader className="min-w-0">
          <CalendarGrid 
            currentMonth={currentMonth}
            onNavigateMonth={navigateMonth}
            onDateClick={handleDateClick}
            getEventsForDate={getEventsForDate}
          />
        </CardHeader>
      </Card>

      {/* Upcoming Events */}
      <Card className="enhanced-card min-w-0">
        <CardHeader className="min-w-0">
          <CardTitle className="text-base sm:text-lg enhanced-text-primary flex items-center gap-2 min-w-0">
            <span className="text-orange-500 flex-shrink-0" role="img" aria-label={t('calendar.upcomingEvents', 'Yaklaşan Etkinlikler')}>⏰</span>
            <span className="truncate max-w-full min-w-0">{t('calendar.upcomingEvents', 'Yaklaşan Etkinlikler')}</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="min-w-0">
          {upcomingEvents.length > 0 ? (
            <EventList events={upcomingEvents} onEventClick={handleEventClick} />
          ) : (
            <div className="text-center py-6 sm:py-8 space-y-2 min-w-0">
              <div className="text-3xl sm:text-4xl text-muted-foreground flex-shrink-0">📅</div>
              <p className="text-xs sm:text-sm enhanced-text-secondary truncate max-w-full min-w-0">
                {t('calendar.noUpcomingEvents', 'Yaklaşan etkinlik bulunmuyor')}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modals */}
      <DailyEventsModal 
        isOpen={isDetailModalOpen}
        onClose={() => setIsDetailModalOpen(false)}
        selectedDate={selectedDate}
        events={selectedDateEvents}
        onEventClick={handleEventClick}
        onAddEvent={handleAddEvent}
      />

      <EventDetailModal 
        isOpen={isEventDetailModalOpen}
        onClose={() => setIsEventDetailModalOpen(false)}
        event={selectedEvent}
      />

      <EventForm
        isOpen={isEventFormOpen}
        onClose={handleEventFormClose}
        onSave={handleEventFormSuccess}
        selectedDate={selectedDate}
      />
    </div>
  );
});

CalendarView.displayName = 'CalendarView';

export default CalendarView;
