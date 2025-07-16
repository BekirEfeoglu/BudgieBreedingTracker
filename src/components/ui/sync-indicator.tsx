import React from 'react';
import { Wifi, WifiOff, RefreshCw, CheckCircle, AlertCircle, Clock } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

export type SyncStatus = 'synced' | 'syncing' | 'pending' | 'error' | 'offline';

interface SyncIndicatorProps {
  status: SyncStatus;
  isOnline: boolean;
  lastSync?: Date;
  pendingCount?: number;
  onRetry?: () => void;
  className?: string;
}

const statusConfig = {
  synced: {
    icon: CheckCircle,
    color: 'bg-green-500',
    text: 'Senkronize',
    variant: 'default' as const
  },
  syncing: {
    icon: RefreshCw,
    color: 'bg-blue-500',
    text: 'Senkronize ediliyor',
    variant: 'secondary' as const
  },
  pending: {
    icon: Clock,
    color: 'bg-yellow-500',
    text: 'Beklemede',
    variant: 'outline' as const
  },
  error: {
    icon: AlertCircle,
    color: 'bg-red-500',
    text: 'Hata',
    variant: 'destructive' as const
  },
  offline: {
    icon: WifiOff,
    color: 'bg-gray-500',
    text: 'Çevrimdışı',
    variant: 'secondary' as const
  }
};

export const SyncIndicator: React.FC<SyncIndicatorProps> = ({
  status,
  isOnline,
  lastSync,
  pendingCount = 0,
  onRetry,
  className = ''
}) => {
  const config = statusConfig[status];
  const IconComponent = config.icon;
  
  const formatLastSync = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'Az önce';
    if (minutes < 60) return `${minutes} dakika önce`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} saat önce`;
    return date.toLocaleDateString('tr-TR');
  };

  const getTooltipContent = () => {
    let content = config.text;
    
    if (lastSync && status === 'synced') {
      content += `\nSon senkronizasyon: ${formatLastSync(lastSync)}`;
    }
    
    if (pendingCount > 0) {
      content += `\n${pendingCount} öğe beklemede`;
    }
    
    if (!isOnline) {
      content += '\nİnternet bağlantısı yok';
    }
    
    return content;
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <div className={`flex items-center gap-2 ${className}`}>
            {/* Network Status */}
            <div className="flex items-center">
              {isOnline ? (
                <Wifi className="w-4 h-4 text-green-500" />
              ) : (
                <WifiOff className="w-4 h-4 text-red-500" />
              )}
            </div>

            {/* Sync Status Badge */}
            <Badge variant={config.variant} className="flex items-center gap-1">
              <IconComponent 
                className={`w-3 h-3 ${status === 'syncing' ? 'animate-spin' : ''}`} 
              />
              <span className="text-xs">{config.text}</span>
              {pendingCount > 0 && (
                <span className="text-xs bg-white/20 px-1 rounded">
                  {pendingCount}
                </span>
              )}
            </Badge>

            {/* Retry Button for Errors */}
            {status === 'error' && onRetry && (
              <Button
                size="sm"
                variant="ghost"
                onClick={onRetry}
                className="h-6 px-2"
              >
                <RefreshCw className="w-3 h-3" />
              </Button>
            )}
          </div>
        </TooltipTrigger>
        <TooltipContent>
          <div className="whitespace-pre-line text-xs">
            {getTooltipContent()}
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
};