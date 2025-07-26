import React, { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Bell } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface ReminderModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (reminder: ReminderData) => void;
  timeRange: string;
}

export interface ReminderData {
  type: 'analytics' | 'breeding' | 'incubation' | 'custom';
  frequency: 'daily' | 'weekly' | 'monthly';
  time: string;
  message: string;
  enabled: boolean;
}

const ReminderModal: React.FC<ReminderModalProps> = ({
  isOpen,
  onClose,
  onSave,
  timeRange
}) => {
  const { t } = useLanguage();
  const [reminderData, setReminderData] = useState<ReminderData>({
    type: 'analytics',
    frequency: 'weekly',
    time: '09:00',
    message: `${timeRange} dönemi için analitik kontrolü yapılmalı.`,
    enabled: true
  });

  const handleSave = () => {
    onSave(reminderData);
    onClose();
  };

  const getDefaultMessage = (type: string) => {
    switch (type) {
      case 'analytics':
        return `${timeRange} dönemi için analitik kontrolü yapılmalı.`;
      case 'breeding':
        return 'Üreme çiftlerinin durumu kontrol edilmeli.';
      case 'incubation':
        return 'Kuluçka durumları kontrol edilmeli.';
      case 'custom':
        return '';
      default:
        return '';
    }
  };

  const handleTypeChange = (type: string) => {
    setReminderData(prev => ({
      ...prev,
      type: type as any,
      message: getDefaultMessage(type)
    }));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px] max-w-[95vw] max-h-[90vh] overflow-y-auto" aria-describedby="reminder-modal-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bell className="w-5 h-5" />
            Hatırlatıcı Ayar
          </DialogTitle>
          <DialogDescription>
            Analitik kontrolü için hatırlatıcı ayarlayın.
          </DialogDescription>
          <div id="reminder-modal-description" className="sr-only">
            Hatırlatıcı ayarlama formu
          </div>
        </DialogHeader>

        <div className="grid gap-4 py-4 mobile-spacing-y">
          {/* Hatırlatıcı Türü */}
          <div className="grid gap-2 mobile-form-field">
            <Label htmlFor="reminderType">Hatırlatıcı Türü</Label>
            <Select value={reminderData.type} onValueChange={handleTypeChange}>
              <SelectTrigger className="mobile-form-input">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="analytics">Analitik Kontrolü</SelectItem>
                <SelectItem value="breeding">Üreme Kontrolü</SelectItem>
                <SelectItem value="incubation">Kuluçka Kontrolü</SelectItem>
                <SelectItem value="custom">Özel Hatırlatıcı</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Sıklık */}
          <div className="grid gap-2 mobile-form-field">
            <Label htmlFor="frequency">Sıklık</Label>
            <Select value={reminderData.frequency} onValueChange={(value: string) => setReminderData(prev => ({ ...prev, frequency: value as any }))}>
              <SelectTrigger className="mobile-form-input">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="daily">{t('common.daily')}</SelectItem>
                <SelectItem value="weekly">{t('common.weekly')}</SelectItem>
                <SelectItem value="monthly">{t('common.monthly')}</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Saat */}
          <div className="grid gap-2 mobile-form-field">
            <Label htmlFor="time">Saat</Label>
            <Input
              id="time"
              type="time"
              value={reminderData.time}
              onChange={(e) => setReminderData(prev => ({
                ...prev,
                time: e.target.value
              }))}
              className="mobile-form-input"
            />
          </div>

          {/* Mesaj */}
          <div className="grid gap-2 mobile-form-field">
            <Label htmlFor="message">Mesaj</Label>
            <Input
              id="message"
              placeholder="Hatırlatıcı mesajı..."
              value={reminderData.message}
              onChange={(e) => setReminderData(prev => ({
                ...prev,
                message: e.target.value
              }))}
              className="mobile-form-input"
            />
          </div>

          {/* Aktif/Pasif */}
          <div className="flex items-center justify-between">
            <Label htmlFor="enabled">Hatırlatıcıyı Aktif Et</Label>
            <Switch
              id="enabled"
              checked={reminderData.enabled}
              onCheckedChange={(checked) => setReminderData(prev => ({
                ...prev,
                enabled: checked
              }))}
            />
          </div>

          {/* Önizleme */}
          <div className="p-3 rounded-lg bg-blue-50 dark:bg-blue-950/20">
            <div className="text-sm font-medium mb-2">Hatırlatıcı Önizleme</div>
            <div className="space-y-1 text-sm">
              <div className="flex justify-between">
                <span>Tür:</span>
                <span className="font-medium">
                  {reminderData.type === 'analytics' ? 'Analitik Kontrolü' :
                   reminderData.type === 'breeding' ? 'Üreme Kontrolü' :
                   reminderData.type === 'incubation' ? 'Kuluçka Kontrolü' : 'Özel'}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Sıklık:</span>
                <span className="font-medium">
                  {reminderData.frequency === 'daily' ? t('common.daily') :
                   reminderData.frequency === 'weekly' ? t('common.weekly') : t('common.monthly')}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Saat:</span>
                <span className="font-medium">{reminderData.time}</span>
              </div>
              <div className="mt-2 p-2 bg-white dark:bg-gray-800 rounded text-xs">
                "{reminderData.message}"
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} className="mobile-form-button">
            İptal
          </Button>
          <Button onClick={handleSave} className="gap-2 mobile-form-button">
            <Bell className="w-4 h-4" />
            Hatırlatıcıyı Kaydet
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default ReminderModal; 