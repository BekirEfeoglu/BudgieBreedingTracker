import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Clock, Settings, Globe } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { useToast } from '@/hooks/use-toast';

interface NotificationSettings {
  eggReminders: {
    enabled: boolean;
    interval: string;
    customDays?: number;
    timeOfDay: string;
  };
  generalReminders: {
    enabled: boolean;
    interval: string;
    timeOfDay: string;
  };
  timeZone: string;
  quietHours: {
    enabled: boolean;
    start: string;
    end: string;
  };
}

const NotificationCustomization: React.FC = () => {
  const { t } = useLanguage();
  const { toast } = useToast();
  
  const [settings, setSettings] = useState<NotificationSettings>({
    eggReminders: {
      enabled: true,
      interval: 'every3days',
      timeOfDay: '09:00'
    },
    generalReminders: {
      enabled: true,
      interval: 'daily',
      timeOfDay: '18:00'
    },
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    quietHours: {
      enabled: false,
      start: '22:00',
      end: '08:00'
    }
  });

  const [isSaving, setIsSaving] = useState(false);

  // Load settings from localStorage
  useEffect(() => {
    const savedSettings = localStorage.getItem('notificationCustomization');
    if (savedSettings) {
      try {
        setSettings(JSON.parse(savedSettings));
      } catch {
        // Handle error silently
      }
    }
  }, []);

  const saveSettings = async () => {
    setIsSaving(true);
    try {
      localStorage.setItem('notificationCustomization', JSON.stringify(settings));
      
      toast({
        title: 'Ayarlar Kaydedildi',
        description: 'Bildirim tercihleri başarıyla güncellendi.',
      });
    } catch {
      toast({
        title: 'Hata',
        description: 'Ayarlar kaydedilirken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsSaving(false);
    }
  };

  const updateSettings = (path: keyof NotificationSettings, value: unknown) => {
    setSettings(prev => ({
      ...prev,
      [path]: value
    }));
  };

  const updateNestedSettings = (path: keyof NotificationSettings, subPath: string, value: unknown) => {
    setSettings(prev => ({
      ...prev,
      [path]: {
        ...prev[path] as Record<string, unknown>,
        [subPath]: value
      }
    }));
  };

  const intervalOptions = [
    { value: 'daily', label: t('settings.notifications.intervalOptions.daily', 'Günlük') },
    { value: 'every2days', label: t('settings.notifications.intervalOptions.every2days', 'Her 2 Günde') },
    { value: 'every3days', label: t('settings.notifications.intervalOptions.every3days', 'Her 3 Günde') },
    { value: 'weekly', label: t('settings.notifications.intervalOptions.weekly', 'Haftalık') },
    { value: 'custom', label: t('settings.notifications.intervalOptions.custom', 'Özel') }
  ];

  const timeZones = [
    { value: 'Europe/Istanbul', label: 'İstanbul (GMT+3)' },
    { value: 'Europe/London', label: 'London (GMT+0)' },
    { value: 'America/New_York', label: 'New York (GMT-5)' },
    { value: 'Asia/Tokyo', label: 'Tokyo (GMT+9)' },
    { value: 'Australia/Sydney', label: 'Sydney (GMT+10)' }
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Settings className="w-5 h-5" />
          {t('settings.notifications.title', 'Bildirim Ayarları')}
        </CardTitle>
        <CardDescription>
          {t('settings.notifications.customization')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Egg Reminders Section */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <Label className="text-base font-medium flex items-center gap-2">
              🥚 {t('settings.notifications.eggReminder', 'Yumurta Hatırlatması')}
            </Label>
            <Switch
              checked={settings.eggReminders.enabled}
              onCheckedChange={(checked) => updateNestedSettings('eggReminders', 'enabled', checked)}
            />
          </div>

          {settings.eggReminders.enabled && (
            <div className="ml-6 space-y-3 border-l-2 border-muted pl-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <Label className="text-sm">{t('settings.notifications.selectInterval', 'Aralık Seçin')}</Label>
                  <Select
                    value={settings.eggReminders.interval}
                    onValueChange={(value) => updateNestedSettings('eggReminders', 'interval', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {intervalOptions.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-sm">{t('settings.notifications.timeOfDay')}</Label>
                  <Input
                    type="time"
                    value={settings.eggReminders.timeOfDay}
                    onChange={(e) => updateNestedSettings('eggReminders', 'timeOfDay', e.target.value)}
                  />
                </div>
              </div>

              {settings.eggReminders.interval === 'custom' && (
                <div>
                  <Label className="text-sm">{t('settings.notifications.customDays')}</Label>
                  <Input
                    type="number"
                    min="1"
                    max="30"
                    placeholder={t('settings.notifications.customDays')}
                    value={settings.eggReminders.customDays || ''}
                    onChange={(e) => updateNestedSettings('eggReminders', 'customDays', parseInt(e.target.value))}
                  />
                </div>
              )}
            </div>
          )}
        </div>

        <Separator />

        {/* General Reminders Section */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <Label className="text-base font-medium flex items-center gap-2">
              🔔 {t('settings.notifications.generalReminder', 'Genel Hatırlatmalar')}
            </Label>
            <Switch
              checked={settings.generalReminders.enabled}
              onCheckedChange={(checked) => updateNestedSettings('generalReminders', 'enabled', checked)}
            />
          </div>

          {settings.generalReminders.enabled && (
            <div className="ml-6 space-y-3 border-l-2 border-muted pl-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <Label className="text-sm">{t('settings.notifications.selectInterval', 'Aralık Seçin')}</Label>
                  <Select
                    value={settings.generalReminders.interval}
                    onValueChange={(value) => updateNestedSettings('generalReminders', 'interval', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {intervalOptions.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-sm">{t('settings.notifications.timeOfDay')}</Label>
                  <Input
                    type="time"
                    value={settings.generalReminders.timeOfDay}
                    onChange={(e) => updateNestedSettings('generalReminders', 'timeOfDay', e.target.value)}
                  />
                </div>
              </div>
            </div>
          )}
        </div>

        <Separator />

        {/* Time Zone Settings */}
        <div className="space-y-3">
          <Label className="text-base font-medium flex items-center gap-2">
            <Globe className="w-5 h-5" />
            {t('settings.notifications.timeZone', 'Saat Dilimi')}
          </Label>
          <Select
            value={settings.timeZone}
            onValueChange={(value) => updateSettings('timeZone', value)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {timeZones.map((tz) => (
                <SelectItem key={tz.value} value={tz.value}>
                  {tz.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <Separator />

        {/* Quiet Hours */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <Label className="text-base font-medium flex items-center gap-2">
              <Clock className="w-5 h-5" />
              {t('settings.notifications.quietHours', 'Sessiz Saatler')}
            </Label>
            <Switch
              checked={settings.quietHours.enabled}
              onCheckedChange={(checked) => updateNestedSettings('quietHours', 'enabled', checked)}
            />
          </div>

          {settings.quietHours.enabled && (
            <div className="ml-6 space-y-3 border-l-2 border-muted pl-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label className="text-sm">{t('settings.notifications.startTime')}</Label>
                  <Input
                    type="time"
                    value={settings.quietHours.start}
                    onChange={(e) => updateNestedSettings('quietHours', 'start', e.target.value)}
                  />
                </div>
                <div>
                  <Label className="text-sm">{t('settings.notifications.endTime')}</Label>
                  <Input
                    type="time"
                    value={settings.quietHours.end}
                    onChange={(e) => updateNestedSettings('quietHours', 'end', e.target.value)}
                  />
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Save Button */}
        <div className="flex justify-end pt-4">
          <Button onClick={saveSettings} disabled={isSaving}>
            <Settings className="w-4 h-4 mr-2" />
            {isSaving ? t('common.saving') : t('common.save')}
          </Button>
        </div>

        {/* Status */}
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Badge variant="outline">
            {settings.eggReminders.enabled ? t('settings.notifications.eggReminder') + ' ' + t('common.active') : t('settings.notifications.eggReminder') + ' ' + t('common.inactive')}
          </Badge>
          <Badge variant="outline">
            {settings.generalReminders.enabled ? t('settings.notifications.generalReminder') + ' ' + t('common.active') : t('settings.notifications.generalReminder') + ' ' + t('common.inactive')}
          </Badge>
          {settings.quietHours.enabled && (
            <Badge variant="outline">
              Sessiz Saatler: {settings.quietHours.start} - {settings.quietHours.end}
            </Badge>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default NotificationCustomization;