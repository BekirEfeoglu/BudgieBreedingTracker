import { X, Trash2, Bell, Clock, Egg, Baby, Calendar, Info } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';
import { useNotifications, type Notification } from '@/hooks/useNotifications';
import { formatDistanceToNow } from 'date-fns';
import { tr } from 'date-fns/locale';
import { useIsMobile } from '@/hooks/use-mobile';
import { useNavigate } from 'react-router-dom';

interface NotificationPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

const getNotificationIcon = (type: Notification['type']) => {
  switch (type) {
    case 'egg':
      return <Egg className="h-4 w-4 text-orange-500" />;
    case 'chick':
      return <Baby className="h-4 w-4 text-yellow-500" />;
    case 'breeding':
      return <Bell className="h-4 w-4 text-blue-500" />;
    case 'reminder':
      return <Clock className="h-4 w-4 text-purple-500" />;
    default:
      return <Info className="h-4 w-4 text-gray-500" />;
  }
};

const getNotificationColor = (type: Notification['type']) => {
  switch (type) {
    case 'egg':
      return 'border-l-orange-500';
    case 'chick':
      return 'border-l-yellow-500';
    case 'breeding':
      return 'border-l-blue-500';
    case 'reminder':
      return 'border-l-purple-500';
    default:
      return 'border-l-gray-500';
  }
};

