import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Trash2, Clock, Bell } from 'lucide-react';
import { NotificationData } from '@/services/notification/PushNotificationService';
import { useLanguage } from '@/contexts/LanguageContext';

interface NotificationListProps {
  notifications: NotificationData[];
  onDelete: (id: string) => void;
  onToggle: (id: string) => void;
}

export const NotificationList: React.FC<NotificationListProps> = ({
  notifications,
  onDelete,
  onToggle
}) => {
  const { t } = useLanguage();

  const getTypeIcon = (type: NotificationData['type']) => {
    switch (type) {
      case 'incubation': return '🥚';
      case 'feeding': return '🍽️';
      case 'veterinary': return '🏥';
      case 'breeding': return '❤️';
      case 'event': return '📅';
      default: return '🔔';
    }
  };

  const getTypeLabel = (type: NotificationData['type']) => {
    switch (type) {
      case 'incubation': return 'Kuluçka';
      case 'feeding': return 'Beslenme';
      case 'veterinary': return 'Veteriner';
      case 'breeding': return 'Üreme';
      case 'event': return 'Etkinlik';
      default: return 'Bildirim';
    }
  };

  const getTimeUntil = (date: Date) => {
    const now = Date.now();
    const timeUntil = date.getTime() - now;
    
    if (timeUntil <= 0) {
      return 'Zamanı geçti';
    }

    const days = Math.floor(timeUntil / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeUntil % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeUntil % (1000 * 60 * 60)) / (1000 * 60));

    if (days > 0) {
      return `${days} gün ${hours} saat sonra`;
    } else if (hours > 0) {
      return `${hours} saat ${minutes} dakika sonra`;
    } else {
      return `${minutes} dakika sonra`;
    }
  };

  const getStatusBadge = (notification: NotificationData) => {
    const now = Date.now();
    const timeUntil = notification.scheduledFor.getTime() - now;
    
    if (timeUntil <= 0) {
      return <Badge variant="destructive">Zamanı Geçti</Badge>;
    } else if (timeUntil <= 60 * 60 * 1000) { // 1 saat içinde
      return <Badge variant="default">Yakında</Badge>;
    } else if (timeUntil <= 24 * 60 * 60 * 1000) { // 24 saat içinde
      return <Badge variant="secondary">Bugün</Badge>;
    } else {
      return <Badge variant="outline">Planlandı</Badge>;
    }
  };

  if (notifications.length === 0) {
    return (
      <div className="text-center py-12">
        <Bell className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
        <h3 className="text-lg font-medium text-muted-foreground mb-2">
          Henüz bildirim yok
        </h3>
        <p className="text-sm text-muted-foreground">
          Yeni hatırlatıcılar oluşturarak başlayın
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {notifications.map((notification) => (
        <Card key={notification.id} className="hover:shadow-md transition-shadow">
          <CardContent className="p-4">
            <div className="flex items-start justify-between">
              <div className="flex items-start gap-3 flex-1">
                <div className="text-2xl">
                  {getTypeIcon(notification.type)}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-medium text-sm truncate">
                      {notification.title}
                    </h4>
                    {getStatusBadge(notification)}
                  </div>
                  
                  <p className="text-sm text-muted-foreground mb-2 line-clamp-2">
                    {notification.message}
                  </p>
                  
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      <span>{notification.scheduledFor.toLocaleString('tr-TR')}</span>
                    </div>
                    
                    <div className="flex items-center gap-1">
                      <span>{getTypeLabel(notification.type)}</span>
                    </div>
                    
                    {notification.repeatInterval && notification.repeatInterval !== 'once' && (
                      <Badge variant="outline" className="text-xs">
                        {notification.repeatInterval === 'daily' && t('common.daily')}
                        {notification.repeatInterval === 'twice_daily' && 'Günde 2x'}
                        {notification.repeatInterval === 'weekly' && t('common.weekly')}
                        {notification.repeatInterval === 'monthly' && t('common.monthly')}
                      </Badge>
                    )}
                  </div>
                  
                  <div className="mt-2">
                    <span className="text-xs text-muted-foreground">
                      {getTimeUntil(notification.scheduledFor)}
                    </span>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center gap-2 ml-4">
                <div className="flex items-center gap-2">
                  <Switch
                    checked={notification.isActive}
                    onCheckedChange={() => onToggle(notification.id)}
                  />
                  <span className="text-xs text-muted-foreground">
                    {notification.isActive ? 'Aktif' : 'Pasif'}
                  </span>
                </div>
                
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => onDelete(notification.id)}
                  className="text-destructive hover:text-destructive"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}; 