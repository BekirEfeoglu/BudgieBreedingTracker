
import { useEffect, useRef, useCallback } from 'react';
import { useNetworkStatus } from './useNetworkStatus';
import { useOfflineQueue } from './useOfflineQueue';
import { useSyncOperations } from './useSyncOperations';
import { useToast } from './use-toast';

export const useOfflineSync = () => {
  const { isOnline } = useNetworkStatus();
  const { getQueue, clearQueue } = useOfflineQueue();
  const { processQueue } = useSyncOperations();
  const { toast } = useToast();
  
  // Performance optimizations
  const syncTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const lastSyncAttemptRef = useRef<number>(0);
  const isProcessingRef = useRef<boolean>(false);

  const syncQueue = useCallback(async () => {
    if (isProcessingRef.current) {
      console.log('⏳ Sync already in progress, skipping...');
      return;
    }

    const now = Date.now();
    if (now - lastSyncAttemptRef.current < 2000) {
      console.log('⏳ Sync attempt too soon, skipping...');
      return;
    }

    const queue = getQueue();
    if (queue.length === 0) {
      // Reduced logging for performance
      return;
    }

    console.log(`🔄 Starting sync for ${queue.length} items...`);
    isProcessingRef.current = true;
    lastSyncAttemptRef.current = now;

    try {
      const result = await processQueue(queue);
      
      if (result.success) {
        if (result.processedCount > 0) {
          toast({
            title: 'Senkronizasyon Başarılı',
            description: `${result.processedCount} işlem başarıyla senkronize edildi.`,
          });
        }
        
        if (result.failedCount > 0) {
          toast({
            title: 'Kısmi Başarı',
            description: `${result.processedCount} işlem başarılı, ${result.failedCount} işlem başarısız.`,
            variant: 'destructive',
          });
        }
      } else {
        toast({
          title: 'Senkronizasyon Hatası',
          description: 'Bazı işlemler senkronize edilemedi.',
          variant: 'destructive',
        });
      }
    } catch (error) {
      console.error('❌ Sync failed:', error);
      toast({
        title: 'Senkronizasyon Hatası',
        description: 'Senkronizasyon sırasında bir hata oluştu.',
        variant: 'destructive',
      });
    } finally {
      isProcessingRef.current = false;
    }
  }, [getQueue, processQueue, toast]);

  const forceSync = useCallback(async () => {
    console.log('🚀 Force sync requested');
    if (syncTimeoutRef.current) {
      clearTimeout(syncTimeoutRef.current);
    }
    await syncQueue();
  }, [syncQueue]);

  // Auto-sync when connection is restored
  useEffect(() => {
    if (isOnline) {
      // Prevent multiple sync attempts
      if (syncTimeoutRef.current) {
        clearTimeout(syncTimeoutRef.current);
      }
      syncTimeoutRef.current = setTimeout(syncQueue, 2000); // Increased delay
    }
  }, [isOnline, syncQueue]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (syncTimeoutRef.current) {
        clearTimeout(syncTimeoutRef.current);
      }
    };
  }, []);

  return {
    syncQueue,
    forceSync,
    isOnline,
  };
};
