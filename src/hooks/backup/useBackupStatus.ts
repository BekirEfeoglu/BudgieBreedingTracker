import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';

export interface BackupStatus {
  lastBackup: string | null;
  nextBackup: string | null;
  isBackingUp: boolean;
  totalBackups: number;
  totalSize: string;
  lastBackupSize: string;
}

export const useBackupStatus = () => {
  const [status, setStatus] = useState<BackupStatus>({
    lastBackup: null,
    nextBackup: null,
    isBackingUp: false,
    totalBackups: 0,
    totalSize: '0 MB',
    lastBackupSize: '0 MB',
  });
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }

    const loadStatus = async () => {
      try {
        // Mock implementation - gerçek uygulamada veritabanından yüklenir
        const savedStatus = localStorage.getItem(`backup-status-${user.id}`);
        if (savedStatus) {
          setStatus(JSON.parse(savedStatus));
        } else {
          // Mock data
          setStatus({
            lastBackup: null,
            nextBackup: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            isBackingUp: false,
            totalBackups: 0,
            totalSize: '0 MB',
            lastBackupSize: '0 MB',
          });
        }
      } catch (error) {
        console.error('Backup durumu yüklenirken hata:', error);
      } finally {
        setLoading(false);
      }
    };

    loadStatus();
  }, [user]);

  const updateStatus = (newStatus: Partial<BackupStatus>) => {
    if (!user) return;

    const updatedStatus = { ...status, ...newStatus };
    setStatus(updatedStatus);
    
    // Mock implementation - gerçek uygulamada veritabanına kaydedilir
    localStorage.setItem(`backup-status-${user.id}`, JSON.stringify(updatedStatus));
  };

  const startBackup = () => {
    updateStatus({ isBackingUp: true });
  };

  const finishBackup = (backupSize: string) => {
    const now = new Date().toISOString();
    const nextBackup = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
    
    updateStatus({
      lastBackup: now,
      nextBackup,
      isBackingUp: false,
      totalBackups: status.totalBackups + 1,
      lastBackupSize: backupSize,
      totalSize: calculateTotalSize(status.totalSize, backupSize),
    });
  };

  const calculateTotalSize = (currentTotal: string, newSize: string): string => {
    const currentMB = parseFloat(currentTotal.replace(' MB', ''));
    const newMB = parseFloat(newSize.replace(' MB', ''));
    return `${(currentMB + newMB).toFixed(1)} MB`;
  };

  return {
    status,
    loading,
    updateStatus,
    startBackup,
    finishBackup,
  };
}; 