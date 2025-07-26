import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { X, Clock, MapPin, Plus, Calendar } from 'lucide-react';
import { Event } from '@/types/calendar';
import { useLanguage } from '@/contexts/LanguageContext';
import { memo } from 'react';

interface DailyEventsModalProps {
  isOpen: boolean;
  onClose: () => void;
  selectedDate: Date;
  events: Event[];
  onEventClick: (event: Event) => void;
  onAddEvent?: () => void;
}

export const DailyEventsModal = memo(({ 
  isOpen, 
  onClose, 
  selectedDate, 
  events, 
  onEventClick,
  onAddEvent
}: DailyEventsModalProps) => {
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
      custom: t('calendar.eventTypes.custom', 'Özel'),
      backup: t('calendar.eventTypes.backup', 'Yedekleme')
    };
    return labels[type as keyof typeof labels] || type;
  };

  // Olay tipine göre renkli nokta
  const getDotColor = (type: string) => {
    switch (type) {
      case 'egg': return 'bg-yellow-400';
      case 'hatching': return 'bg-green-500';
      case 'chick': return 'bg-purple-500';
      default: return 'bg-gray-400';
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('tr-TR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="mobile-modal-large min-w-0" aria-describedby="daily-events-description">
        <DialogHeader className="min-w-0">
          <DialogTitle className="flex items-center justify-between gap-2 min-w-0">
            <div className="flex items-center gap-2 min-w-0 flex-1">
              <Calendar className="w-5 h-5 flex-shrink-0" />
              <span className="truncate max-w-full min-w-0">
                {formatDate(selectedDate)}
              </span>
            </div>
            {onAddEvent && (
              <Button
                size="sm"
                onClick={onAddEvent}
                className="min-h-[36px] min-w-0 flex-shrink-0"
              >
                <Plus className="w-4 h-4 mr-1 flex-shrink-0" />
                <span className="truncate max-w-full min-w-0">Ekle</span>
              </Button>
            )}
          </DialogTitle>
          <div id="daily-events-description" className="sr-only">
            {formatDate(selectedDate)} tarihindeki etkinlikler
          </div>
        </DialogHeader>

        <div className="space-y-4 min-w-0">
          {events.length === 0 ? (
            <div className="text-center py-8 space-y-4 min-w-0">
              <div className="text-4xl text-muted-foreground flex-shrink-0">📅</div>
              <div className="space-y-2 min-w-0">
                <p className="text-sm enhanced-text-secondary truncate max-w-full min-w-0">
                  {t('calendar.noEventsForDate', 'Bu tarihte etkinlik bulunmuyor')}
                </p>
                {onAddEvent && (
                  <Button
                    variant="outline"
                    onClick={onAddEvent}
                    className="min-h-[44px] min-w-0"
                  >
                    <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
                    <span className="truncate max-w-full min-w-0">
                      {t('calendar.addEventForDate', 'Bu Tarihe Etkinlik Ekle')}
                    </span>
                  </Button>
                )}
              </div>
            </div>
          ) : (
            <div className="space-y-3 min-w-0">
              {events.map((event) => (
                <Card 
                  key={event.id} 
                  className="mobile-card cursor-pointer hover:shadow-md transition-shadow min-w-0"
                  onClick={() => onEventClick(event)}
                >
                  <CardContent className="p-4 min-w-0">
                    <div className="flex items-start gap-3 min-w-0">
                      <div className="flex-shrink-0 pt-1">
                        <span className={`inline-block w-3 h-3 rounded-full ${getDotColor(event.type)}`} aria-hidden="true"></span>
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-start justify-between gap-2 min-w-0">
                          <h4 className="font-semibold text-base sm:text-lg truncate max-w-full min-w-0">
                            {event.title}
                          </h4>
                          <Badge 
                            variant={event.type === 'egg' ? 'secondary' : event.type === 'hatching' ? 'outline' : event.type === 'chick' ? 'default' : 'secondary'}
                            className={`text-xs px-3 py-1 rounded-full flex-shrink-0 ${getDotColor(event.type)} text-white`}
                          >
                            {getEventTypeLabel(event.type)}
                          </Badge>
                        </div>
                        {event.description && (
                          <p className="text-sm text-muted-foreground mt-1 line-clamp-2 min-w-0">
                            {event.description}
                          </p>
                        )}
                        {event.parentNames && (
                          <div className="flex items-center gap-1 mt-2 min-w-0">
                            <MapPin className="w-3 h-3 text-muted-foreground flex-shrink-0" />
                            <span className="text-xs text-muted-foreground truncate max-w-full min-w-0">
                              {event.parentNames}
                            </span>
                          </div>
                        )}
                        {event.birdName && (
                          <div className="flex items-center gap-1 mt-1 min-w-0">
                            <span className="text-xs text-muted-foreground truncate max-w-full min-w-0">
                              🦜 {event.birdName}
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
});

DailyEventsModal.displayName = 'DailyEventsModal';