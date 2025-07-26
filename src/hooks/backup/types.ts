export interface BackupSettings {
  autoBackupEnabled: boolean;
  backupFrequencyHours: number;
  retentionDays: number;
  tablesToBackup: string[];
}

export interface BackupStatus {
  isRunning: boolean;
  lastBackupTime: Date | null;
  nextBackupTime: Date | null;
  totalBackups: number;
}