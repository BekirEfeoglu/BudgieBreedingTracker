
import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

export const useDataDeletion = () => {
  const [isDeleting, setIsDeleting] = useState(false);
  const { user } = useAuth();
  const { isOnline } = useSupabaseOperations();
  const { toast } = useToast();

  const deleteAllUserData = async () => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı oturumu bulunamadı.',
        variant: 'destructive'
      });
      return { success: false };
    }

    setIsDeleting(true);
    console.log('🗑️ Starting complete data deletion for user:', user.id);

    try {
      if (isOnline) {
        // Online: Direct database deletion with proper order due to foreign keys
        console.log('🌐 Online deletion: Direct database operations');
        
        // Delete in reverse dependency order to avoid FK violations
        // Chicks first (depends on eggs and incubations)
        // Then eggs (depends on incubations) 
        // Then incubations
        // Finally birds, clutches, and calendar
        const deletionOrder = [
          'calendar',
          'chicks', 
          'eggs',
          'incubations',
          'clutches',
          'birds'
        ];

        let totalDeleted = 0;
        
        for (const table of deletionOrder) {
          console.log(`🗑️ Deleting from ${table} table...`);
          
          const { error, count } = await supabase
            .from(table as any)
            .delete()
            .eq('user_id', user.id);

          if (error) {
            console.error(`❌ Error deleting from ${table}:`, error);
            throw error;
          }

          const deletedCount = count || 0;
          totalDeleted += deletedCount;
          console.log(`✅ Deleted ${deletedCount} records from ${table}`);
        }

        // Clear any local storage/cache
        localStorage.removeItem('offline_sync_queue');
        
        console.log(`✅ Total deletion completed: ${totalDeleted} records`);
        
        toast({
          title: 'Başarılı',
          description: `Tüm verileriniz kalıcı olarak silindi. (${totalDeleted} kayıt)`,
        });

        return { success: true, deletedCount: totalDeleted };

      } else {
        // Offline: Add to queue and clear local data
        console.log('📱 Offline deletion: Adding to sync queue');
        
        const offlineQueue = JSON.parse(localStorage.getItem('offline_sync_queue') || '[]');
        
        // Add bulk delete operation to queue
        const bulkDeleteOperation = {
          id: `bulk_delete_${Date.now()}`,
          operation: 'bulk_delete_user_data',
          data: { user_id: user.id },
          timestamp: new Date().toISOString(),
          retryCount: 0
        };
        
        offlineQueue.push(bulkDeleteOperation);
        localStorage.setItem('offline_sync_queue', JSON.stringify(offlineQueue));
        
        // Clear local data immediately for UI responsiveness
        // This will be handled by individual components' state management
        
        toast({
          title: 'Çevrimdışı Mod',
          description: 'Silme işlemi kuyruğa eklendi. Bağlantı sağlandığında tüm veriler silinecek.',
        });

        return { success: true, queued: true };
      }

    } catch (error) {
      console.error('💥 Complete data deletion failed:', error);
      
      toast({
        title: 'Silme Hatası',
        description: 'Veriler silinirken bir hata oluştu. Lütfen tekrar deneyin.',
        variant: 'destructive'
      });

      return { success: false, error };
    } finally {
      setIsDeleting(false);
    }
  };

  const resetAllLocalData = () => {
    // Clear offline sync queue
    localStorage.removeItem('offline_sync_queue');
    
    // Clear any other local storage keys related to the app
    const keysToRemove = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && (key.startsWith('budgie_') || key.includes('breeding_tracker'))) {
        keysToRemove.push(key);
      }
    }
    
    keysToRemove.forEach(key => localStorage.removeItem(key));
    
    console.log('🧹 Local data cleared:', keysToRemove.length, 'items');
  };

  return {
    deleteAllUserData,
    resetAllLocalData,
    isDeleting
  };
};
