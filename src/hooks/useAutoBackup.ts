import { useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useBackupSettings } from './backup/useBackupSettings';
import { useBackupStatus } from './backup/useBackupStatus';
import { useBackupOperations } from './backup/useBackupOperations';

export const useAutoBackup = () => {
  const { user } = useAuth();
  
  const {
    settings,
    loadBackupSettings,
    updateBackupSettings
  } = useBackupSettings();

  const {
    status,
    setStatus,
    loadBackupStatus
  } = useBackupStatus();

  const {
    startManualBackup
  } = useBackupOperations({
    status,
    setStatus,
    settings,
    loadBackupStatus
  });

  // Bir sonraki otomatik yedekleme zamanını hesapla
  useEffect(() => {
    if (settings.autoBackupEnabled && status.lastBackupTime) {
      const nextBackup = new Date(status.lastBackupTime);
      nextBackup.setHours(nextBackup.getHours() + settings.backupFrequencyHours);
      setStatus(prev => ({ ...prev, nextBackupTime: nextBackup }));
    } else {
      setStatus(prev => ({ ...prev, nextBackupTime: null }));
    }
  }, [settings.autoBackupEnabled, settings.backupFrequencyHours, status.lastBackupTime, setStatus]);

  // Component mount olduğunda ayarları ve durumu yükle
  useEffect(() => {
    loadBackupSettings();
    loadBackupStatus();
  }, [loadBackupSettings, loadBackupStatus]);

  // Otomatik yedekleme zamanlayıcısı
  useEffect(() => {
    if (!settings.autoBackupEnabled || !user) return;

    const checkBackupSchedule = () => {
      const now = new Date();
      if (status.nextBackupTime && now >= status.nextBackupTime && !status.isRunning) {
        console.log('🔄 Starting scheduled backup...');
        startManualBackup();
      }
    };

    // Her 5 dakikada bir kontrol et
    const interval = setInterval(checkBackupSchedule, 5 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, [settings.autoBackupEnabled, user, status.nextBackupTime, status.isRunning, startManualBackup]);

  return {
    settings,
    status,
    updateBackupSettings,
    startManualBackup,
    loadBackupStatus
  };
};