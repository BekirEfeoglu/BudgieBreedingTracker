import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';

export interface BackupSettings {
  autoBackupEnabled: boolean;
  backupFrequency: 'daily' | 'weekly' | 'monthly';
  backupTime: string;
  maxBackups: number;
  includePhotos: boolean;
  includeSettings: boolean;
}

const defaultSettings: BackupSettings = {
  autoBackupEnabled: false,
  backupFrequency: 'weekly',
  backupTime: '02:00',
  maxBackups: 10,
  includePhotos: true,
  includeSettings: true,
};

export const useBackupSettings = () => {
  const [settings, setSettings] = useState<BackupSettings>(defaultSettings);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }

    const loadSettings = async () => {
      try {
        // Mock implementation - gerçek uygulamada veritabanından yüklenir
        const savedSettings = localStorage.getItem(`backup-settings-${user.id}`);
        if (savedSettings) {
          setSettings(JSON.parse(savedSettings));
        }
      } catch (error) {
        console.error('Backup ayarları yüklenirken hata:', error);
        toast({
          title: 'Hata',
          description: 'Yedekleme ayarları yüklenemedi',
          variant: 'destructive',
        });
      } finally {
        setLoading(false);
      }
    };

    loadSettings();
  }, [user, toast]);

  const updateSettings = async (newSettings: Partial<BackupSettings>) => {
    if (!user) return;

    try {
      const updatedSettings = { ...settings, ...newSettings };
      setSettings(updatedSettings);
      
      // Mock implementation - gerçek uygulamada veritabanına kaydedilir
      localStorage.setItem(`backup-settings-${user.id}`, JSON.stringify(updatedSettings));
      
      toast({
        title: 'Başarılı',
        description: 'Yedekleme ayarları kaydedildi',
      });
    } catch (error) {
      console.error('Backup ayarları güncellenirken hata:', error);
      toast({
        title: 'Hata',
        description: 'Yedekleme ayarları kaydedilemedi',
        variant: 'destructive',
      });
    }
  };

  return {
    settings,
    loading,
    updateSettings,
  };
}; 