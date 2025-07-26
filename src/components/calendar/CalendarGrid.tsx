import { Button } from '@/components/ui/button';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Event } from '@/types/calendar';
import { useLanguage } from '@/contexts/LanguageContext';
import { memo, useMemo } from 'react';

interface CalendarGridProps {
  currentMonth: Date;
  onNavigateMonth: (direction: 'prev' | 'next') => void;
  onDateClick: (day: number) => void;
  getEventsForDate: (date: string) => Event[];
}

export const CalendarGrid = memo(({ 
  currentMonth, 
  onNavigateMonth, 
  onDateClick, 
  getEventsForDate 
}: CalendarGridProps) => {
  const { t } = useLanguage();

  // Localized month and day names
  const monthNames = useMemo(() => [
    t('calendar.months.january', 'Ocak'),
    t('calendar.months.february', 'Şubat'),
    t('calendar.months.march', 'Mart'),
    t('calendar.months.april', 'Nisan'),
    t('calendar.months.may', 'Mayıs'),
    t('calendar.months.june', 'Haziran'),
    t('calendar.months.july', 'Temmuz'),
    t('calendar.months.august', 'Ağustos'),
    t('calendar.months.september', 'Eylül'),
    t('calendar.months.october', 'Ekim'),
    t('calendar.months.november', 'Kasım'),
    t('calendar.months.december', 'Aralık')
  ], [t]);

  const dayNames = useMemo(() => [
    t('calendar.days.sunday', 'Paz'),
    t('calendar.days.monday', 'Pzt'),
    t('calendar.days.tuesday', 'Sal'),
    t('calendar.days.wednesday', 'Çar'),
    t('calendar.days.thursday', 'Per'),
    t('calendar.days.friday', 'Cum'),
    t('calendar.days.saturday', 'Cmt')
  ], [t]);

  // Memoized calendar days calculation
  const calendarDays = useMemo(() => {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay();

    const days = [];
    
    // Add empty cells for days before the first day of the month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null);
    }
    
    // Add days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      days.push(day);
    }
    
    return days;
  }, [currentMonth]);

  // Navigation handlers
  const handlePrevMonth = () => {
    onNavigateMonth('prev');
  };

  const handleNextMonth = () => {
    onNavigateMonth('next');
  };

  // Get today's date for highlighting
  const today = new Date();
  const isToday = (day: number) => {
    return today.getDate() === day && 
           today.getMonth() === currentMonth.getMonth() && 
           today.getFullYear() === currentMonth.getFullYear();
  };

  return (
    <div className="space-y-3 sm:space-y-4 min-w-0">
      {/* Calendar Header */}
      <div className="flex items-center justify-between min-w-0">
        <h3 className="text-base sm:text-lg md:text-xl font-semibold enhanced-text-primary truncate max-w-full min-w-0 px-1">
          {monthNames[currentMonth.getMonth()]} {currentMonth.getFullYear()}
        </h3>
        <div className="flex gap-1 sm:gap-2 min-w-0 flex-shrink-0">
          <Button
            variant="outline"
            size="sm"
            onClick={handlePrevMonth}
            className="enhanced-button-secondary min-h-[44px] w-10 h-10 sm:w-12 sm:h-12 rounded-full p-0 flex-shrink-0"
            aria-label={t('calendar.previousMonth', 'Önceki Ay')}
          >
            <ChevronLeft className="w-4 h-4 flex-shrink-0" />
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleNextMonth}
            className="enhanced-button-secondary min-h-[44px] w-10 h-10 sm:w-12 sm:h-12 rounded-full p-0 flex-shrink-0"
            aria-label={t('calendar.nextMonth', 'Sonraki Ay')}
          >
            <ChevronRight className="w-4 h-4 flex-shrink-0" />
          </Button>
        </div>
      </div>

      {/* Day Names Header */}
      <div className="grid grid-cols-7 gap-1 text-center text-xs sm:text-sm mb-2 min-w-0">
        {dayNames.map((day, _index) => (
          <div 
            key={day} 
            className="p-1 sm:p-2 font-semibold enhanced-text-secondary min-w-0"
            role="columnheader"
            aria-label={day}
          >
            <span className="hidden sm:inline truncate max-w-full min-w-0 block">{day}</span>
            <span className="sm:hidden text-xs truncate max-w-full min-w-0 block">{day.charAt(0)}</span>
          </div>
        ))}
      </div>
      
      {/* Calendar Days Grid */}
      <div 
        className="grid grid-cols-7 gap-1 text-center text-xs sm:text-sm min-w-0"
        role="grid"
        aria-label={t('calendar.gridLabel', 'Takvim Günleri')}
      >
        {calendarDays.map((day, idx) => {
          if (day === null) {
            return (
              <div 
                key={`empty-${idx}`} 
                className="p-1 sm:p-2 h-8 sm:h-12 md:h-14 min-w-0"
                role="gridcell"
                aria-hidden="true"
              />
            );
          }
          
          const dateString = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day)
            .toISOString().split('T')[0];
          const dayEvents = dateString ? getEventsForDate(dateString) : [];
          const hasEvents = dayEvents.length > 0;
          const isTodayDate = isToday(day);
          
          return (
            <button
              key={day}
              onClick={() => onDateClick(day)}
              className={`
                relative p-1 sm:p-2 h-8 sm:h-12 md:h-14 rounded-lg transition-all duration-200 min-w-0
                hover:bg-accent cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
                ${isTodayDate 
                  ? 'bg-primary text-primary-foreground font-bold ring-2 ring-primary ring-offset-2' 
                  : hasEvents 
                  ? 'bg-primary/10 border-2 border-primary/30 font-bold enhanced-text-primary hover:bg-primary/20' 
                  : 'enhanced-text-primary hover:bg-muted'
                }
              `}
              role="gridcell"
              aria-label={`${day} ${monthNames[currentMonth.getMonth()]}, ${hasEvents ? t('calendar.hasEvents', 'etkinlik var') : t('calendar.noEvents', 'etkinlik yok')}`}
              aria-pressed={hasEvents}
              tabIndex={0}
            >
              <span className="relative z-10 text-xs sm:text-sm truncate max-w-full min-w-0 block">{day}</span>
              
              {/* Event indicators */}
              {hasEvents && (
                <div className="absolute bottom-0.5 sm:bottom-1 left-1/2 transform -translate-x-1/2 flex gap-0.5 sm:gap-1 min-w-0">
                  {dayEvents.slice(0, 3).map((event, _index) => (
                    <div
                      key={_index}
                      className={`w-1 h-1 sm:w-1.5 sm:h-1.5 rounded-full flex-shrink-0 ${
                        event.status === 'infertile' ? 'bg-gray-400' : 'bg-primary'
                      } opacity-80`}
                      aria-hidden="true"
                    />
                  ))}
                  {dayEvents.length > 3 && (
                    <div 
                      className="text-xs text-primary font-bold flex-shrink-0"
                      aria-label={t('calendar.moreEvents', 'Daha fazla etkinlik')}
                    >
                      +
                    </div>
                  )}
                </div>
              )}
              
              {/* Today indicator */}
              {isTodayDate && (
                <div className="absolute top-0.5 sm:top-1 right-0.5 sm:right-1 w-1.5 h-1.5 sm:w-2 sm:h-2 bg-primary-foreground rounded-full flex-shrink-0" />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
});

CalendarGrid.displayName = 'CalendarGrid';