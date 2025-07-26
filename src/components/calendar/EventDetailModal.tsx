import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { X, Clock, MapPin, Calendar, Edit, Trash2 } from 'lucide-react';
import { Event } from '@/types/calendar';
import { useLanguage } from '@/contexts/LanguageContext';

interface EventDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  event: Event | null;
  onEdit?: (event: Event) => void;
  onDelete?: (eventId: number) => void;
}

export const EventDetailModal = ({ 
  isOpen, 
  onClose, 
  event, 
  onEdit, 
  onDelete 
}: EventDetailModalProps) => {
  const { t } = useLanguage();

  if (!event) return null;

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

  const getStatusLabel = (status: string) => {
    const labels = {
      active: 'Aktif',
      completed: 'Tamamlandı',
      cancelled: 'İptal Edildi',
      hatched: 'Çıktı',
      infertile: 'Boş',
      fertile: 'Döllü',
      healthy: 'Sağlıklı',
      sick: 'Hasta'
    };
    return labels[status as keyof typeof labels] || status;
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="mobile-modal-large min-w-0" aria-describedby="event-detail-description">
        <DialogHeader className="min-w-0">
          <DialogTitle className="flex items-center justify-between gap-2 min-w-0">
            <div className="flex items-center gap-2 min-w-0 flex-1">
              <span className={`inline-block w-3 h-3 rounded-full ${getDotColor(event.type)}`} aria-hidden="true"></span>
              <span className="text-2xl flex-shrink-0" role="img" aria-hidden="true">
                {event.icon}
              </span>
              <span className="truncate max-w-full min-w-0 font-semibold text-lg">
                {event.title}
              </span>
            </div>
            <div className="flex items-center gap-2 min-w-0 flex-shrink-0">
              {onEdit && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => onEdit(event)}
                  className="min-h-[36px] min-w-0"
                >
                  <Edit className="w-4 h-4 flex-shrink-0" />
                </Button>
              )}
              {onDelete && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => onDelete(event.id)}
                  className="min-h-[36px] min-w-0 text-red-600 hover:text-red-700"
                >
                  <Trash2 className="w-4 h-4 flex-shrink-0" />
                </Button>
              )}
            </div>
          </DialogTitle>
          <div id="event-detail-description" className="sr-only">
            {event.title} etkinlik detayları
          </div>
        </DialogHeader>

        <div className="space-y-4 min-w-0">
          {/* Event Type and Status */}
          <div className="flex items-center gap-2 min-w-0">
            <Badge 
              variant={event.type === 'egg' ? 'secondary' : event.type === 'hatching' ? 'outline' : event.type === 'chick' ? 'default' : 'secondary'}
              className={`text-xs px-3 py-1 rounded-full flex-shrink-0 ${getDotColor(event.type)} text-white`}
            >
              {getEventTypeLabel(event.type)}
            </Badge>
            {event.status && (
              <Badge 
                variant="outline" 
                className="flex-shrink-0"
              >
                {getStatusLabel(event.status)}
              </Badge>
            )}
          </div>

          {/* Date */}
          <div className="flex items-center gap-2 min-w-0">
            <Calendar className="w-4 h-4 text-muted-foreground flex-shrink-0" />
            <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
              {formatDate(event.date)}
            </span>
          </div>

          {/* Description */}
          {event.description && (
            <div className="space-y-2 min-w-0">
              <h4 className="text-base font-semibold truncate max-w-full min-w-0">
                Açıklama
              </h4>
              <p className="text-sm text-muted-foreground min-w-0">
                {event.description}
              </p>
            </div>
          )}

          {/* Bird Information */}
          {event.birdName && (
            <div className="space-y-2 min-w-0">
              <h4 className="text-sm font-medium truncate max-w-full min-w-0">
                Kuş Bilgisi
              </h4>
              <div className="flex items-center gap-2 min-w-0">
                <span className="text-lg flex-shrink-0" role="img" aria-hidden="true">🦜</span>
                <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                  {event.birdName}
                </span>
              </div>
            </div>
          )}

          {/* Parent Information */}
          {event.parentNames && (
            <div className="space-y-2 min-w-0">
              <h4 className="text-sm font-medium truncate max-w-full min-w-0">
                Ebeveyn Bilgisi
              </h4>
              <div className="flex items-center gap-2 min-w-0">
                <MapPin className="w-4 h-4 text-muted-foreground flex-shrink-0" />
                <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                  {event.parentNames}
                </span>
              </div>
            </div>
          )}

          {/* Egg Number */}
          {event.eggNumber && (
            <div className="space-y-2 min-w-0">
              <h4 className="text-sm font-medium truncate max-w-full min-w-0">
                Yumurta Numarası
              </h4>
              <div className="flex items-center gap-2 min-w-0">
                <span className="text-lg flex-shrink-0" role="img" aria-hidden="true">🥚</span>
                <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                  {event.eggNumber}. yumurta
                </span>
              </div>
            </div>
          )}

          {/* Time (if available) */}
          {event.time && (
            <div className="flex items-center gap-2 min-w-0">
              <Clock className="w-4 h-4 text-muted-foreground flex-shrink-0" />
              <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                {event.time}
              </span>
            </div>
          )}

          {/* Location (if available) */}
          {event.location && (
            <div className="flex items-center gap-2 min-w-0">
              <MapPin className="w-4 h-4 text-muted-foreground flex-shrink-0" />
              <span className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                {event.location}
              </span>
            </div>
          )}
        </div>

        {/* Close Button */}
        <div className="flex justify-end pt-4 min-w-0">
          <Button
            variant="outline"
            onClick={onClose}
            className="min-h-[44px] min-w-0"
          >
            <X className="w-4 h-4 mr-2 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">Kapat</span>
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};