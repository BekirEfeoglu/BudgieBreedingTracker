import { Badge } from '@/components/ui/badge';
import { Event } from '@/types/calendar';
import { useLanguage } from '@/contexts/LanguageContext';
import { memo } from 'react';

interface EventListProps {
  events: Event[];
  onEventClick: (event: Event) => void;
}

export const EventList = memo(({ events, onEventClick }: EventListProps) => {
  const { t } = useLanguage();

  const getEventTypeLabel = (type: string) => {
    const labels = {
      breeding: t('calendar.eventTypes.breeding', 'Kuluçka'),
      health: t('calendar.eventTypes.health', 'Sağlık'),
      hatching: t('calendar.eventTypes.hatching', 'Çıkış'),
      mating: t('calendar.eventTypes.mating', 'Çiftleşme'),
      feeding: t('calendar.eventTypes.feeding', 'Beslenme'),
      cleaning: t('calendar.eventTypes.cleaning', 'Temizlik'),
      egg: t('calendar.eventTypes.egg', 'Yumurta'),
      chick: t('calendar.eventTypes.chick', 'Yavru'),
      backup: t('calendar.eventTypes.backup', 'Yedekleme')
    };
    return labels[type as keyof typeof labels] || type;
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'short'
    });
  };

  if (events.length === 0) {
    return (
      <div className="text-center py-6 sm:py-8 space-y-2 min-w-0">
        <div className="text-3xl sm:text-4xl text-muted-foreground" role="img" aria-label={t('calendar.noEvents', 'Etkinlik yok')}>📅</div>
        <p className="text-xs sm:text-sm enhanced-text-secondary truncate max-w-full min-w-0">
          {t('calendar.noUpcomingEvents', 'Yaklaşan etkinlik bulunmuyor')}
        </p>
      </div>
    );
  }

  return (
    <div 
      className="space-y-2 sm:space-y-3 min-w-0"
      role="list"
      aria-label={t('calendar.upcomingEventsList', 'Yaklaşan etkinlikler listesi')}
    >
      {events.slice(0, 5).map(event => (
        <div 
          key={event.id} 
          className="enhanced-card-subtle p-3 sm:p-4 hover:shadow-md transition-shadow cursor-pointer focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 rounded-lg min-w-0"
          onClick={() => onEventClick(event)}
          role="listitem"
          tabIndex={0}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              onEventClick(event);
            }
          }}
          aria-label={`${event.title} - ${formatDate(event.date)} - ${getEventTypeLabel(event.type)}`}
        >
          <div className="flex items-start gap-2 sm:gap-3 min-w-0">
            <div 
              className="text-xl sm:text-2xl flex-shrink-0"
              role="img"
              aria-label={event.icon}
            >
              {event.icon}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2 min-w-0">
                <h4 className="font-semibold enhanced-text-primary text-sm sm:text-base truncate max-w-full min-w-0">
                  {event.title}
                </h4>
                <Badge className={`${event.color} flex-shrink-0 text-xs`}>
                  {getEventTypeLabel(event.type)}
                </Badge>
              </div>
              <p className="text-xs sm:text-sm enhanced-text-secondary mt-1 truncate max-w-full min-w-0">
                {formatDate(event.date)}
                {event.time && ` • ${event.time}`}
              </p>
              {event.description && (
                <p className="text-xs sm:text-sm enhanced-text-secondary mt-2 line-clamp-2 min-w-0">
                  {event.description}
                </p>
              )}
              {event.birdName && (
                <div className="flex items-center gap-1 sm:gap-2 mt-2 text-xs enhanced-text-secondary min-w-0">
                  <span role="img" aria-label={t('common.bird', 'Kuş')} className="flex-shrink-0">🐦</span>
                  <span className="truncate max-w-full min-w-0">{event.birdName}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      ))}
      
      {events.length > 5 && (
        <div className="text-center pt-2 min-w-0">
          <p className="text-xs enhanced-text-secondary truncate max-w-full min-w-0">
            {t('calendar.andMoreEvents', `ve ${events.length - 5} etkinlik daha...`)}
          </p>
        </div>
      )}
    </div>
  );
});

EventList.displayName = 'EventList';