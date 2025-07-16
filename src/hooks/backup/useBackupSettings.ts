import { useState, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { BackupSettings } from './types';

export const useBackupSettings = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  
  const [settings, setSettings] = useState<BackupSettings>({
    autoBackupEnabled: true,
    backupFrequencyHours: 24,
    retentionDays: 30,
    tablesToBackup: ['birds', 'clutches', 'eggs', 'chicks', 'calendar']
  });

  // Yedekleme ayarlarını yükle
  const loadBackupSettings = useCallback(async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('backup_settings')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') {
        console.error('Error loading backup settings:', error);
        return;
      }

      if (data) {
        setSettings({
          autoBackupEnabled: data.auto_backup_enabled ?? true,
          backupFrequencyHours: data.backup_frequency_hours ?? 24,
          retentionDays: data.retention_days ?? 30,
          tablesToBackup: data.tables_to_backup ?? ['birds', 'clutches', 'eggs', 'chicks', 'calendar']
        });
      } else {
        // Eğer ayarlar yoksa varsayılan ayarları oluştur (sadece bir kez)
        console.log('No backup settings found, creating default settings');
        
        // Önce tekrar kontrol et (race condition'ı önlemek için)
        const { data: existingData } = await supabase
          .from('backup_settings')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();
          
        if (!existingData) {
          await createDefaultBackupSettings();
        }
      }
    } catch (error) {
      console.error('Error loading backup settings:', error);
    }
  }, [user]);

  // Varsayılan yedekleme ayarlarını oluştur
  const createDefaultBackupSettings = useCallback(async () => {
    if (!user) return;

    try {
      const { error } = await supabase
        .from('backup_settings')
        .upsert({
          user_id: user.id,
          auto_backup_enabled: true,
          backup_frequency_hours: 24,
          retention_days: 30,
          tables_to_backup: ['birds', 'clutches', 'eggs', 'chicks', 'calendar'],
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'user_id'
        });

      if (error) {
        console.error('Error creating default backup settings:', error);
      } else {
        console.log('Default backup settings created successfully');
      }
    } catch (error) {
      console.error('Error creating default backup settings:', error);
    }
  }, [user]);

  // Yedekleme ayarlarını kaydet
  const updateBackupSettings = useCallback(async (newSettings: Partial<BackupSettings>) => {
    if (!user) return;

    try {
      const updatedSettings = { ...settings, ...newSettings };
      
      const { error } = await supabase
        .from('backup_settings')
        .upsert({
          user_id: user.id,
          auto_backup_enabled: updatedSettings.autoBackupEnabled,
          backup_frequency_hours: updatedSettings.backupFrequencyHours,
          retention_days: updatedSettings.retentionDays,
          tables_to_backup: updatedSettings.tablesToBackup,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      setSettings(updatedSettings);
      
      toast({
        title: 'Yedekleme Ayarları Güncellendi',
        description: 'Otomatik yedekleme ayarlarınız başarıyla kaydedildi.',
      });
    } catch (error) {
      console.error('Error updating backup settings:', error);
      toast({
        title: 'Hata',
        description: 'Yedekleme ayarları güncellenirken bir hata oluştu.',
        variant: 'destructive'
      });
    }
  }, [user, settings, toast]);

  return {
    settings,
    loadBackupSettings,
    createDefaultBackupSettings,
    updateBackupSettings
  };
};