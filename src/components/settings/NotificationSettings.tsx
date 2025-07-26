import React, { useState, useEffect, useCallback, memo } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Slider } from '@/components/ui/slider';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Bell, Globe, Volume2, VolumeX, Thermometer, Droplets, Moon } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';

interface Settings {
  language: 'tr' | 'en';
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  eggTurningEnabled: boolean;
  eggTurningInterval: number;
  temperatureAlertsEnabled: boolean;
  temperatureMin: number;
  temperatureMax: number;
  temperatureTolerance: number;
  humidityAlertsEnabled: boolean;
  humidityMin: number;
  humidityMax: number;
  feedingRemindersEnabled: boolean;
  feedingInterval: number;
  doNotDisturbStart: string | null;
  doNotDisturbEnd: string | null;
}

const defaultSettings: Settings = {
  language: 'tr',
  soundEnabled: true,
  vibrationEnabled: true,
  eggTurningEnabled: false,
  eggTurningInterval: 240,
  temperatureAlertsEnabled: false,
  temperatureMin: 37,
  temperatureMax: 38,
  temperatureTolerance: 0.5,
  humidityAlertsEnabled: false,
  humidityMin: 55,
  humidityMax: 65,
  feedingRemindersEnabled: false,
  feedingInterval: 720,
  doNotDisturbStart: null,
  doNotDisturbEnd: null,
};

