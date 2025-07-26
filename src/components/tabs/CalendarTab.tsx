import React, { Suspense, memo, useState, useMemo, useCallback } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { Calendar, Loader2, Plus, ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { format, addMonths, subMonths, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isToday, isSameDay } from 'date-fns';
import { tr } from 'date-fns/locale';
import EventForm from '@/components/calendar/EventForm';
import { useCalendarEvents } from '@/hooks/useCalendarEvents';
import { Event } from '@/types/calendar';

// Lazy load CalendarView for better performance
const CalendarView = React.lazy(() => import('@/components/CalendarView'));

// Loading skeleton component
const CalendarSkeleton = () => (
  <div className="space-y-4 sm:space-y-6">
    {/* Header skeleton */}
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div className="flex items-center gap-2">
        <Calendar className="w-5 h-5 sm:w-6 sm:h-6 text-muted-foreground animate-pulse" />
        <div className="h-8 w-24 bg-muted rounded animate-pulse" />
      </div>
      <div className="h-11 w-full sm:w-32 bg-muted rounded animate-pulse" />
    </div>

    {/* Calendar grid skeleton */}
    <div className="enhanced-card p-6">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="h-6 w-32 bg-muted rounded animate-pulse" />
          <div className="flex gap-2">
            <div className="h-8 w-8 bg-muted rounded animate-pulse" />
            <div className="h-8 w-8 bg-muted rounded animate-pulse" />
          </div>
        </div>
        <div className="grid grid-cols-7 gap-1">
          {Array.from({ length: 42 }).map((_, i) => (
            <div key={i} className="h-12 bg-muted rounded animate-pulse" />
          ))}
        </div>
      </div>
    </div>

    {/* Events list skeleton */}
    <div className="enhanced-card p-6">
      <div className="space-y-4">
        <div className="h-6 w-40 bg-muted rounded animate-pulse" />
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="flex items-start gap-3 p-4 border rounded-lg">
            <div className="w-8 h-8 bg-muted rounded animate-pulse" />
            <div className="flex-1 space-y-2">
              <div className="h-4 w-3/4 bg-muted rounded animate-pulse" />
              <div className="h-3 w-1/2 bg-muted rounded animate-pulse" />
            </div>
          </div>
        ))}
      </div>
    </div>
  </div>
);

// Error fallback component
const CalendarErrorFallback = () => {
  const { t } = useLanguage();
  
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] text-center space-y-4">
      <div className="text-6xl text-muted-foreground">📅</div>
      <h3 className="text-lg font-semibold enhanced-text-primary">
        {t('calendar.error', 'Takvim Yüklenemedi')}
      </h3>
      <p className="text-sm enhanced-text-secondary max-w-md">
        {t('calendar.errorDescription', 'Takvim verilerini yüklerken bir hata oluştu. Lütfen tekrar deneyin.')}
      </p>
      <button
        onClick={() => window.location.reload()}
        className="enhanced-button-primary min-h-[44px] px-6"
        aria-label={t('common.retry', 'Tekrar Dene')}
      >
        {t('common.retry', 'Tekrar Dene')}
      </button>
    </div>
  );
};

// Loading component with spinner
const CalendarLoading = () => {
  const { t } = useLanguage();
  
  return (
    <div className="space-y-6 pb-20 md:pb-4 px-2 md:px-0">
      <div className="flex flex-col items-center justify-center min-h-[400px] space-y-4">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
        <p className="text-sm enhanced-text-secondary">
          {t('calendar.loading', 'Takvim yükleniyor...')}
        </p>
        <CalendarSkeleton />
      </div>
    </div>
  );
};

// Türkçeleştirme fonksiyonu
const getEventTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    breeding: 'Kuluçka',
    health: 'Sağlık',
    hatching: 'Çıkış',
    mating: 'Çiftleşme',
    feeding: 'Beslenme',
    cleaning: 'Temizlik',
    egg: 'Yumurta',
    chick: 'Yavru',
    custom: 'Özel',
    backup: 'Yedekleme'
  };
  return labels[type] || type;
};

