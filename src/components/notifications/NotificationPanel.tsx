import React, { useState } from 'react';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { Bell, ArrowLeft, BellOff, Check, Trash2, Calendar } from 'lucide-react';
import { useNotifications } from '@/hooks/useNotifications';
import { useIsMobile } from '@/hooks/use-mobile';
import { ScrollArea } from '@/components/ui/scroll-area';
import { formatDistanceToNow } from 'date-fns';
import { tr } from 'date-fns/locale';

const NotificationPanel = () => {
  const [isOpen, setIsOpen] = useState(false);
  const { unreadCount, notifications } = useNotifications();
  const isMobile = useIsMobile();

  const handleNotificationClick = (notification: any) => {
    // Placeholder for notification click handling
    console.log('Notification clicked:', notification);
  };

  const handleClearAll = () => {
    // Placeholder for clear all notifications
    console.log('Clear all notifications clicked');
  };

  const handleMarkAsRead = (id: string) => {
    // Placeholder for mark as read
    console.log('Mark as read:', id);
  };

  const handleDeleteNotification = (id: string) => {
    // Placeholder for delete notification
    console.log('Delete notification:', id);
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'info':
        return <Bell className="h-4 w-4 text-primary" />;
      case 'success':
        return <Check className="h-4 w-4 text-green-500" />;
      case 'warning':
        return <Bell className="h-4 w-4 text-yellow-500" />;
      case 'error':
        return <Trash2 className="h-4 w-4 text-red-500" />;
      default:
        return <Bell className="h-4 w-4 text-primary" />;
    }
  };

  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetTrigger asChild>
        <Button 
          variant="ghost" 
          size="icon"
          className={`relative touch-target mobile-tap-target bg-background/90 backdrop-blur-md border border-border/50 shadow-lg hover:bg-primary/10 hover:border-primary/20 transition-all duration-200 rounded-full ${
            isOpen ? 'bg-primary/20 border-primary/30' : ''
          }`}
          aria-label="Bildirimler"
        >
          <Bell className="h-5 w-5 text-primary stroke-2" />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 h-4 w-4 bg-destructive text-destructive-foreground text-xs rounded-full flex items-center justify-center animate-pulse">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </Button>
      </SheetTrigger>
      
      <SheetContent 
        side="right"
        className={`
          ${isMobile 
            ? 'w-full h-[60vh] max-h-[60vh] rounded-t-2xl rounded-b-none' 
            : 'w-full sm:max-w-lg h-full'
          }
          bg-background/95 backdrop-blur-md 
          border-t border-border/50
          shadow-2xl
          ${isMobile ? 'bottom-0 top-auto' : ''}
          min-w-0
        `}
        style={isMobile ? { 
          position: 'fixed',
          bottom: 0,
          top: 'auto',
          height: '60vh',
          maxHeight: '60vh'
        } : {}}
      >
        {/* Mobile Pull Handle */}
        {isMobile && (
          <div className="flex justify-center pt-2 pb-1 min-w-0">
            <div className="w-12 h-1 bg-muted-foreground/30 rounded-full"></div>
          </div>
        )}
        
        {/* Header */}
        <SheetHeader className={`${isMobile ? 'px-4 pt-2 pb-4' : 'px-6 pt-6 pb-4'} border-b border-border/50 min-w-0`}>
          <div className="flex items-center justify-between min-w-0">
            <div className="flex items-center gap-3 min-w-0 flex-1">
              <div className="p-2 bg-primary/10 rounded-full flex-shrink-0">
                <Bell className="h-5 w-5 text-primary" />
              </div>
              <div className="min-w-0 flex-1">
                <SheetTitle className="text-lg font-semibold truncate max-w-full min-w-0">
                  Bildirimler
                </SheetTitle>
                <SheetDescription className="text-sm text-muted-foreground truncate max-w-full min-w-0">
                  {unreadCount > 0 && `${unreadCount} okunmamış bildirim`}
                </SheetDescription>
              </div>
            </div>
            
            {/* Close Button */}
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setIsOpen(false)}
              className="h-8 w-8 rounded-full hover:bg-muted/50 flex-shrink-0"
              aria-label="Kapat"
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </div>
        </SheetHeader>
        
        {/* Content */}
        <div className={`${isMobile ? 'px-4' : 'px-6'} py-4 min-w-0 flex-1 overflow-hidden`}>
          <ScrollArea className="h-full min-w-0">
            <div className="space-y-3 min-w-0">
              {notifications.length === 0 ? (
                <div className="text-center py-8 min-w-0">
                  <BellOff className="h-12 w-12 mx-auto mb-4 opacity-50" />
                  <p className="text-muted-foreground truncate max-w-full min-w-0">Bildirim bulunmuyor</p>
                </div>
              ) : (
                <>
                  {/* Clear All Button */}
                  <div className="flex justify-end min-w-0">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={handleClearAll}
                      className="text-xs h-8 px-2 flex-shrink-0"
                    >
                      Tümünü Temizle
                    </Button>
                  </div>
                  
                  {/* Notifications List */}
                  <div className="space-y-2 min-w-0">
                    {notifications.map((notification) => (
                      <div 
                        key={notification.id} 
                        className={`p-3 border rounded-lg hover:bg-muted/50 transition-colors min-w-0 ${
                          !notification.read ? 'bg-primary/5 border-primary/20' : ''
                        }`}
                        onClick={() => handleNotificationClick(notification)}
                      >
                        <div className="flex items-start justify-between gap-2 min-w-0">
                          <div className="flex items-start gap-2 flex-1 min-w-0">
                            <div className={`flex-shrink-0 mt-0.5 bg-background/50 rounded-full ${isMobile ? 'p-2' : 'p-1'}`}>
                              {getNotificationIcon(notification.type)}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-1 min-w-0">
                                <h4 className={`font-medium truncate text-foreground ${isMobile ? 'text-sm' : 'text-xs'} max-w-full min-w-0`}>
                                  {notification.title}
                                </h4>
                                {!notification.read && (
                                  <div className="w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0 animate-pulse" />
                                )}
                              </div>
                              <p className={`text-muted-foreground mb-2 line-clamp-2 ${isMobile ? 'text-sm' : 'text-xs'} max-w-full min-w-0`}>
                                {notification.message}
                              </p>
                              <div className={`flex items-center gap-1 text-muted-foreground ${isMobile ? 'text-sm' : 'text-xs'} min-w-0`}>
                                <Calendar className={`${isMobile ? 'h-4 w-4' : 'h-3 w-3'} flex-shrink-0`} />
                                <span className="truncate max-w-full min-w-0">
                                  {formatDistanceToNow(notification.timestamp, { 
                                    addSuffix: true,
                                    locale: tr 
                                  })}
                                </span>
                              </div>
                            </div>
                          </div>
                          
                          {/* Action Buttons */}
                          <div className="flex flex-col gap-1 flex-shrink-0">
                            {!notification.read && (
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleMarkAsRead(notification.id);
                                }}
                                className="h-6 w-6 p-0 text-xs"
                              >
                                <Check className="h-3 w-3" />
                              </Button>
                            )}
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleDeleteNotification(notification.id);
                              }}
                              className="h-6 w-6 p-0 text-xs text-destructive hover:text-destructive"
                            >
                              <Trash2 className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          </ScrollArea>
        </div>
      </SheetContent>
    </Sheet>
  );
};

export default NotificationPanel;