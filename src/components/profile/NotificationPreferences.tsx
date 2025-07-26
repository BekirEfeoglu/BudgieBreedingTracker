import React from 'react';
import { Bell, BellOff, Smartphone, Monitor } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';

interface NotificationPreferencesProps {
  preferences: {
    pushNotifications: boolean;
    localNotifications: boolean;
    eggReminders: boolean;
    breedingAlerts: boolean;
    healthReminders: boolean;
  };
  onPreferenceChange: (key: string, value: boolean) => void;
  permissionStatus: NotificationPermission;
  onRequestPermission: () => void;
}

export const NotificationPreferences: React.FC<NotificationPreferencesProps> = ({
  preferences,
  onPreferenceChange,
  permissionStatus,
  onRequestPermission
}) => {
  const preferenceSections = [
    {
      title: 'Bildirim Türleri',
      items: [
        {
          key: 'pushNotifications',
          label: 'Push Bildirimleri',
          description: 'Tarayıcı bildirimleri (internet bağlantısı gerekli)',
          icon: Monitor,
          disabled: permissionStatus !== 'granted'
        },
        {
          key: 'localNotifications',
          label: 'Yerel Bildirimler',
          description: 'Uygulama içi bildirimler',
          icon: Smartphone,
          disabled: false
        }
      ]
    },
    {
      title: 'Bildirim İçerikleri',
      items: [
        {
          key: 'eggReminders',
          label: 'Yumurta Hatırlatıcıları',
          description: 'Kuluçka süresi ve çıkış tarihi bildirimleri',
          icon: Bell,
          disabled: false
        },
        {
          key: 'breedingAlerts',
          label: 'Üreme Uyarıları',
          description: 'Çiftleşme ve kuluçka durumu bildirimleri',
          icon: Bell,
          disabled: false
        },
        {
          key: 'healthReminders',
          label: 'Sağlık Hatırlatıcıları',
          description: 'Veteriner kontrolü ve bakım hatırlatmaları',
          icon: Bell,
          disabled: false
        }
      ]
    }
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Bell className="w-5 h-5" />
          Bildirim Tercihleri
        </CardTitle>
        <CardDescription>
          Almak istediğiniz bildirim türlerini belirleyin
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Permission Status */}
        {permissionStatus !== 'granted' && (
          <div className="p-4 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <BellOff className="w-4 h-4 text-amber-600" />
                <span className="text-sm font-medium text-amber-800 dark:text-amber-200">
                  Bildirim İzni Gerekli
                </span>
              </div>
              <button
                onClick={onRequestPermission}
                className="text-sm text-amber-700 dark:text-amber-300 underline hover:no-underline"
              >
                İzin Ver
              </button>
            </div>
            <p className="text-xs text-amber-600 dark:text-amber-400 mt-1">
              Push bildirimleri almak için tarayıcı izni vermeniz gerekiyor.
            </p>
          </div>
        )}

        {/* Preference Sections */}
        {preferenceSections.map((section, sectionIndex) => (
          <div key={section.title}>
            <h4 className="text-sm font-medium mb-3 text-foreground">
              {section.title}
            </h4>
            <div className="space-y-4">
              {section.items.map((item) => {
                const IconComponent = item.icon;
                const isEnabled = preferences[item.key as keyof typeof preferences];
                const isDisabled = item.disabled;

                return (
                  <div
                    key={item.key}
                    className={`flex items-start justify-between p-3 rounded-lg border ${
                      isDisabled ? 'opacity-50 bg-muted/30' : 'bg-background'
                    }`}
                  >
                    <div className="flex items-start gap-3 flex-1">
                      <IconComponent className="w-4 h-4 mt-1 text-muted-foreground" />
                      <div className="space-y-1">
                        <Label
                          htmlFor={item.key}
                          className={`text-sm font-medium cursor-pointer ${
                            isDisabled ? 'text-muted-foreground' : ''
                          }`}
                        >
                          {item.label}
                        </Label>
                        <p className="text-xs text-muted-foreground">
                          {item.description}
                        </p>
                      </div>
                    </div>
                    <Switch
                      id={item.key}
                      checked={isEnabled}
                      onCheckedChange={(checked) => onPreferenceChange(item.key, checked)}
                      disabled={isDisabled}
                      aria-describedby={`${item.key}-description`}
                    />
                  </div>
                );
              })}
            </div>
            {sectionIndex < preferenceSections.length - 1 && (
              <Separator className="mt-6" />
            )}
          </div>
        ))}

        {/* Additional Info */}
        <div className="text-xs text-muted-foreground bg-muted/30 p-3 rounded-lg">
          <p className="font-medium mb-1">Bilgi:</p>
          <ul className="space-y-1 list-disc list-inside">
            <li>Yerel bildirimler uygulama açıkken çalışır</li>
            <li>Push bildirimleri uygulama kapalıyken de görünür</li>
            <li>Bu ayarlar sadece bu cihazda geçerlidir</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
};