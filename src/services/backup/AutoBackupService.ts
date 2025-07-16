import { securityService } from '@/services/security/SecurityService';

export interface BackupConfig {
  enabled: boolean;
  frequency: 'daily' | 'weekly' | 'monthly';
  time: string; // HH:MM format
  retentionDays: number;
  includePhotos: boolean;
  includeSettings: boolean;
  autoUpload: boolean;
  cloudProvider?: 'google' | 'dropbox' | 'onedrive';
}

export interface BackupData {
  id: string;
  timestamp: Date;
  size: number;
  type: 'manual' | 'auto';
  status: 'success' | 'failed' | 'in_progress';
  data: any;
  checksum: string;
  encrypted: boolean;
}

class AutoBackupService {
  private config: BackupConfig;
  private backups: BackupData[] = [];
  private isRunning = false;

  constructor() {
    this.config = {
      enabled: true,
      frequency: 'daily',
      time: '02:00',
      retentionDays: 30,
      includePhotos: true,
      includeSettings: true,
      autoUpload: false
    };

    this.loadConfig();
    this.loadBackups();
    this.scheduleBackup();
  }

  // Konfigürasyon yükleme
  private loadConfig(): void {
    try {
      const saved = localStorage.getItem('budgie_backup_config');
      if (saved) {
        this.config = { ...this.config, ...JSON.parse(saved) };
      }
    } catch (error) {
      console.error('Failed to load backup config:', error);
    }
  }

  // Konfigürasyon kaydetme
  private saveConfig(): void {
    try {
      localStorage.setItem('budgie_backup_config', JSON.stringify(this.config));
    } catch (error) {
      console.error('Failed to save backup config:', error);
    }
  }

  // Yedekleme listesi yükleme
  private loadBackups(): void {
    try {
      const saved = localStorage.getItem('budgie_backups');
      if (saved) {
        this.backups = JSON.parse(saved).map((backup: any) => ({
          ...backup,
          timestamp: new Date(backup.timestamp)
        }));
      }
    } catch (error) {
      console.error('Failed to load backups:', error);
      this.backups = [];
    }
  }

  // Yedekleme listesi kaydetme
  private saveBackups(): void {
    try {
      localStorage.setItem('budgie_backups', JSON.stringify(this.backups));
    } catch (error) {
      console.error('Failed to save backups:', error);
    }
  }

  // Yedekleme zamanlaması
  private scheduleBackup(): void {
    if (!this.config.enabled) return;

    const now = new Date();
    const timeParts = this.config.time.split(':').map(Number);
    const hours = timeParts[0] || 0;
    const minutes = timeParts[1] || 0;
    const nextBackup = new Date();
    nextBackup.setHours(hours, minutes, 0, 0);

    // Eğer bugünün zamanı geçtiyse, yarına planla
    if (nextBackup <= now) {
      nextBackup.setDate(nextBackup.getDate() + 1);
    }

    const timeUntilBackup = nextBackup.getTime() - now.getTime();

    setTimeout(() => {
      this.performAutoBackup();
      this.scheduleBackup(); // Sonraki yedekleme için tekrar planla
    }, timeUntilBackup);
  }

  // Otomatik yedekleme
  private async performAutoBackup(): Promise<void> {
    if (this.isRunning) return;

    this.isRunning = true;
    const backupId = this.generateBackupId();

    try {
      // Yedekleme başladı
      const backup: BackupData = {
        id: backupId,
        timestamp: new Date(),
        size: 0,
        type: 'auto',
        status: 'in_progress',
        data: null,
        checksum: '',
        encrypted: false
      };

      this.backups.push(backup);
      this.saveBackups();

      // Veri toplama
      const data = await this.collectBackupData();
      
      // Şifreleme
      const encryptedData = securityService.encryptData(data);
      
      // Checksum hesaplama
      const checksum = this.calculateChecksum(encryptedData);
      
      // Yedekleme tamamlandı
      backup.data = encryptedData;
      backup.checksum = checksum;
      backup.encrypted = true;
      backup.size = new Blob([encryptedData]).size;
      backup.status = 'success';

      this.saveBackups();

      // Eski yedeklemeleri temizle
      this.cleanupOldBackups();

      // Cloud upload (opsiyonel)
      if (this.config.autoUpload && this.config.cloudProvider) {
        await this.uploadToCloud(backup);
      }

      console.log('Auto backup completed successfully');
    } catch (error) {
      console.error('Auto backup failed:', error);
      
      // Hata durumunda backup'ı güncelle
      const failedBackup = this.backups.find(b => b.id === backupId);
      if (failedBackup) {
        failedBackup.status = 'failed';
        this.saveBackups();
      }
    } finally {
      this.isRunning = false;
    }
  }

