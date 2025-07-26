import React, { useState, useCallback } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Calendar, X, Save } from 'lucide-react';
import { Event } from '@/types/calendar';
import { useLanguage } from '@/contexts/LanguageContext';
import { format } from 'date-fns';

interface EventFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (event: Omit<Event, 'id'>) => void;
  selectedDate?: Date;
  editingEvent?: Event | null;
}

const EventForm = ({ isOpen, onClose, onSave, selectedDate, editingEvent }: EventFormProps) => {
  const { t } = useLanguage();
  
  // Reset form when modal opens/closes or editingEvent changes
  React.useEffect(() => {
    if (isOpen) {
      setFormData({
        title: editingEvent?.title || '',
        description: editingEvent?.description || '',
        type: editingEvent?.type || 'custom',
        date: selectedDate ? format(selectedDate, 'yyyy-MM-dd') : editingEvent?.date || format(new Date(), 'yyyy-MM-dd'),
        icon: editingEvent?.icon || '📅',
        color: editingEvent?.color || 'bg-blue-100 text-blue-800 border-blue-200'
      });
    }
  }, [isOpen, editingEvent, selectedDate]);

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    type: 'custom' as Event['type'],
    date: format(new Date(), 'yyyy-MM-dd'),
    icon: '📅',
    color: 'bg-blue-100 text-blue-800 border-blue-200'
  });

  const eventTypes = [
    { value: 'custom', label: 'Özel', icon: '📅' },
    { value: 'breeding', label: 'Üreme', icon: '🥚' },
    { value: 'health', label: 'Sağlık', icon: '🏥' },
    { value: 'feeding', label: 'Beslenme', icon: '🍎' },
    { value: 'cleaning', label: 'Temizlik', icon: '🧹' },
    { value: 'mating', label: 'Çiftleşme', icon: '💕' },
    { value: 'egg', label: 'Yumurta', icon: '🥚' },
    { value: 'chick', label: 'Yavru', icon: '🐤' }
  ];

  const colorOptions = [
    { value: 'bg-blue-100 text-blue-800 border-blue-200', label: 'Mavi' },
    { value: 'bg-green-100 text-green-800 border-green-200', label: 'Yeşil' },
    { value: 'bg-orange-100 text-orange-800 border-orange-200', label: 'Turuncu' },
    { value: 'bg-red-100 text-red-800 border-red-200', label: 'Kırmızı' },
    { value: 'bg-purple-100 text-purple-800 border-purple-200', label: 'Mor' },
    { value: 'bg-yellow-100 text-yellow-800 border-yellow-200', label: 'Sarı' },
    { value: 'bg-gray-100 text-gray-800 border-gray-200', label: 'Gri' }
  ];

  const iconOptions = [
    '📅', '🥚', '🐤', '🐣', '🏥', '🍎', '🧹', '💕', '📝', '🎯', '⭐', '🔥', '💧', '🌱', '🌞', '🌙'
  ];

  const handleInputChange = useCallback((field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  }, []);

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim()) {
      // TODO: Show error message
      return;
    }

    if (!formData.date) {
      // TODO: Show error message
      return;
    }

    // Validate date is not in the past for future events
    const selectedDate = new Date(formData.date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    if (selectedDate < today && formData.type === 'custom') {
      // TODO: Show warning for past dates
    }

    const newEvent: Omit<Event, 'id'> = {
      date: formData.date,
      title: formData.title.trim(),
      description: formData.description.trim(),
      type: formData.type as Event['type'],
      icon: formData.icon,
      color: formData.color,
      status: 'active'
    };

    onSave(newEvent);
    onClose();
  }, [formData, onSave, onClose]);

  const handleClose = useCallback(() => {
    setFormData({
      title: '',
      description: '',
      type: 'custom',
      date: format(new Date(), 'yyyy-MM-dd'),
      icon: '📅',
      color: 'bg-blue-100 text-blue-800 border-blue-200'
    });
    onClose();
  }, [onClose]);

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="mobile-modal-large min-w-0" aria-describedby="event-form-description">
        <DialogHeader className="min-w-0">
          <DialogTitle className="flex items-center gap-2 truncate max-w-full min-w-0">
            <Calendar className="w-5 h-5 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">
              {editingEvent ? t('calendar.editEvent', 'Etkinlik Düzenle') : t('calendar.addEvent', 'Etkinlik Ekle')}
            </span>
          </DialogTitle>
          <DialogDescription className="truncate max-w-full min-w-0">
            {editingEvent 
              ? t('calendar.editEventDescription', 'Mevcut etkinliği düzenleyin')
              : t('calendar.addEventDescription', 'Yeni bir etkinlik ekleyin')
            }
          </DialogDescription>
          <div id="event-form-description" className="sr-only">
            {editingEvent ? 'Etkinlik düzenleme formu' : 'Yeni etkinlik ekleme formu'}
          </div>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 min-w-0">
          {/* Event Type */}
          <div className="space-y-2 min-w-0">
            <Label htmlFor="type" className="text-sm font-medium truncate max-w-full min-w-0">
              {t('calendar.eventType', 'Etkinlik Türü')}
            </Label>
            <Select value={formData.type} onValueChange={(value) => handleInputChange('type', value)}>
              <SelectTrigger className="min-h-[44px] min-w-0">
                <SelectValue placeholder={t('calendar.selectEventType', 'Etkinlik türü seçin')} />
              </SelectTrigger>
              <SelectContent>
                {eventTypes.map((type) => (
                  <SelectItem key={type.value} value={type.value}>
                    <span className="flex items-center gap-2 min-w-0">
                      <span className="flex-shrink-0">{type.icon}</span>
                      <span className="truncate max-w-full min-w-0">{type.label}</span>
                    </span>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Date */}
          <div className="space-y-2 min-w-0">
            <Label htmlFor="date" className="text-sm font-medium truncate max-w-full min-w-0">
              {t('calendar.date', 'Tarih')}
            </Label>
            <Input
              id="date"
              type="date"
              value={formData.date}
              onChange={(e) => handleInputChange('date', e.target.value)}
              className="min-h-[44px] min-w-0"
              required
            />
          </div>

          {/* Title */}
          <div className="space-y-2 min-w-0">
            <Label htmlFor="title" className="text-sm font-medium truncate max-w-full min-w-0">
              {t('calendar.title', 'Başlık')}
            </Label>
            <Input
              id="title"
              type="text"
              value={formData.title}
              onChange={(e) => handleInputChange('title', e.target.value)}
              placeholder={t('calendar.eventTitlePlaceholder', 'Etkinlik başlığı')}
              className="min-h-[44px] min-w-0"
              required
            />
          </div>

          {/* Description */}
          <div className="space-y-2 min-w-0">
            <Label htmlFor="description" className="text-sm font-medium truncate max-w-full min-w-0">
              {t('calendar.description', 'Açıklama')}
            </Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => handleInputChange('description', e.target.value)}
              placeholder={t('calendar.eventDescriptionPlaceholder', 'Etkinlik açıklaması (isteğe bağlı)')}
              className="min-h-[80px] min-w-0 resize-none"
              rows={3}
            />
          </div>

          {/* Icon and Color Selection */}
          <div className="grid grid-cols-2 gap-4 min-w-0">
            {/* Icon */}
            <div className="space-y-2 min-w-0">
              <Label className="text-sm font-medium truncate max-w-full min-w-0">
                {t('calendar.icon', 'İkon')}
              </Label>
              <div className="border rounded-md p-3 min-w-0">
                <div className="grid grid-cols-4 gap-2 min-w-0">
                  {iconOptions.map((icon) => (
                    <button
                      key={icon}
                      type="button"
                      onClick={() => handleInputChange('icon', icon)}
                      className={`
                        p-2 rounded-md text-lg min-w-0 transition-colors
                        ${formData.icon === icon 
                          ? 'bg-primary text-primary-foreground ring-2 ring-primary ring-offset-2' 
                          : 'hover:bg-muted'
                        }
                      `}
                      aria-label={`İkon seç: ${icon}`}
                    >
                      {icon}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Color */}
            <div className="space-y-2 min-w-0">
              <Label className="text-sm font-medium truncate max-w-full min-w-0">
                {t('calendar.color', 'Renk')}
              </Label>
              <Select value={formData.color} onValueChange={(value) => handleInputChange('color', value)}>
                <SelectTrigger className="min-h-[44px] min-w-0">
                  <SelectValue>
                    <span className="flex items-center gap-2 min-w-0">
                      <div className={`w-4 h-4 rounded-full ${formData.color.split(' ')[0]} flex-shrink-0`}></div>
                      <span className="truncate max-w-full min-w-0">Renk</span>
                    </span>
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  {colorOptions.map((color) => (
                    <SelectItem key={color.value} value={color.value}>
                      <span className="flex items-center gap-2 min-w-0">
                        <div className={`w-4 h-4 rounded-full ${color.value.split(' ')[0]} flex-shrink-0`}></div>
                        <span className="truncate max-w-full min-w-0">{color.label}</span>
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4 min-w-0">
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              className="flex-1 min-h-[44px] min-w-0"
            >
              <X className="w-4 h-4 mr-2 flex-shrink-0" />
              <span className="truncate max-w-full min-w-0">{t('common.cancel', 'İptal')}</span>
            </Button>
            <Button
              type="submit"
              className="flex-1 min-h-[44px] min-w-0"
            >
              <Save className="w-4 h-4 mr-2 flex-shrink-0" />
              <span className="truncate max-w-full min-w-0">
                {editingEvent ? t('common.save', 'Kaydet') : t('common.add', 'Ekle')}
              </span>
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default EventForm; 