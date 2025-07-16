
import React, { useState, useCallback, useRef } from 'react';
import { useToast } from '@/hooks/use-toast';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { useOfflineQueue } from '@/hooks/useOfflineQueue';
import { useSyncOperations } from '@/hooks/useSyncOperations';
import { useConflictResolution } from '@/hooks/useConflictResolution';

interface SyncState {
  isSyncing: boolean;
  lastSyncTime: Date | null;
  syncErrors: string[];
  conflictCount: number;
}

export const useEnhancedOfflineSync = () => {
  const [syncState, setSyncState] = useState<SyncState>({
    isSyncing: false,
    lastSyncTime: null,
    syncErrors: [],
    conflictCount: 0
  });
  
  const { toast } = useToast();
  const { isOnline } = useNetworkStatus();
  const { queueSize, getQueue, setQueue, addToQueue, clearQueue } = useOfflineQueue();
  const { processQueue } = useSyncOperations();
  const { detectConflict, addConflict, conflicts } = useConflictResolution();
  
  // Prevent concurrent sync operations
  const syncLockRef = useRef(false);

  const syncQueue = useCallback(async () => {
    if (syncLockRef.current) {
      return;
    }
    
    const queue = getQueue();
    if (queue.length === 0) {
      return;
    }

    syncLockRef.current = true;
    setSyncState(prev => ({ 
      ...prev, 
      isSyncing: true, 
      syncErrors: [] 
    }));
    
    try {
      // Gelişmiş çatışma kontrolü ile queue'yu işle
      const conflictCheckedQueue = [];
      const detectedConflicts = [];
      
      for (const item of queue) {
        // Eğer bu bir update operasyonu ise çatışma kontrolü yap
        if (item.operation === 'update' && item.data.id) {
          try {
            // Remote veriyi kontrol et (gerçek API çağrısı yapılmalı)
            const remoteData = null; // Bu kısım API'den güncel veri alacak
            
            if (remoteData) {
              const conflict = detectConflict(item.data, remoteData, item.table || 'unknown');
              if (conflict) {
                detectedConflicts.push(conflict);
                addConflict(conflict);
                continue; // Çatışmalı öğeyi queue'dan çıkar
              }
            }
          } catch (conflictError) {
            console.warn('Conflict detection failed for item:', item.id, conflictError);
            // Çatışma tespiti başarısız olursa öğeyi queue'da bırak
          }
        }
        
        conflictCheckedQueue.push(item);
      }

      // Çatışma tespit edildi ise kullanıcıya bildir
      if (detectedConflicts.length > 0) {
        toast({
          title: 'Veri Çatışması Tespit Edildi',
          description: `${detectedConflicts.length} kayıtta çatışma bulundu. Senkronizasyon durdu.`,
          variant: 'destructive'
        });
        
        setSyncState(prev => ({
          ...prev,
          conflictCount: detectedConflicts.length,
          syncErrors: [`${detectedConflicts.length} veri çatışması tespit edildi`]
        }));
        
        return; // Çatışma varsa senkronizasyonu durdur
      }

      const { failedItems, successCount } = await processQueue(conflictCheckedQueue);
      
      // Queue'yu sadece başarısız öğelerle güncelle
      setQueue(failedItems);
      
      setSyncState(prev => ({
        ...prev,
        lastSyncTime: new Date(),
        conflictCount: conflicts.length,
        syncErrors: failedItems.map(item => item.error || 'Bilinmeyen hata').filter(Boolean)
      }));

      // Başarı bildirimi
      if (successCount > 0) {
        toast({
          title: 'Senkronizasyon Tamamlandı',
          description: `${successCount} kayıt başarıyla senkronize edildi.`,
        });
      }

      // Başarısız işlemler varsa kullanıcıya bildir
      if (failedItems.length > 0) {
        toast({
          title: 'Senkronizasyon Kısmi Başarılı',
          description: `${failedItems.length} kayıt senkronize edilemedi. Tekrar deneyecek.`,
          variant: 'destructive'
        });
      }

    } catch (error) {
      console.error('Enhanced sync queue processing failed:', error);
      const errorMessage = error instanceof Error ? error.message : 'Bilinmeyen senkronizasyon hatası';
      
      setSyncState(prev => ({
        ...prev,
        syncErrors: [...prev.syncErrors, errorMessage]
      }));
      
      toast({
        title: 'Senkronizasyon Hatası',
        description: 'Senkronizasyon sırasında beklenmedik bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.',
        variant: 'destructive'
      });
    } finally {
      syncLockRef.current = false;
      setSyncState(prev => ({ ...prev, isSyncing: false }));
    }
  }, [getQueue, setQueue, processQueue, toast, detectConflict, addConflict, conflicts]);

  const forceSync = useCallback(() => {
    if (isOnline) {
      syncQueue();
    } else {
      toast({
        title: 'Bağlantı Yok',
        description: 'İnternet bağlantısı olmadan senkronizasyon yapılamaz.',
        variant: 'destructive'
      });
    }
  }, [isOnline, syncQueue, toast]);

  // Enhanced offline operation with conflict detection
  const addToQueueWithConflictCheck = useCallback((
    table: string, 
    operation: 'insert' | 'update' | 'delete', 
    data: any
  ) => {
    const existingItem = getQueue().find(item => 
      item.table === table && 
      item.data.id === data.id && 
      item.operation === operation
    );

    if (existingItem) {
      // Update existing item with newer data
      const queue = getQueue().map(item => 
        item.id === existingItem.id 
          ? { ...item, data: { ...item.data, ...data }, timestamp: new Date().toISOString() }
          : item
      );
      setQueue(queue);
    } else {
      addToQueue(table, operation, data);
    }
  }, [getQueue, setQueue, addToQueue]);

  // Auto-sync when coming online with enhanced logic
  React.useEffect(() => {
    if (isOnline && queueSize > 0 && !syncLockRef.current) {
      const timer = setTimeout(syncQueue, 500);
      return () => clearTimeout(timer);
    }
  }, [isOnline, queueSize, syncQueue]);

  return {
    isOnline,
    syncState,
    queueSize,
    conflicts,
    addToQueue: addToQueueWithConflictCheck,
    syncQueue,
    clearQueue,
    forceSync
  };
};