const NotificationSettings = memo(() => {
  const [settings, setSettings] = useState<Settings>(defaultSettings);
  const [isLoading, setIsLoading] = useState(true);
  const [hasPermission, setHasPermission] = useState(false);
  const { toast } = useToast();

  const scheduler = NotificationScheduler.getInstance();

  // Initialize settings
  useEffect(() => {
    const initializeSettings = async () => {
      try {
        await scheduler.initialize();
        const currentSettings = scheduler.getSettings();
        setSettings((prev: Settings) => ({ ...prev, ...currentSettings }));
        
        // Check notification permissions
        if ('Notification' in window) {
          setHasPermission(Notification.permission === 'granted');
        }
      } catch (error) {
        console.error('Error initializing notification settings:', error);
        toast({
          title: 'Hata',
          description: 'Bildirim ayarları yüklenemedi.',
          variant: 'destructive'
        });
      } finally {
        setIsLoading(false);
      }
    };

    initializeSettings();
  }, [scheduler, toast]);

  // Handle setting changes
  const handleSettingChange = useCallback(async (key: keyof Settings, value: any) => {
    if (!settings) return;

    const updatedSettings = { ...settings, [key]: value };
    setSettings(updatedSettings);

    try {
      await scheduler.updateSettings({ [key]: value });
      toast({
        title: 'Başarılı',
        description: 'Ayarlar kaydedildi.',
      });
    } catch (error) {
      console.error('Error updating settings:', error);
      toast({
        title: 'Hata',
        description: 'Ayarlar kaydedilemedi.',
        variant: 'destructive'
      });
      // Revert the change
      setSettings(settings);
    }
  }, [settings, scheduler, toast]);

  // Request permissions
  const requestPermissions = useCallback(async () => {
    try {
      if ('Notification' in window) {
        const permission = await Notification.requestPermission();
        setHasPermission(permission === 'granted');
        
        if (permission === 'granted') {
          toast({
            title: 'İzin Verildi',
            description: 'Bildirimler etkinleştirildi.',
          });
        } else {
          toast({
            title: 'İzin Reddedildi',
            description: 'Bildirimler çalışmayacak.',
            variant: 'destructive'
          });
        }
      }
    } catch (error) {
      console.error('Error requesting permissions:', error);
      toast({
        title: 'Hata',
        description: 'İzin alınamadı.',
        variant: 'destructive'
      });
    }
  }, [toast]);

  // Send test notification
  const sendTestNotification = useCallback(async () => {
    try {
      // Use the browser's Notification API directly for test
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('Test Bildirimi', {
          body: 'Bildirimler başarıyla çalışıyor!',
          icon: '/icons/icon-192x192.png',
          badge: '/icons/icon-72x72.png'
        });
        
        toast({
          title: 'Test Bildirimi',
          description: 'Bildirim gönderildi.',
        });
      } else {
        throw new Error('Bildirim izni yok');
      }
    } catch (error) {
      console.error('Error sending test notification:', error);
      toast({
        title: 'Hata',
        description: 'Test bildirimi gönderilemedi.',
        variant: 'destructive'
      });
    }
  }, [toast]);

  if (isLoading) {
    return (
      <div className="space-y-6">
        {[...Array(3)].map((_, i) => (
          <Card key={i} className="animate-pulse">
            <CardHeader>
              <div className="h-6 bg-muted rounded w-1/3"></div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="h-4 bg-muted rounded w-full"></div>
                <div className="h-4 bg-muted rounded w-2/3"></div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* İzin Durumu */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Bell className="h-5 w-5" />
            Bildirim İzinleri
          </CardTitle>
          <CardDescription>
            Bildirimlerin çalışması için tarayıcı izni gereklidir
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span>İzin Durumu:</span>
              <Badge variant={hasPermission ? 'default' : 'destructive'}>
                {hasPermission ? 'Verildi' : 'Verilmedi'}
              </Badge>
            </div>
            {!hasPermission && (
              <Button onClick={requestPermissions} variant="outline">
                İzin Ver
              </Button>
            )}
          </div>

          {hasPermission && (
            <Button onClick={sendTestNotification} variant="outline">
              Test Bildirimi Gönder
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Genel Ayarlar */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Globe className="h-5 w-5" />
            Genel Ayarlar
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Dil</Label>
              <p className="text-sm text-muted-foreground">Bildirim dilini seçin</p>
            </div>
            <Select
              value={settings.language}
              onValueChange={(value: 'tr' | 'en') => handleSettingChange('language', value)}
            >
              <SelectTrigger className="w-32">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="tr">Türkçe</SelectItem>
                <SelectItem value="en">English</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Separator />

          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label className="flex items-center gap-2">
                {settings.soundEnabled ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
                Ses
              </Label>
              <p className="text-sm text-muted-foreground">Bildirim sesi</p>
            </div>
            <Switch
              checked={settings.soundEnabled}
              onCheckedChange={(checked) => handleSettingChange('soundEnabled', checked)}
            />
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Titreşim</Label>
              <p className="text-sm text-muted-foreground">Mobil cihazlarda titreşim</p>
            </div>
            <Switch
              checked={settings.vibrationEnabled}
              onCheckedChange={(checked) => handleSettingChange('vibrationEnabled', checked)}
            />
          </div>
        </CardContent>
      </Card>

      {/* Yumurta Çevirme */}
      <Card>
        <CardHeader>
          <CardTitle>🥚 Yumurta Çevirme Hatırlatmaları</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Yumurta Çevirme Bildirimleri</Label>
              <p className="text-sm text-muted-foreground">Otomatik çevirme hatırlatmaları</p>
            </div>
            <Switch
              checked={settings.eggTurningEnabled}
              onCheckedChange={(checked) => handleSettingChange('eggTurningEnabled', checked)}
            />
          </div>

          {settings.eggTurningEnabled && (
            <div className="space-y-2">
              <Label>Çevirme Aralığı: {settings.eggTurningInterval} dakika</Label>
              <Slider
                value={[settings.eggTurningInterval]}
                onValueChange={([value]) => handleSettingChange('eggTurningInterval', value)}
                min={120}
                max={480}
                step={30}
                className="w-full"
              />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>2 saat</span>
                <span>8 saat</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Sıcaklık Uyarıları */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Thermometer className="h-5 w-5" />
            Sıcaklık Uyarıları
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Sıcaklık Uyarıları</Label>
              <p className="text-sm text-muted-foreground">Sıcaklık sınır değerleri için uyarı</p>
            </div>
            <Switch
              checked={settings.temperatureAlertsEnabled}
              onCheckedChange={(checked) => handleSettingChange('temperatureAlertsEnabled', checked)}
            />
          </div>

          {settings.temperatureAlertsEnabled && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Min. Sıcaklık (°C)</Label>
                <Input
                  type="number"
                  value={settings.temperatureMin}
                  onChange={(e) => handleSettingChange('temperatureMin', parseInt(e.target.value))}
                  min="35"
                  max="40"
                />
              </div>
              <div className="space-y-2">
                <Label>Max. Sıcaklık (°C)</Label>
                <Input
                  type="number"
                  value={settings.temperatureMax}
                  onChange={(e) => handleSettingChange('temperatureMax', parseInt(e.target.value))}
                  min="35"
                  max="40"
                />
              </div>
              <div className="space-y-2">
                <Label>Tolerans (°C)</Label>
                <Input
                  type="number"
                  step="0.1"
                  value={settings.temperatureTolerance}
                  onChange={(e) => handleSettingChange('temperatureTolerance', parseFloat(e.target.value))}
                  min="0.1"
                  max="2.0"
                />
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Nem Uyarıları */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Droplets className="h-5 w-5" />
            Nem Uyarıları
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Nem Uyarıları</Label>
              <p className="text-sm text-muted-foreground">Nem sınır değerleri için uyarı</p>
            </div>
            <Switch
              checked={settings.humidityAlertsEnabled}
              onCheckedChange={(checked) => handleSettingChange('humidityAlertsEnabled', checked)}
            />
          </div>

          {settings.humidityAlertsEnabled && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Min. Nem (%)</Label>
                <Input
                  type="number"
                  value={settings.humidityMin}
                  onChange={(e) => handleSettingChange('humidityMin', parseInt(e.target.value))}
                  min="40"
                  max="80"
                />
              </div>
              <div className="space-y-2">
                <Label>Max. Nem (%)</Label>
                <Input
                  type="number"
                  value={settings.humidityMax}
                  onChange={(e) => handleSettingChange('humidityMax', parseInt(e.target.value))}
                  min="40"
                  max="80"
                />
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Besleme Hatırlatmaları */}
      <Card>
        <CardHeader>
          <CardTitle>🍽️ Besleme Hatırlatmaları</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label>Besleme Hatırlatmaları</Label>
              <p className="text-sm text-muted-foreground">Düzenli besleme hatırlatmaları</p>
            </div>
            <Switch
              checked={settings.feedingRemindersEnabled}
              onCheckedChange={(checked) => handleSettingChange('feedingRemindersEnabled', checked)}
            />
          </div>

          {settings.feedingRemindersEnabled && (
            <div className="space-y-2">
              <Label>Besleme Aralığı: {Math.floor(settings.feedingInterval / 60)} saat</Label>
              <Slider
                value={[settings.feedingInterval]}
                onValueChange={([value]) => handleSettingChange('feedingInterval', value)}
                min={360}
                max={1440}
                step={60}
                className="w-full"
              />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>6 saat</span>
                <span>24 saat</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Rahatsız Etme Saatleri */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Moon className="h-5 w-5" />
            Rahatsız Etme Saatleri
          </CardTitle>
          <CardDescription>
            Bu saatler arasında bildirim gönderilmez
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Başlangıç Saati</Label>
              <Input
                type="time"
                value={settings.doNotDisturbStart || ''}
                onChange={(e) => handleSettingChange('doNotDisturbStart', e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Bitiş Saati</Label>
              <Input
                type="time"
                value={settings.doNotDisturbEnd || ''}
                onChange={(e) => handleSettingChange('doNotDisturbEnd', e.target.value)}
              />
            </div>
          </div>

          {settings.doNotDisturbStart && settings.doNotDisturbEnd && (
            <div className="p-3 bg-muted rounded-lg">
              <p className="text-sm">
                <Moon className="h-4 w-4 inline mr-1" />
                {settings.doNotDisturbStart} - {settings.doNotDisturbEnd} arası bildirim gönderilmeyecek
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
});

NotificationSettings.displayName = 'NotificationSettings';

export default NotificationSettings;