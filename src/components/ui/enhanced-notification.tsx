import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';
import { formatDistanceToNow } from 'date-fns';
import { tr } from 'date-fns/locale';
import { type EnhancedNotification } from '@/contexts/notifications';
import { AlertTriangle, CheckCircle, Info, Clock, X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface EnhancedNotificationProps {
  notification: EnhancedNotification;
  onMarkAsRead?: (id: string) => void;
  onRemove?: (id: string) => void;
  onActionClick?: (action: { label: string; primary?: boolean; action?: string }) => void;
  compact?: boolean;
}

const getNotificationIcon = (type: string, category?: string) => {
  if (category === 'breeding') return '🥚';
  if (category === 'health') return '🏥';
  if (category === 'reminder') return '⏰';
  
  switch (type) {
    case 'success': return <CheckCircle className="w-4 h-4 text-green-500" />;
    case 'error': return <AlertTriangle className="w-4 h-4 text-red-500" />;
    case 'warning': return <AlertTriangle className="w-4 h-4 text-amber-500" />;
    default: return <Info className="w-4 h-4 text-blue-500" />;
  }
};

const getPriorityColor = (priority?: string) => {
  switch (priority) {
    case 'urgent': return 'bg-red-50 border-red-200 dark:bg-red-950/20 dark:border-red-800';
    case 'high': return 'bg-amber-50 border-amber-200 dark:bg-amber-950/20 dark:border-amber-800';
    case 'low': return 'bg-slate-50 border-slate-200 dark:bg-slate-950/20 dark:border-slate-800';
    default: return 'bg-card border-border';
  }
};

export const EnhancedNotificationCard: React.FC<EnhancedNotificationProps> = ({
  notification,
  onMarkAsRead: _onMarkAsRead,
  onRemove,
  onActionClick,
  compact = false
}) => {
  const timeAgo = formatDistanceToNow(notification.timestamp, { 
    addSuffix: true, 
    locale: tr 
  });

  if (compact) {
    return (
      <div className={cn(
        "flex items-start gap-3 p-3 rounded-lg transition-colors hover:bg-muted/50",
        !notification.read && "bg-primary/5",
        getPriorityColor(notification.priority)
      )}>
        <div className="flex-shrink-0 mt-0.5">
          {notification.icon ? (
            <span className="text-lg">{notification.icon}</span>
          ) : (
            getNotificationIcon(notification.type, notification.category)
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div>
              <h4 className="text-sm font-medium truncate">{notification.title}</h4>
              <p className="text-xs text-muted-foreground line-clamp-2">{notification.message}</p>
            </div>
            <div className="flex items-center gap-1 flex-shrink-0">
              <span className="text-xs text-muted-foreground">{timeAgo}</span>
              {onRemove && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => onRemove(notification.id)}
                  className="h-6 w-6 p-0 hover:bg-destructive/10"
                >
                  <X className="w-3 h-3" />
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <Card className={cn(
      "transition-all duration-200 hover:shadow-md",
      !notification.read && "ring-2 ring-primary/20",
      getPriorityColor(notification.priority)
    )}>
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          {/* Icon or Image */}
          <div className="flex-shrink-0">
            {notification.imageUrl ? (
              <Avatar className="w-10 h-10">
                <AvatarImage src={notification.imageUrl} alt={notification.title} />
                <AvatarFallback>
                  {getNotificationIcon(notification.type, notification.category)}
                </AvatarFallback>
              </Avatar>
            ) : (
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                {notification.icon ? (
                  <span className="text-xl">{notification.icon}</span>
                ) : (
                  getNotificationIcon(notification.type, notification.category)
                )}
              </div>
            )}
          </div>

          {/* Content */}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <h3 className="font-semibold text-sm">{notification.title}</h3>
                  {notification.priority && notification.priority !== 'normal' && (
                    <Badge variant={
                      notification.priority === 'urgent' ? 'destructive' :
                      notification.priority === 'high' ? 'default' : 'secondary'
                    } className="text-xs px-1.5 py-0.5">
                      {notification.priority === 'urgent' ? 'Acil' :
                       notification.priority === 'high' ? 'Yüksek' : 'Düşük'}
                    </Badge>
                  )}
                  {notification.category && (
                    <Badge variant="outline" className="text-xs px-1.5 py-0.5">
                      {notification.category === 'breeding' ? 'Üretim' :
                       notification.category === 'health' ? 'Sağlık' :
                       notification.category === 'reminder' ? 'Hatırlatıcı' : 'Sistem'}
                    </Badge>
                  )}
                </div>
                <p className="text-sm text-muted-foreground mb-2">{notification.message}</p>
              </div>
              
              {/* Actions */}
              <div className="flex items-center gap-1">
                <div className="flex items-center gap-1 text-xs text-muted-foreground">
                  <Clock className="w-3 h-3" />
                  <span>{timeAgo}</span>
                </div>
                {onRemove && (
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onRemove(notification.id)}
                    className="h-6 w-6 p-0 hover:bg-destructive/10"
                  >
                    <X className="w-3 h-3" />
                  </Button>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            {notification.actions && notification.actions.length > 0 && (
              <div className="flex gap-2 mt-3">
                {notification.actions.map((action, index) => (
                  <Button
                    key={index}
                    variant={action.primary ? "default" : "outline"}
                    size="sm"
                    onClick={() => onActionClick?.(action)}
                    className="text-xs h-7"
                  >
                    {action.label}
                  </Button>
                ))}
              </div>
            )}

            {/* Expiration warning */}
            {notification.expiresAt && (
              <div className="flex items-center gap-1 mt-2 text-xs text-amber-600">
                <Clock className="w-3 h-3" />
                <span>
                  Süre: {formatDistanceToNow(notification.expiresAt, { locale: tr })}
                </span>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};