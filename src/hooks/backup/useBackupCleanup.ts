import { useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';

export const useBackupCleanup = () => {
  const { user } = useAuth();

  // Pending durumda kalan işleri temizle
  const cleanupPendingJobs = useCallback(async () => {
    if (!user) return;

    try {
      console.log('🧹 Cleaning up pending backup jobs...');
      
      // Pending durumda kalan tüm işleri başarısız olarak işaretle
      const { error } = await supabase
        .from('backup_jobs')
        .update({ 
          status: 'failed', 
          error_message: 'Job was stuck in pending state and cleaned up',
          completed_at: new Date().toISOString()
        })
        .eq('user_id', user.id)
        .eq('status', 'pending');

      if (error) {
        console.error('❌ Error cleaning up pending jobs:', error);
      } else {
        console.log('✅ Pending jobs cleaned up successfully');
      }
    } catch (error) {
      console.error('❌ Error in cleanup:', error);
    }
  }, [user]);

  return {
    cleanupPendingJobs
  };
};