  // Manuel yedekleme
  async performManualBackup(): Promise<BackupData> {
    if (this.isRunning) {
      throw new Error('Yedekleme zaten çalışıyor');
    }

    this.isRunning = true;
    const backupId = this.generateBackupId();

    try {
      const backup: BackupData = {
        id: backupId,
        timestamp: new Date(),
        size: 0,
        type: 'manual',
        status: 'in_progress',
        data: null,
        checksum: '',
        encrypted: false
      };

      this.backups.push(backup);
      this.saveBackups();

      const data = await this.collectBackupData();
      const encryptedData = securityService.encryptData(data);
      const checksum = this.calculateChecksum(encryptedData);

      backup.data = encryptedData;
      backup.checksum = checksum;
      backup.encrypted = true;
      backup.size = new Blob([encryptedData]).size;
      backup.status = 'success';

      this.saveBackups();
      this.cleanupOldBackups();

      return backup;
    } catch (error) {
      console.error('Manual backup failed:', error);
      
      const failedBackup = this.backups.find(b => b.id === backupId);
      if (failedBackup) {
        failedBackup.status = 'failed';
        this.saveBackups();
      }
      
      throw error;
    } finally {
      this.isRunning = false;
    }
  }

  // Veri toplama
  private async collectBackupData(): Promise<any> {
    const data: any = {
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      birds: [],
      breedings: [],
      eggs: [],
      chicks: [],
      settings: {},
      photos: []
    };

    // Kuş verileri
    try {
      const birdsData = localStorage.getItem('budgie_birds');
      if (birdsData) {
        data.birds = JSON.parse(birdsData);
      }
    } catch (error) {
      console.error('Failed to backup birds data:', error);
    }

    // Üreme verileri
    try {
      const breedingsData = localStorage.getItem('budgie_breedings');
      if (breedingsData) {
        data.breedings = JSON.parse(breedingsData);
      }
    } catch (error) {
      console.error('Failed to backup breedings data:', error);
    }

    // Yumurta verileri
    try {
      const eggsData = localStorage.getItem('budgie_eggs');
      if (eggsData) {
        data.eggs = JSON.parse(eggsData);
      }
    } catch (error) {
      console.error('Failed to backup eggs data:', error);
    }

    // Civciv verileri
    try {
      const chicksData = localStorage.getItem('budgie_chicks');
      if (chicksData) {
        data.chicks = JSON.parse(chicksData);
      }
    } catch (error) {
      console.error('Failed to backup chicks data:', error);
    }

    // Ayarlar
    if (this.config.includeSettings) {
      try {
        const settingsData = localStorage.getItem('budgie_settings');
        if (settingsData) {
          data.settings = JSON.parse(settingsData);
        }
      } catch (error) {
        console.error('Failed to backup settings data:', error);
      }
    }

    // Fotoğraflar
    if (this.config.includePhotos) {
      try {
        const photosData = localStorage.getItem('budgie_photos');
        if (photosData) {
          data.photos = JSON.parse(photosData);
        }
      } catch (error) {
        console.error('Failed to backup photos data:', error);
      }
    }

    return data;
  }

