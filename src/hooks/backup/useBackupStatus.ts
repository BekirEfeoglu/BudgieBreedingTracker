import { useState, useCallback, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { BackupStatus } from './types';
import { useBackupCleanup } from './useBackupCleanup';

export const useBackupStatus = () => {
  const { user } = useAuth();
  const { cleanupPendingJobs } = useBackupCleanup();
  
  const [status, setStatus] = useState<BackupStatus>({
    isRunning: false,
    lastBackupTime: null,
    nextBackupTime: null,
    totalBackups: 0
  });

  // Component mount olduğunda pending işleri temizle
  useEffect(() => {
    if (user) {
      cleanupPendingJobs();
    }
  }, [user, cleanupPendingJobs]);

  // Yedekleme durumunu yükle
  const loadBackupStatus = useCallback(async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('backup_jobs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1);

      if (data && data.length > 0) {
        const lastBackup = data[0];
        setStatus(prev => ({
          ...prev,
          lastBackupTime: lastBackup.completed_at ? new Date(lastBackup.completed_at) : null,
          isRunning: false // Pending işleri temizlediğimiz için false olarak ayarla
        }));
      }

      // Toplam yedekleme sayısını al
      const { count } = await supabase
        .from('backup_jobs')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .eq('status', 'completed');

      setStatus(prev => ({
        ...prev,
        totalBackups: count || 0
      }));
    } catch (error) {
      console.error('Error loading backup status:', error);
    }
  }, [user]);

  return {
    status,
    setStatus,
    loadBackupStatus
  };
};