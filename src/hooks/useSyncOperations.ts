
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import type { QueueItem } from '@/hooks/useOfflineQueue';

const MAX_RETRY_COUNT = 5;

export const useSyncOperations = () => {
  const { toast } = useToast();

  const syncSingleItem = async (item: QueueItem) => {
    console.log(`📡 Syncing ${item.operation} on ${item.table || 'bulk'}:`, item.data);
    
    if (item.operation === 'bulk_delete_user_data') {
      // Handle bulk user data deletion
      console.log('🗑️ Processing bulk delete for user:', item.data.user_id);
      
      const deletionOrder = ['calendar', 'chicks', 'eggs', 'clutches', 'birds'];
      let totalDeleted = 0;
      
      for (const table of deletionOrder) {
        const deleteResult = await supabase
          .from(table as any)
          .delete()
          .eq('user_id', item.data.user_id);
          
        if (deleteResult.error) {
          throw deleteResult.error;
        }
        
        totalDeleted += deleteResult.count || 0;
      }
      
      console.log(`✅ Bulk delete completed: ${totalDeleted} records deleted`);
      return { error: null };
      
    } else {
      // Handle regular operations
      switch (item.operation) {
        case 'insert':
          return await supabase.from(item.table as any).insert(item.data);
        case 'update':
          return await supabase.from(item.table as any).update(item.data).eq('id', item.data.id);
        case 'delete':
          console.log(`🗑️ Deleting record with ID: ${item.data.id} from ${item.table}`);
          return await supabase.from(item.table as any).delete().eq('id', item.data.id);
        default:
          throw new Error(`Unknown operation: ${item.operation}`);
      }
    }
  };

  const processQueue = async (queue: QueueItem[]) => {
    if (queue.length === 0) {
      console.log('📭 Sync queue is empty');
      return { successCount: 0, failedItems: [] };
    }

    console.log('🔄 Starting sync process...', { queueSize: queue.length });

    const failedItems: QueueItem[] = [];
    let successCount = 0;

    for (const item of queue) {
      try {
        const result = await syncSingleItem(item);

        if (result?.error) {
          console.error(`❌ Sync failed for ${item.id}:`, result.error);
          if (item.retryCount < MAX_RETRY_COUNT) {
            failedItems.push({ ...item, retryCount: item.retryCount + 1 });
            console.log(`🔄 Retrying item ${item.id} (attempt ${item.retryCount + 2}/${MAX_RETRY_COUNT + 1})`);
          } else {
            console.error(`🚫 Max retry count exceeded for ${item.id}, dropping item`);
          }
        } else {
          successCount++;
          console.log(`✅ Successfully synced ${item.operation} for ${item.id}`);
        }
      } catch (error) {
        console.error(`💥 Exception during sync of ${item.id}:`, error);
        if (item.retryCount < MAX_RETRY_COUNT) {
          failedItems.push({ ...item, retryCount: item.retryCount + 1 });
        } else {
          console.error(`🚫 Max retry exceeded for ${item.id} due to exception`);
        }
      }
    }

    // Show results
    if (successCount > 0) {
      console.log(`✅ Sync completed successfully: ${successCount} items`);
      toast({
        title: 'Senkronizasyon Tamamlandı',
        description: `${successCount} kayıt başarıyla senkronize edildi.`,
      });
    }

    if (failedItems.length > 0) {
      console.log(`⚠️ Sync partially failed: ${failedItems.length} items remain in queue`);
      toast({
        title: 'Senkronizasyon Hatası',
        description: `${failedItems.length} kayıt senkronize edilemedi. Tekrar denenecek.`,
        variant: 'destructive'
      });
    }

    console.log('🏁 Sync completed', { success: successCount, failed: failedItems.length });
    
    return { successCount, failedItems };
  };

  return {
    processQueue
  };
};