export const NotificationPanel = ({ isOpen, onClose }: NotificationPanelProps) => {
  const { 
    notifications, 
    markAsRead, 
    deleteNotification, 
    clearAllNotifications 
  } = useNotifications();
  const isMobile = useIsMobile();
  const navigate = useNavigate();

  const handleNotificationClick = (notification: Notification) => {
    if (!notification.read) {
      markAsRead(notification.id);
    }
    
    // Bildirim türüne göre yönlendirme
    switch (notification.type) {
      case 'egg':
        navigate('/?tab=breeding');
        break;
      case 'chick':
        navigate('/?tab=chicks');
        break;
      case 'breeding':
        navigate('/?tab=breeding');
        break;
      default:
        break;
    }
    
    onClose();
  };

  const handleDeleteNotification = (e: React.MouseEvent, notificationId: string) => {
    e.stopPropagation();
    deleteNotification(notificationId);
  };

  const handleClearAll = () => {
    clearAllNotifications();
  };

  // Modal arka planı (mobilde tam ekran karartma)
  if (isMobile && isOpen) {
    return (
      <div className="fixed inset-0 z-[999] flex items-start justify-end bg-black/60">
        <div className="relative w-full h-full bg-white rounded-t-2xl shadow-2xl animate-slide-up border border-border/30">
          {/* Kapatma butonu */}
          <button
            type="button"
            className="absolute top-4 right-4 z-10 bg-background/80 rounded-full p-2 shadow-md border border-border/30"
            onClick={onClose}
            aria-label="Kapat"
          >
            <X className="h-6 w-6 text-destructive" />
          </button>
          {/* Panel içeriği */}
          <div className="pt-14 pb-4 px-4 text-black">
            {/* Header */}
            <div className="flex items-center justify-between p-6 pb-4 border-b border-border/50 text-black">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary/10 rounded-full">
                  <Bell className="h-4 w-4 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold text-black text-lg">
                    Bildirimler
                  </h3>
                  {notifications.length > 0 && (
                    <Badge variant="secondary" className="mt-0.5 text-sm text-black bg-gray-100">
                      {notifications.length} bildirim
                    </Badge>
                  )}
                </div>
              </div>
            </div>

            {/* Clear All Button */}
            {notifications.length > 0 && (
              <div className="border-b border-border/30 p-4">
                <Button
                  variant="outline"
                  size="default"
                  onClick={clearAllNotifications}
                  className="w-full flex items-center gap-2 text-destructive hover:bg-destructive/10 hover:border-destructive/30 border-destructive/20"
                >
                  <Trash2 className="h-4 w-4" />
                  Tüm Bildirimleri Temizle
                </Button>
              </div>
            )}

            {/* Notifications List */}
            <ScrollArea className="h-[calc(100vh-200px)]">
              <div className="p-4 text-black">
                {notifications.length === 0 ? (
                  <div className="flex flex-col items-center justify-center text-center py-10">
                    <div className="bg-muted/30 rounded-full mb-2 p-3">
                      <Bell className="text-muted-foreground/50 h-8 w-8" />
                    </div>
                    <h4 className="font-medium text-black mb-1 text-base">Hiç bildiriminiz yok</h4>
                    <p className="text-gray-500 text-sm">Yeni bildirimler burada görünecek</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {notifications.map((notification) => (
                      <Card 
                        key={notification.id}
                        className={`cursor-pointer transition-all hover:shadow-lg border-l-4 ${getNotificationColor(notification.type)} ${
                          !notification.read ? 'bg-primary/5 border-primary/20' : 'bg-white'
                        } p-4 text-black`}
                        onClick={() => handleNotificationClick(notification)}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-start gap-2 flex-1 min-w-0">
                            <div className="flex-shrink-0 mt-0.5 bg-gray-100 rounded-full p-2">
                              {getNotificationIcon(notification.type)}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-1">
                                <h4 className="font-medium truncate text-black text-sm">
                                  {notification.title}
                                </h4>
                                {!notification.read && (
                                  <div className="w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0 animate-pulse" />
                                )}
                              </div>
                              <p className="text-gray-600 mb-2 line-clamp-2 text-sm">
                                {notification.message}
                              </p>
                              <div className="flex items-center gap-1 text-gray-500 text-sm">
                                <Calendar className="h-4 w-4" />
                                <span>
                                  {formatDistanceToNow(notification.timestamp, { 
                                    addSuffix: true,
                                    locale: tr 
                                  })}
                                </span>
                              </div>
                            </div>
                          </div>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={(e) => handleDeleteNotification(e, notification.id)}
                            className="text-gray-400 hover:text-destructive hover:bg-destructive/10 flex-shrink-0 rounded-full h-8 w-8"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </Card>
                    ))}
                  </div>
                )}
              </div>
            </ScrollArea>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`w-full ${isMobile ? 'h-full' : 'max-w-md'}`}>
      {/* Header */}
      <div className={`flex items-center justify-between ${isMobile ? 'p-6 pb-4' : 'p-4 pb-3'} border-b border-border/50`}>
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary/10 rounded-full">
            <Bell className="h-4 w-4 text-primary" />
          </div>
          <div>
            <h3 className={`font-semibold text-foreground ${isMobile ? 'text-lg' : 'text-sm'}`}>
              Bildirimler
            </h3>
            {notifications.length > 0 && (
              <Badge variant="secondary" className={`mt-0.5 ${isMobile ? 'text-sm' : 'text-xs'}`}>
                {notifications.length} bildirim
              </Badge>
            )}
          </div>
        </div>
        {!isMobile && (
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="h-8 w-8 rounded-full hover:bg-destructive/10 hover:text-destructive"
          >
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>

      {/* Clear All Button */}
      {notifications.length > 0 && (
        <div className={`border-b border-border/30 ${isMobile ? 'p-4' : 'p-3'}`}>
          <Button
            variant="outline"
            size={isMobile ? "default" : "sm"}
            onClick={handleClearAll}
            className="w-full flex items-center gap-2 text-destructive hover:bg-destructive/10 hover:border-destructive/30 border-destructive/20"
          >
            <Trash2 className={`${isMobile ? 'h-4 w-4' : 'h-3 w-3'}`} />
            Tüm Bildirimleri Temizle
          </Button>
        </div>
      )}

      {/* Notifications List */}
      <ScrollArea className={`${isMobile ? 'h-[calc(100vh-200px)]' : 'max-h-80'}`}>
        <div className={isMobile ? 'p-4' : 'p-2'}>
          {notifications.length === 0 ? (
            <div className="flex flex-col items-center justify-center text-center py-10">
              <div className="bg-muted/30 rounded-full mb-2 p-3">
                <Bell className="text-muted-foreground/50 h-8 w-8" />
              </div>
              <h4 className="font-medium text-foreground mb-1 text-base">Hiç bildiriminiz yok</h4>
              <p className="text-muted-foreground text-sm">Yeni bildirimler burada görünecek</p>
            </div>
          ) : (
            <div className={`space-y-${isMobile ? '3' : '2'}`}>
              {notifications.map((notification) => (
                <Card 
                  key={notification.id}
                  className={`cursor-pointer transition-all hover:shadow-sm border-l-4 ${getNotificationColor(notification.type)} ${
                    !notification.read ? 'bg-primary/5 border-primary/20' : 'bg-background/80'
                  } ${isMobile ? 'p-4' : 'p-3'}`}
                  onClick={() => handleNotificationClick(notification)}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-start gap-2 flex-1 min-w-0">
                      <div className={`flex-shrink-0 mt-0.5 bg-background/50 rounded-full ${isMobile ? 'p-2' : 'p-1'}`}>
                        {getNotificationIcon(notification.type)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <h4 className={`font-medium truncate text-foreground ${isMobile ? 'text-sm' : 'text-xs'}`}>
                            {notification.title}
                          </h4>
                          {!notification.read && (
                            <div className="w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0 animate-pulse" />
                          )}
                        </div>
                        <p className={`text-muted-foreground mb-2 line-clamp-2 ${isMobile ? 'text-sm' : 'text-xs'}`}>
                          {notification.message}
                        </p>
                        <div className={`flex items-center gap-1 text-muted-foreground ${isMobile ? 'text-sm' : 'text-xs'}`}>
                          <Calendar className={`${isMobile ? 'h-4 w-4' : 'h-3 w-3'}`} />
                          <span>
                            {formatDistanceToNow(notification.timestamp, { 
                              addSuffix: true,
                              locale: tr 
                            })}
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={(e) => handleDeleteNotification(e, notification.id)}
                      className={`text-muted-foreground hover:text-destructive hover:bg-destructive/10 flex-shrink-0 rounded-full ${
                        isMobile ? 'h-8 w-8' : 'h-6 w-6'
                      }`}
                    >
                      <Trash2 className={`${isMobile ? 'h-4 w-4' : 'h-3 w-3'}`} />
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  );
};