const CalendarTab = memo(() => {
  const { t } = useLanguage();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [isAddEventModalOpen, setIsAddEventModalOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [isEventDetailModalOpen, setIsEventDetailModalOpen] = useState(false);
  const { addEvent, events, getEventsForDate } = useCalendarEvents();

  // Get events for selected date
  const dailyEvents = useMemo(() => {
    const dateString = format(selectedDate, 'yyyy-MM-dd');
    return getEventsForDate(dateString);
  }, [selectedDate, getEventsForDate]);

  // Generate calendar days
  const calendarDays = useMemo(() => {
    const start = startOfMonth(currentDate);
    const end = endOfMonth(currentDate);
    const days = eachDayOfInterval({ start, end });
    
    // Add padding days from previous/next month
    const firstDayOfWeek = start.getDay();
    const lastDayOfWeek = end.getDay();
    
    const paddingStart = Array.from({ length: firstDayOfWeek }, (_, i) => {
      const date = new Date(start);
      date.setDate(date.getDate() - (firstDayOfWeek - i));
      return { date, isCurrentMonth: false, isToday: isToday(date), hasEvents: false };
    });
    
    const paddingEnd = Array.from({ length: 6 - lastDayOfWeek }, (_, i) => {
      const date = new Date(end);
      date.setDate(date.getDate() + i + 1);
      return { date, isCurrentMonth: false, isToday: isToday(date), hasEvents: false };
    });
    
    const currentMonthDays = days.map(date => {
      const dateString = format(date, 'yyyy-MM-dd');
      const dayEvents = getEventsForDate(dateString);
      return {
        date,
        isCurrentMonth: true,
        isToday: isToday(date),
        hasEvents: dayEvents.length > 0
      };
    });
    
    return [...paddingStart, ...currentMonthDays, ...paddingEnd];
  }, [currentDate, getEventsForDate]);

  const handleDayClick = (date: Date) => {
    setSelectedDate(date);
  };

  const handleEventClick = useCallback((event: Event) => {
    setSelectedEvent(event);
    setIsEventDetailModalOpen(true);
  }, []);

  const handleEventFormClose = () => {
    setIsAddEventModalOpen(false);
  };

  const handleEventFormSuccess = (newEvent: Omit<Event, 'id'>) => {
    if (addEvent) {
      addEvent(newEvent);
    }
    setIsAddEventModalOpen(false);
  };

  const getEventColor = useCallback((type: string) => {
    const colors: Record<string, string> = {
      breeding: 'bg-blue-500',
      feeding: 'bg-green-500',
      health: 'bg-red-500',
      cleaning: 'bg-yellow-500',
      egg: 'bg-orange-500',
      chick: 'bg-purple-500',
      hatching: 'bg-green-500',
      mating: 'bg-pink-500',
      custom: 'bg-gray-500',
      backup: 'bg-indigo-500'
    };
    return colors[type] || 'bg-gray-500';
  }, []);

  return (
    <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="region" aria-label="Takvim">
      {/* Header */}
      <div className="mobile-header min-w-0">
        <div className="min-w-0 flex-1">
          <h1 className="mobile-header-title truncate max-w-full min-w-0 flex items-center gap-2">
            <Calendar className="w-5 h-5 sm:w-6 sm:h-6 text-primary flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">Takvim</span>
          </h1>
          <p className="mobile-subtitle truncate max-w-full min-w-0 mt-1">
            Üreme takvimi ve önemli tarihler
          </p>
        </div>
        
        <div className="mobile-header-actions min-w-0 flex-shrink-0">
          <Button 
            onClick={() => setIsAddEventModalOpen(true)}
            className="w-full sm:w-auto enhanced-button-primary mobile-form-button min-w-0"
          >
            <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">Olay Ekle</span>
          </Button>
        </div>
      </div>

      {/* Calendar Navigation */}
      <div className="flex items-center justify-between min-w-0">
        <Button
          variant="outline"
          size="sm"
          onClick={() => setCurrentDate(subMonths(currentDate, 1))}
          className="enhanced-button-secondary min-h-[48px] w-12 h-12 rounded-full p-0 flex-shrink-0 touch-target"
        >
          <ChevronLeft className="w-4 h-4 flex-shrink-0" />
        </Button>
        
        <h2 className="text-lg sm:text-xl font-semibold enhanced-text-primary truncate max-w-full min-w-0 px-2">
          {format(currentDate, 'MMMM yyyy', { locale: tr })}
        </h2>
        
        <Button
          variant="outline"
          size="sm"
          onClick={() => setCurrentDate(addMonths(currentDate, 1))}
          className="enhanced-button-secondary min-h-[48px] w-12 h-12 rounded-full p-0 flex-shrink-0 touch-target"
        >
          <ChevronRight className="w-4 h-4 flex-shrink-0" />
        </Button>
      </div>

      {/* Calendar Grid */}
      <Card className="enhanced-card min-w-0">
        <CardContent className="p-2 sm:p-4 min-w-0">
          <div className="grid grid-cols-7 gap-1 min-w-0">
            {/* Day Headers */}
            {['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((day) => (
              <div key={day} className="text-center py-2 min-w-0">
                <span className="text-xs font-medium text-muted-foreground truncate max-w-full min-w-0 block">
                  {day}
                </span>
              </div>
            ))}
            
            {/* Calendar Days */}
            {calendarDays.map((day, index) => (
              <button
                key={index}
                onClick={() => handleDayClick(day.date)}
                className={`
                  aspect-square p-1 text-center cursor-pointer rounded-md transition-colors min-w-0 touch-target
                  hover:bg-accent focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
                  ${!day.isCurrentMonth ? 'text-muted-foreground/50' : 'enhanced-text-primary'}
                  ${day.isToday ? 'bg-primary text-primary-foreground font-bold ring-2 ring-primary ring-offset-2' : ''}
                  ${isSameDay(day.date, selectedDate) ? 'bg-secondary border-2 border-secondary-foreground' : ''}
                  ${day.hasEvents ? 'bg-primary/10 border-2 border-primary/30 font-bold' : ''}
                `}
              >
                <div className="text-xs sm:text-sm font-medium truncate max-w-full min-w-0">
                  {format(day.date, 'd')}
                </div>
                {day.hasEvents && (
                  <div className="w-1 h-1 bg-primary rounded-full mx-auto mt-1 flex-shrink-0"></div>
                )}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Events List */}
      <Card className="enhanced-card min-w-0">
        <CardHeader className="min-w-0">
          <CardTitle className="flex items-center gap-2 truncate max-w-full min-w-0">
            <Calendar className="w-5 h-5 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">Günlük Olaylar</span>
          </CardTitle>
          <CardDescription className="truncate max-w-full min-w-0">
            {format(selectedDate, 'd MMMM yyyy', { locale: tr })} tarihindeki olaylar
          </CardDescription>
        </CardHeader>
        <CardContent className="min-w-0">
          {dailyEvents.length === 0 ? (
            <div className="mobile-empty-state min-w-0">
              <Calendar className="h-12 w-12 mx-auto mb-4 opacity-50 flex-shrink-0" />
              <p className="mobile-empty-text truncate max-w-full min-w-0">Bu tarihte olay bulunmuyor</p>
            </div>
          ) : (
            <div className="space-y-3 min-w-0">
              {dailyEvents.map((event) => (
                <div 
                  key={event.id} 
                  className="flex items-center gap-3 p-4 border rounded-lg hover:bg-muted/50 transition-colors min-w-0 cursor-pointer touch-target"
                  onClick={() => handleEventClick(event)}
                >
                  <div className={`w-3 h-3 rounded-full flex-shrink-0 ${getEventColor(event.type)}`}></div>
                  <div className="flex-1 min-w-0">
                    <h4 className="font-medium truncate max-w-full min-w-0 enhanced-text-primary">{event.title}</h4>
                    <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                      {event.description}
                    </p>
                  </div>
                  <div className="text-xs text-muted-foreground flex-shrink-0 min-w-0">
                    {getEventTypeLabel(event.type)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 min-w-0">
        <Button 
          variant="outline" 
          onClick={() => setIsAddEventModalOpen(true)}
          className="enhanced-button-secondary mobile-form-button min-w-0"
        >
          <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
          <span className="truncate max-w-full min-w-0">Olay Ekle</span>
        </Button>
        <Button 
          variant="outline" 
          onClick={() => setCurrentDate(new Date())}
          className="enhanced-button-secondary mobile-form-button min-w-0"
        >
          <Calendar className="w-4 h-4 mr-2 flex-shrink-0" />
          <span className="truncate max-w-full min-w-0">Bugüne Git</span>
        </Button>
      </div>

      {/* Event Form Modal */}
      <EventForm
        isOpen={isAddEventModalOpen}
        onClose={handleEventFormClose}
        onSave={handleEventFormSuccess}
        selectedDate={selectedDate}
      />

      {/* Event Detail Modal */}
      {selectedEvent && (
        <Dialog open={isEventDetailModalOpen} onOpenChange={() => setIsEventDetailModalOpen(false)}>
          <DialogContent className="mobile-modal-large min-w-0" aria-describedby="calendar-detail-description">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2 truncate max-w-full min-w-0">
                <span className="text-2xl flex-shrink-0">{selectedEvent.icon}</span>
                <span className="truncate max-w-full min-w-0">{selectedEvent.title}</span>
              </DialogTitle>
              <div id="calendar-detail-description" className="sr-only">
                {selectedEvent.title} detayları
              </div>
              <DialogDescription className="truncate max-w-full min-w-0">
                {format(new Date(selectedEvent.date), 'd MMMM yyyy', { locale: tr })}
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4 min-w-0">
              {selectedEvent.description && (
                <div className="min-w-0">
                  <h4 className="font-medium mb-2 truncate max-w-full min-w-0">Açıklama</h4>
                  <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                    {selectedEvent.description}
                  </p>
                </div>
              )}
              
              {selectedEvent.birdName && (
                <div className="min-w-0">
                  <h4 className="font-medium mb-2 truncate max-w-full min-w-0">Kuş Adı</h4>
                  <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                    {selectedEvent.birdName}
                  </p>
                </div>
              )}
              
              {selectedEvent.parentNames && (
                <div className="min-w-0">
                  <h4 className="font-medium mb-2 truncate max-w-full min-w-0">Ebeveynler</h4>
                  <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                    {selectedEvent.parentNames}
                  </p>
                </div>
              )}
              
              {selectedEvent.eggNumber && (
                <div className="min-w-0">
                  <h4 className="font-medium mb-2 truncate max-w-full min-w-0">Yumurta Numarası</h4>
                  <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                    {selectedEvent.eggNumber}
                  </p>
                </div>
              )}
              
              <div className="flex items-center gap-2 min-w-0">
                <div className={`w-4 h-4 rounded-full ${getEventColor(selectedEvent.type)} flex-shrink-0`}></div>
                <span className="text-sm text-muted-foreground truncate max-w-full min-w-0 capitalize">
                  {getEventTypeLabel(selectedEvent.type)}
                </span>
              </div>
            </div>
            
            <div className="flex gap-3 pt-4 min-w-0">
              <Button
                variant="outline"
                onClick={() => setIsEventDetailModalOpen(false)}
                className="flex-1 min-h-[44px] min-w-0"
              >
                <span className="truncate max-w-full min-w-0">Kapat</span>
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
});

CalendarTab.displayName = 'CalendarTab';

export default CalendarTab;
