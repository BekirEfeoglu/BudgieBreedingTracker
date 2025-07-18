import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { Bell, BellOff, Clock, Trash2, Info, CheckCircle, Calendar, Thermometer, Droplets, RotateCcw } from 'lucide-react';
import { NotificationScheduler } from '@/services/notification/NotificationScheduler';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { useIsMobile } from '@/hooks/use-mobile';
import { formatDistanceToNow } from 'date-fns';
import { tr } from 'date-fns/locale';
import { useLanguage } from '@/contexts/LanguageContext';

interface NotificationItem {
  id: string;
  notification_id: string;
  action: string;
  timestamp: string | null;
  metadata?: any;
}

interface ScheduledNotification {
  id: number;
  title: string;
  body: string;
  schedule: {
    at: Date;
  };
  extra?: any;
}

interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'success' | 'error' | 'warning' | 'info';
  timestamp: Date;
  read: boolean;
  category?: string;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  expiresAt?: Date;
  actions?: Array<{
    label: string;
    action: string;
    primary?: boolean;
  }>;
  icon?: string;
  imageUrl?: string;
  metadata?: unknown;
  extra?: unknown;
}

const NotificationCenter = () => {
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [scheduledNotifications, setScheduledNotifications] = useState<ScheduledNotification[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();
  const isMobile = useIsMobile();
  const { t } = useLanguage();

  const scheduler = NotificationScheduler.getInstance();

  useEffect(() => {
    loadNotifications();
    loadScheduledNotifications();
  }, []);

  const loadNotifications = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data, error } = await supabase
          .from('notification_interactions')
          .select('*')
          .eq('user_id', user.id)
          .order('timestamp', { ascending: false })
          .limit(50);

        if (error) throw error;
        setNotifications((data || []).filter(n => n.timestamp !== null));
      }
    } catch (error) {
      console.error('Error loading notifications:', error);
      toast({
        title: 'Hata',
        description: 'Bildirimler yüklenemedi.',
        variant: 'destructive'
      });
    }
  };

  const loadScheduledNotifications = async () => {
    try {
      // Capacitor LocalNotifications'dan planlanmış bildirimleri al
      const { LocalNotifications } = await import('@capacitor/local-notifications');
      const pending = await LocalNotifications.getPending();
      setScheduledNotifications(pending.notifications as ScheduledNotification[]);
    } catch (error) {
      console.error('Error loading scheduled notifications:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const cancelNotification = async (notificationId: string) => {
    try {
      await scheduler.cancelNotification(notificationId);
      await loadScheduledNotifications();
      toast({
        title: 'Başarılı',
        description: 'Bildirim iptal edildi.',
      });
    } catch (error) {
      console.error('Error canceling notification:', error);
      toast({
        title: 'Hata',
        description: 'Bildirim iptal edilemedi.',
        variant: 'destructive'
      });
    }
  };

  const cancelAllNotifications = async () => {
    try {
      await scheduler.cancelAllNotifications();
      await loadScheduledNotifications();
      toast({
        title: 'Başarılı',
        description: 'Tüm bildirimler iptal edildi.',
      });
    } catch (error) {
      console.error('Error canceling all notifications:', error);
      toast({
        title: 'Hata',
        description: 'Bildirimler iptal edilemedi.',
        variant: 'destructive'
      });
    }
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'egg_turning':
        return <RotateCcw className="h-4 w-4" />;
      case 'temperature_alert':
        return <Thermometer className="h-4 w-4" />;
      case 'humidity_alert':
        return <Droplets className="h-4 w-4" />;
      case 'incubation_milestone':
        return <Calendar className="h-4 w-4" />;
      case 'feeding_schedule':
        return <Clock className="h-4 w-4" />;
      default:
        return <Bell className="h-4 w-4" />;
    }
  };

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'egg_turning':
        return 'bg-blue-500';
      case 'temperature_alert':
        return 'bg-red-500';
      case 'humidity_alert':
        return 'bg-cyan-500';
      case 'incubation_milestone':
        return 'bg-green-500';
      case 'feeding_schedule':
        return 'bg-orange-500';
      default:
        return 'bg-gray-500';
    }
  };

  const formatTime = (timestamp: string) => {
    return formatDistanceToNow(new Date(timestamp), {
      addSuffix: true,
      locale: tr
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="animate-pulse space-y-4">
          <div className="h-4 bg-muted rounded w-3/4"></div>
          <div className="h-4 bg-muted rounded w-1/2"></div>
          <div className="h-4 bg-muted rounded w-2/3"></div>
        </div>
      </div>
    );
  }

  return (
    <div className={`space-y-4 ${isMobile ? 'pb-4' : 'pb-6'}`}>
      {/* Planlanmış Bildirimler */}
      <Card className={`${isMobile ? 'p-1' : 'p-2 sm:p-4'} border-border/50`}>
        <CardHeader className={`${isMobile ? 'p-3 pb-2' : 'p-4 pb-3'}`}>
          <div className={`flex items-center justify-between ${isMobile ? 'gap-2' : 'gap-4'}`}>
            <div>
              <CardTitle className={`flex items-center gap-2 ${isMobile ? 'text-base' : 'text-lg'}`}>
                <Clock className={`${isMobile ? 'h-4 w-4' : 'h-5 w-5'}`} />
                Planlanmış Bildirimler
              </CardTitle>
              <CardDescription className={`${isMobile ? 'text-xs' : 'text-sm'}`}>
                Yaklaşan bildirimler ({scheduledNotifications.length})
              </CardDescription>
            </div>
            {scheduledNotifications.length > 0 && (
              <Button 
                variant="outline" 
                size={isMobile ? "sm" : "sm"}
                onClick={cancelAllNotifications}
                className={`text-destructive hover:text-destructive ${isMobile ? 'text-xs px-2' : ''}`}
              >
                <Trash2 className={`${isMobile ? 'h-3 w-3 mr-1' : 'h-4 w-4 mr-2'}`} />
                {isMobile ? 'Tümü' : 'Tümünü İptal Et'}
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent className={`${isMobile ? 'p-3 pt-0' : 'p-4 pt-0'}`}>
          {scheduledNotifications.length === 0 ? (
            <div className={`text-center ${isMobile ? 'py-4' : 'py-8'} text-muted-foreground`}>
              <BellOff className={`${isMobile ? 'h-8 w-8' : 'h-12 w-12'} mx-auto mb-4 opacity-50`} />
              <p className={`${isMobile ? 'text-sm' : 'text-base'}`}>Planlanmış bildirim bulunmuyor</p>
            </div>
          ) : (
            <ScrollArea className={`${isMobile ? 'h-48' : 'h-64'}`}>
              <div className="space-y-3">
                {scheduledNotifications.map((notification) => (
                  <div key={notification.id} className={`flex items-center justify-between ${isMobile ? 'p-2' : 'p-3'} border rounded-lg overflow-x-auto`}>
                    <div className="flex items-start gap-3">
                      <div className={`${isMobile ? 'p-1.5' : 'p-2'} rounded-full text-white ${getNotificationColor(notification.extra?.type || 'default')}`}>
                        {getNotificationIcon(notification.extra?.type || 'default')}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className={`font-medium truncate ${isMobile ? 'text-sm max-w-[100px]' : 'text-base max-w-[120px] sm:max-w-xs'}`}>
                          {notification.title}
                        </h4>
                        <p className={`text-muted-foreground truncate ${isMobile ? 'text-xs max-w-[150px]' : 'text-sm max-w-[180px] sm:max-w-full'}`}>
                          {notification.body}
                        </p>
                        <p className={`text-muted-foreground mt-1 ${isMobile ? 'text-xs' : 'text-xs'}`}>
                          {formatTime(notification.schedule.at.toISOString())}
                        </p>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size={isMobile ? "sm" : "sm"}
                      onClick={() => cancelNotification(notification.id.toString())}
                      className={`text-destructive hover:text-destructive ${isMobile ? 'min-h-[36px] min-w-[36px]' : 'min-h-[44px] min-w-[44px]'}`}
                    >
                      <Trash2 className={`${isMobile ? 'h-3 w-3' : 'h-4 w-4'}`} />
                    </Button>
                  </div>
                ))}
              </div>
            </ScrollArea>
          )}
        </CardContent>
      </Card>

      {/* Bildirim Geçmişi */}
      <Card className={`${isMobile ? 'p-1' : 'p-2 sm:p-4'} border-border/50`}>
        <CardHeader className={`${isMobile ? 'p-3 pb-2' : 'p-4 pb-3'}`}>
          <CardTitle className={`flex items-center gap-2 ${isMobile ? 'text-base' : 'text-lg'}`}>
            <Bell className={`${isMobile ? 'h-4 w-4' : 'h-5 w-5'}`} />
            Bildirim Geçmişi
          </CardTitle>
          <CardDescription className={`${isMobile ? 'text-xs' : 'text-sm'}`}>
            Son etkileşimlerin geçmişi ({notifications.length})
          </CardDescription>
        </CardHeader>
        <CardContent className={`${isMobile ? 'p-3 pt-0' : 'p-4 pt-0'}`}>
          {notifications.length === 0 ? (
            <div className={`text-center ${isMobile ? 'py-4' : 'py-8'} text-muted-foreground`}>
              <Info className={`${isMobile ? 'h-8 w-8' : 'h-12 w-12'} mx-auto mb-4 opacity-50`} />
              <p className={`${isMobile ? 'text-sm' : 'text-base'}`}>Bildirim geçmişi bulunmuyor</p>
            </div>
          ) : (
            <ScrollArea className={`${isMobile ? 'h-40' : 'h-96'}`}>
              <div className="space-y-3">
                {notifications.map((notification, index) => (
                  <div key={notification.id}>
                    <div className={`flex items-center justify-between ${isMobile ? 'p-2' : 'p-3'}`}>
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-2">
                          {notification.action === 'received' && (
                            <Badge variant="secondary" className={`${isMobile ? 'text-xs' : 'text-xs'}`}>
                              <Bell className={`${isMobile ? 'h-2 w-2' : 'h-3 w-3'} mr-1`} />
                              Alındı
                            </Badge>
                          )}
                          {notification.action === 'clicked' && (
                            <Badge variant="default" className={`${isMobile ? 'text-xs' : 'text-xs'}`}>
                              <CheckCircle className={`${isMobile ? 'h-2 w-2' : 'h-3 w-3'} mr-1`} />
                              Tıklandı
                            </Badge>
                          )}
                          {notification.action === 'dismissed' && (
                            <Badge variant="destructive" className={`${isMobile ? 'text-xs' : 'text-xs'}`}>
                              <Trash2 className={`${isMobile ? 'h-2 w-2' : 'h-3 w-3'} mr-1`} />
                              Reddedildi
                            </Badge>
                          )}
                        </div>
                        <div>
                          <p className={`font-medium ${isMobile ? 'text-xs' : 'text-sm'}`}>
                            ID: {notification.notification_id}
                          </p>
                                                     <p className={`text-muted-foreground ${isMobile ? 'text-xs' : 'text-xs'}`}>
                             {notification.timestamp ? formatTime(notification.timestamp) : t('common.unknown')}
                           </p>
                        </div>
                      </div>
                      
                      {notification.metadata && !isMobile && (
                        <div className="text-xs text-muted-foreground">
                          <pre className="max-w-xs truncate">
                            {JSON.stringify(notification.metadata, null, 2)}
                          </pre>
                        </div>
                      )}
                    </div>
                    {index < notifications.length - 1 && <Separator />}
                  </div>
                ))}
              </div>
            </ScrollArea>
          )}
        </CardContent>
      </Card>

      {/* İstatistikler */}
      <Card className={`${isMobile ? 'p-1' : 'p-2 sm:p-4'} border-border/50`}>
        <CardHeader className={`${isMobile ? 'p-3 pb-2' : 'p-4 pb-3'}`}>
          <CardTitle className={`${isMobile ? 'text-base' : 'text-lg'}`}>📊 İstatistikler</CardTitle>
        </CardHeader>
        <CardContent className={`${isMobile ? 'p-3 pt-0' : 'p-4 pt-0'}`}>
          <div className={`grid grid-cols-2 ${isMobile ? 'gap-2' : 'gap-4 sm:grid-cols-4'}`}>
            <div className="text-center">
              <div className={`font-bold text-primary ${isMobile ? 'text-xl' : 'text-2xl'}`}>
                {scheduledNotifications.length}
              </div>
              <div className={`text-muted-foreground ${isMobile ? 'text-xs' : 'text-sm'}`}>Planlanmış</div>
            </div>
            <div className="text-center">
              <div className={`font-bold text-green-600 ${isMobile ? 'text-xl' : 'text-2xl'}`}>
                {notifications.filter(n => n.action === 'received').length}
              </div>
              <div className={`text-muted-foreground ${isMobile ? 'text-xs' : 'text-sm'}`}>Alınan</div>
            </div>
            <div className="text-center">
              <div className={`font-bold text-blue-600 ${isMobile ? 'text-xl' : 'text-2xl'}`}>
                {notifications.filter(n => n.action === 'clicked').length}
              </div>
              <div className={`text-muted-foreground ${isMobile ? 'text-xs' : 'text-sm'}`}>Tıklanan</div>
            </div>
            <div className="text-center">
              <div className={`font-bold text-red-600 ${isMobile ? 'text-xl' : 'text-2xl'}`}>
                {notifications.filter(n => n.action === 'dismissed').length}
              </div>
              <div className={`text-muted-foreground ${isMobile ? 'text-xs' : 'text-sm'}`}>Reddedilen</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default NotificationCenter;