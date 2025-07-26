import { useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { useBackupStatus } from './useBackupStatus';

export const useBackupOperations = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const { startBackup, finishBackup } = useBackupStatus();

  const createBackup = useCallback(async (): Promise<{ success: boolean; error?: string }> => {
    if (!user) {
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      startBackup();
      
      // Mock backup process
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const backupSize = `${(Math.random() * 5 + 1).toFixed(1)} MB`;
      finishBackup(backupSize);
      
      toast({
        title: 'Yedekleme Başarılı',
        description: `Yedekleme tamamlandı (${backupSize})`,
      });
      
      return { success: true };
    } catch (error) {
      console.error('Backup oluşturma hatası:', error);
      toast({
        title: 'Yedekleme Hatası',
        description: 'Yedekleme sırasında bir hata oluştu',
        variant: 'destructive',
      });
      return { success: false, error: 'Yedekleme başarısız' };
    }
  }, [user, toast, startBackup, finishBackup]);

  const restoreBackup = useCallback(async (backupId: string): Promise<{ success: boolean; error?: string }> => {
    if (!user) {
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      // Mock restore process
      await new Promise(resolve => setTimeout(resolve, 4000));
      
      toast({
        title: 'Geri Yükleme Başarılı',
        description: 'Verileriniz başarıyla geri yüklendi',
      });
      
      return { success: true };
    } catch (error) {
      console.error('Backup geri yükleme hatası:', error);
      toast({
        title: 'Geri Yükleme Hatası',
        description: 'Geri yükleme sırasında bir hata oluştu',
        variant: 'destructive',
      });
      return { success: false, error: 'Geri yükleme başarısız' };
    }
  }, [user, toast]);

  const deleteBackup = useCallback(async (backupId: string): Promise<{ success: boolean; error?: string }> => {
    if (!user) {
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      // Mock delete process
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      toast({
        title: 'Yedek Silindi',
        description: 'Seçilen yedek başarıyla silindi',
      });
      
      return { success: true };
    } catch (error) {
      console.error('Backup silme hatası:', error);
      toast({
        title: 'Silme Hatası',
        description: 'Yedek silinirken bir hata oluştu',
        variant: 'destructive',
      });
      return { success: false, error: 'Silme başarısız' };
    }
  }, [user, toast]);

  const getBackupList = useCallback(async (): Promise<{ success: boolean; data?: any[]; error?: string }> => {
    if (!user) {
      return { success: false, error: 'Kullanıcı girişi gerekli' };
    }

    try {
      // Mock backup list
      const mockBackups = [
        {
          id: '1',
          name: 'Yedek 1 - 21 Temmuz 2025',
          date: '2025-07-21T10:00:00Z',
          size: '2.3 MB',
          type: 'auto',
        },
        {
          id: '2',
          name: 'Yedek 2 - 20 Temmuz 2025',
          date: '2025-07-20T10:00:00Z',
          size: '2.1 MB',
          type: 'manual',
        },
        {
          id: '3',
          name: 'Yedek 3 - 19 Temmuz 2025',
          date: '2025-07-19T10:00:00Z',
          size: '2.0 MB',
          type: 'auto',
        },
      ];
      
      return { success: true, data: mockBackups };
    } catch (error) {
      console.error('Backup listesi getirme hatası:', error);
      return { success: false, error: 'Yedek listesi alınamadı' };
    }
  }, [user]);

  return {
    createBackup,
    restoreBackup,
    deleteBackup,
    getBackupList,
  };
}; 