  // Yedekleme geri yükleme
  async restoreBackup(backupId: string): Promise<boolean> {
    try {
      const backup = this.backups.find(b => b.id === backupId);
      if (!backup || backup.status !== 'success') {
        throw new Error('Geçersiz yedekleme');
      }

      // Checksum doğrulama
      const calculatedChecksum = this.calculateChecksum(backup.data);
      if (calculatedChecksum !== backup.checksum) {
        throw new Error('Yedekleme bozulmuş');
      }

      // Veri şifre çözme
      const decryptedData = securityService.decryptData(backup.data);

      // Veri geri yükleme
      if (decryptedData.birds) {
        localStorage.setItem('budgie_birds', JSON.stringify(decryptedData.birds));
      }

      if (decryptedData.breedings) {
        localStorage.setItem('budgie_breedings', JSON.stringify(decryptedData.breedings));
      }

      if (decryptedData.eggs) {
        localStorage.setItem('budgie_eggs', JSON.stringify(decryptedData.eggs));
      }

      if (decryptedData.chicks) {
        localStorage.setItem('budgie_chicks', JSON.stringify(decryptedData.chicks));
      }

      if (decryptedData.settings) {
        localStorage.setItem('budgie_settings', JSON.stringify(decryptedData.settings));
      }

      if (decryptedData.photos) {
        localStorage.setItem('budgie_photos', JSON.stringify(decryptedData.photos));
      }

      return true;
    } catch (error) {
      console.error('Backup restore failed:', error);
      return false;
    }
  }

  // Yedekleme export
  exportBackup(backupId: string): void {
    const backup = this.backups.find(b => b.id === backupId);
    if (!backup) return;

    const exportData = {
      ...backup,
      timestamp: backup.timestamp.toISOString()
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { 
      type: 'application/json' 
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `budgie-backup-${backupId}-${backup.timestamp.toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  // Yedekleme silme
  deleteBackup(backupId: string): boolean {
    const index = this.backups.findIndex(b => b.id === backupId);
    if (index === -1) return false;

    this.backups.splice(index, 1);
    this.saveBackups();
    return true;
  }

  // Eski yedeklemeleri temizle
  private cleanupOldBackups(): void {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - this.config.retentionDays);

    this.backups = this.backups.filter(backup => 
      backup.timestamp > cutoffDate
    );

    this.saveBackups();
  }

  // Cloud upload (demo)
  private async uploadToCloud(backup: BackupData): Promise<void> {
    // Gerçek uygulamada cloud API'leri kullanılır
    console.log(`Uploading backup ${backup.id} to ${this.config.cloudProvider}`);
    
    // Simüle edilmiş upload
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  // Checksum hesaplama
  private calculateChecksum(data: string): string {
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 32-bit integer
    }
    return hash.toString(16);
  }

  // Backup ID oluşturma
  private generateBackupId(): string {
    return `backup_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Konfigürasyon güncelleme
  updateConfig(newConfig: Partial<BackupConfig>): void {
    this.config = { ...this.config, ...newConfig };
    this.saveConfig();
    this.scheduleBackup();
  }

  // Konfigürasyon alma
  getConfig(): BackupConfig {
    return { ...this.config };
  }

  // Yedekleme listesi alma
  getBackups(): BackupData[] {
    return [...this.backups].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }

  // Yedekleme durumu
  getBackupStatus(): { isRunning: boolean; lastBackup: Date | undefined; nextBackup: Date | undefined } {
    const lastBackup = this.backups
      .filter(b => b.status === 'success')
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())[0];

    let nextBackup: Date | undefined;
    if (this.config.enabled) {
      const timeParts = this.config.time.split(':').map(Number);
      const hours = timeParts[0] || 0;
      const minutes = timeParts[1] || 0;
      nextBackup = new Date();
      nextBackup.setHours(hours, minutes, 0, 0);
      
      if (nextBackup <= new Date()) {
        nextBackup.setDate(nextBackup.getDate() + 1);
      }
    }

    return {
      isRunning: this.isRunning,
      lastBackup: lastBackup?.timestamp || undefined,
      nextBackup
    };
  }
}

// Singleton instance
export const autoBackupService = new AutoBackupService();
export default autoBackupService; 