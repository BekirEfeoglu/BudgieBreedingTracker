
import React, { useState, useCallback } from 'react';
import { useToast } from '@/hooks/use-toast';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { useOfflineQueue } from '@/hooks/useOfflineQueue';
import { useSyncOperations } from '@/hooks/useSyncOperations';

export const useOfflineSync = () => {
  const [isSyncing, setIsSyncing] = useState(false);
  const { toast } = useToast();
  
  const { isOnline } = useNetworkStatus();
  const { queueSize, getQueue, setQueue, addToQueue, clearQueue } = useOfflineQueue();
  const { processQueue } = useSyncOperations();

  const syncQueue = useCallback(async () => {
    if (isSyncing) {
      console.log('⏳ Sync already in progress, skipping...');
      return;
    }
    
    const queue = getQueue();
    setIsSyncing(true);
    
    try {
      const { failedItems } = await processQueue(queue);
      // Update queue with failed items only
      setQueue(failedItems);
    } catch (error) {
      console.error('💥 Sync queue processing failed:', error);
      toast({
        title: 'Senkronizasyon Hatası',
        description: 'Senkronizasyon sırasında beklenmedik bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsSyncing(false);
    }
  }, [isSyncing, getQueue, setQueue, processQueue, toast]);

  const forceSync = () => {
    if (isOnline) {
      syncQueue();
    } else {
      toast({
        title: 'Bağlantı Yok',
        description: 'İnternet bağlantısı olmadan senkronizasyon yapılamaz.',
        variant: 'destructive'
      });
    }
  };

  // Auto-sync when coming online
  React.useEffect(() => {
    if (isOnline && queueSize > 0) {
      console.log('🟢 Connection restored - starting sync...');
      setTimeout(syncQueue, 100); // Small delay to avoid race conditions
    }
  }, [isOnline, queueSize, syncQueue]);

  return {
    isOnline,
    isSyncing,
    queueSize,
    addToQueue,
    syncQueue,
    clearQueue,
    forceSync
  };
};
