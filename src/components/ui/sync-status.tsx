
import { useState, useEffect } from 'react';
import { Wifi, WifiOff, RefreshCw, AlertCircle, CheckCircle, Clock, Calendar } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useOfflineSync } from '@/hooks/useOfflineSync';
import { useDateTimeUpdater } from '@/hooks/useDateTimeUpdater';

export const SyncStatus = () => {
  const { isOnline, isSyncing, queueSize, forceSync, clearQueue } = useOfflineSync();
  const [lastSyncTime, setLastSyncTime] = useState<string | null>(null);
  const { formattedDate, formattedTime } = useDateTimeUpdater(1000);

  useEffect(() => {
    if (!isSyncing && isOnline && queueSize === 0) {
      setLastSyncTime(new Date().toLocaleTimeString('tr-TR'));
    }
  }, [isSyncing, isOnline, queueSize]);

  return (
    <div className="flex items-center gap-4 text-xs">
      {/* Date and Time */}
      <div className="flex items-center gap-2 text-muted-foreground">
        <Clock className="w-3 h-3" />
        <span>{formattedTime.substring(0, 5)}</span>
        <Calendar className="w-3 h-3" />
        <span>{formattedDate}</span>
      </div>

      {/* Connection Status */}
      <div className="flex items-center gap-1">
        {isOnline ? (
          <>
            <Wifi className="w-3 h-3 text-green-500" />
            <span className="text-green-600 font-medium">Çevrimiçi</span>
          </>
        ) : (
          <>
            <WifiOff className="w-3 h-3 text-red-500" />
            <span className="text-red-600 font-medium">Çevrimdışı</span>
          </>
        )}
      </div>

      {/* Queue Status - Enhanced Performance Indicator */}
      {queueSize > 0 && (
        <Badge 
          variant="outline" 
          className={`text-xs px-2 py-0.5 ${queueSize > 10 ? 'animate-pulse' : ''}`}
        >
          <AlertCircle className="w-3 h-3 mr-1 text-orange-500" />
          <span className="text-orange-600">
            {queueSize} bekliyor
            {queueSize > 10 && ' (yoğun)'}
          </span>
        </Badge>
      )}

      {/* Sync Status */}
      {isSyncing && (
        <div className="flex items-center gap-1">
          <RefreshCw className="w-3 h-3 animate-spin text-blue-500" />
          <span className="text-blue-600">Senkronize ediliyor...</span>
        </div>
      )}

      {/* Control Buttons */}
      {queueSize > 0 && isOnline && (
        <Button 
          size="sm" 
          variant="outline" 
          onClick={forceSync}
          disabled={isSyncing}
          className="text-xs px-2 py-1 h-6"
        >
          {isSyncing ? 'Senkronize ediliyor...' : 'Şimdi Senkronize Et'}
        </Button>
      )}

      {/* Clear Queue Button (for debugging) */}
      {queueSize > 0 && process.env.NODE_ENV === 'development' && (
        <Button 
          size="sm" 
          variant="destructive" 
          onClick={clearQueue}
          className="text-xs px-2 py-1 h-6"
        >
          Kuyruğu Temizle
        </Button>
      )}
    </div>
  );
};
