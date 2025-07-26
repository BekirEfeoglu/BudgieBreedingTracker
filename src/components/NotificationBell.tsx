import React, { useEffect, useState } from 'react';
import { Bell } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { useNotifications } from '@/hooks/useNotifications';

const NotificationBell = React.memo(() => {
  const { unreadCount } = useNotifications();
  const [prevCount, setPrevCount] = useState(unreadCount);
  const [showAnimation, setShowAnimation] = useState(false);

  useEffect(() => {
    // Yeni bildirim geldiğinde animasyonu göster
    if (unreadCount > prevCount) {
      setShowAnimation(true);
      const timer = setTimeout(() => setShowAnimation(false), 3000);
      return () => clearTimeout(timer);
    }
    setPrevCount(unreadCount);
  }, [unreadCount, prevCount]);

  return (
    <div className="relative flex items-center justify-center" aria-label={`${unreadCount} okunmamış bildirim`}>
      <Bell className="h-[22px] w-[22px] text-foreground stroke-[1.5px]" />
      {unreadCount > 0 && (
        <Badge 
          variant="destructive" 
          className={`absolute -top-0.5 -right-0.5 h-[18px] min-w-[18px] flex items-center justify-center text-[10px] font-medium p-px shadow-sm ${showAnimation ? 'animate-pulse' : ''}`}
          aria-hidden="true"
        >
          {unreadCount > 99 ? '99+' : unreadCount}
        </Badge>
      )}
    </div>
  );
});

export default NotificationBell;
