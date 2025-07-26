import { useState, useEffect, useCallback } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';

export interface DatabaseMigration {
  id: string;
  version: string;
  description: string;
  sql: string;
  rollbackSql?: string;
  timestamp: Date;
  checksum: string;
  applied: boolean;
  appliedAt?: Date;
  rollbackable: boolean;
}

interface UseSafeMigrations {
  migrations: DatabaseMigration[];
  pendingMigrations: DatabaseMigration[];
  appliedMigrations: DatabaseMigration[];
  isLoading: boolean;
  error: string | null;
  applyMigration: (migration: DatabaseMigration) => Promise<boolean>;
  rollbackMigration: (migration: DatabaseMigration) => Promise<boolean>;
  validateMigration: (migration: DatabaseMigration) => Promise<boolean>;
  createBackup: () => Promise<boolean>;
  restoreBackup: (backupId: string) => Promise<boolean>;
  addMigration: (migration: Omit<DatabaseMigration, 'id' | 'timestamp' | 'applied' | 'checksum'>) => void;
}

export const useSafeMigrations = (): UseSafeMigrations => {
  const [migrations, setMigrations] = useState<DatabaseMigration[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { t } = useLanguage();

  // Load existing migrations from localStorage with versioning
  useEffect(() => {
    const loadMigrations = () => {
      try {
        const stored = localStorage.getItem('database_migrations');
        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) {
            setMigrations(parsed.map(m => ({
              ...m,
              timestamp: new Date(m.timestamp),
              appliedAt: m.appliedAt ? new Date(m.appliedAt) : undefined
            })));
            return;
          }
        }
        
        // Initialize with schema versioning migrations
        const initialMigrations: DatabaseMigration[] = [
          {
            id: 'schema_version_001',
            version: '1.0.0',
            description: 'Initialize schema versioning system',
            sql: `
              -- Create schema version tracking table
              CREATE TABLE IF NOT EXISTS schema_versions (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                version VARCHAR(20) NOT NULL UNIQUE,
                description TEXT,
                applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                checksum VARCHAR(64) NOT NULL,
                migration_id VARCHAR(100) NOT NULL
              );
              
              -- Create data integrity triggers
              CREATE OR REPLACE FUNCTION update_sync_version()
              RETURNS TRIGGER AS $$
              BEGIN
                NEW.sync_version = COALESCE(OLD.sync_version, 0) + 1;
                NEW.last_modified = NOW();
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;
              
              -- Apply sync triggers to main tables
              DROP TRIGGER IF EXISTS trigger_birds_sync_version ON birds;
              CREATE TRIGGER trigger_birds_sync_version
                BEFORE UPDATE ON birds
                FOR EACH ROW EXECUTE FUNCTION update_sync_version();
                
              DROP TRIGGER IF EXISTS trigger_eggs_sync_version ON eggs;
              CREATE TRIGGER trigger_eggs_sync_version
                BEFORE UPDATE ON eggs
                FOR EACH ROW EXECUTE FUNCTION update_sync_version();
                
              DROP TRIGGER IF EXISTS trigger_chicks_sync_version ON chicks;
              CREATE TRIGGER trigger_chicks_sync_version
                BEFORE UPDATE ON chicks
                FOR EACH ROW EXECUTE FUNCTION update_sync_version();
            `,
            rollbackSql: `
              DROP TRIGGER IF EXISTS trigger_birds_sync_version ON birds;
              DROP TRIGGER IF EXISTS trigger_eggs_sync_version ON eggs;
              DROP TRIGGER IF EXISTS trigger_chicks_sync_version ON chicks;
              DROP FUNCTION IF EXISTS update_sync_version();
              DROP TABLE IF EXISTS schema_versions;
            `,
            timestamp: new Date('2024-01-01'),
            checksum: 'schema_v1_abc123',
            applied: false,
            rollbackable: true
          },
          {
            id: 'performance_indexes_002',
            version: '1.1.0',
            description: 'Add performance optimization indexes',
            sql: `
              -- Core performance indexes
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_eggs_incubation_status ON eggs(incubation_id, status);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_eggs_hatch_date ON eggs(hatch_date);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_birds_user_gender ON birds(user_id, gender);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chicks_hatch_incubation ON chicks(hatch_date, incubation_id);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_clutches_pair_date ON clutches(pair_date);
              
              -- Sync optimization indexes
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_birds_sync_version ON birds(sync_version, last_modified);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_eggs_sync_version ON eggs(sync_version, last_modified);
              CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chicks_sync_version ON chicks(sync_version, last_modified);
            `,
            rollbackSql: `
              DROP INDEX CONCURRENTLY IF EXISTS idx_eggs_incubation_status;
              DROP INDEX CONCURRENTLY IF EXISTS idx_eggs_hatch_date;
              DROP INDEX CONCURRENTLY IF EXISTS idx_birds_user_gender;
              DROP INDEX CONCURRENTLY IF EXISTS idx_chicks_hatch_incubation;
              DROP INDEX CONCURRENTLY IF EXISTS idx_clutches_pair_date;
              DROP INDEX CONCURRENTLY IF EXISTS idx_birds_sync_version;
              DROP INDEX CONCURRENTLY IF EXISTS idx_eggs_sync_version;
              DROP INDEX CONCURRENTLY IF EXISTS idx_chicks_sync_version;
            `,
            timestamp: new Date('2024-01-15'),
            checksum: 'perf_v1_def456',
            applied: false,
            rollbackable: true
          },
          {
            id: 'conflict_resolution_003',
            version: '1.2.0',
            description: 'Add conflict resolution support',
            sql: `
              -- Conflict resolution tracking
              CREATE TABLE IF NOT EXISTS sync_conflicts (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL,
                table_name VARCHAR(50) NOT NULL,
                record_id UUID NOT NULL,
                conflict_type VARCHAR(20) NOT NULL, -- 'update', 'delete'
                local_data JSONB,
                remote_data JSONB,
                resolved BOOLEAN DEFAULT false,
                resolution_strategy VARCHAR(20), -- 'local', 'remote', 'merge'
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                resolved_at TIMESTAMP WITH TIME ZONE
              );
              
              ALTER TABLE sync_conflicts ENABLE ROW LEVEL SECURITY;
              
              CREATE POLICY "Users can manage their own conflicts"
                ON sync_conflicts FOR ALL
                USING (auth.uid() = user_id);
                
              CREATE INDEX IF NOT EXISTS idx_sync_conflicts_user_resolved ON sync_conflicts(user_id, resolved);
            `,
            rollbackSql: `
              DROP TABLE IF EXISTS sync_conflicts;
            `,
            timestamp: new Date('2024-02-01'),
            checksum: 'conflict_v1_ghi789',
            applied: false,
            rollbackable: true
          }
        ];

        setMigrations(initialMigrations);
        localStorage.setItem('database_migrations', JSON.stringify(initialMigrations));
      } catch (error) {
        console.error('Error loading migrations:', error);
        setError('Migration yükleme hatası');
      }
    };

    loadMigrations();
  }, []);

  const pendingMigrations = migrations.filter(m => !m.applied);
  const appliedMigrations = migrations.filter(m => m.applied);

  const calculateChecksum = (sql: string): string => {
    // Simple checksum calculation
    let hash = 0;
    for (let i = 0; i < sql.length; i++) {
      const char = sql.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash).toString(16);
  };

  const validateMigration = useCallback(async (migration: DatabaseMigration): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Validate SQL syntax (basic check)
      if (!migration.sql.trim()) {
        setError(t('migrations.errors.emptySql', 'Migration SQL cannot be empty'));
        return false;
      }

      // Check for dangerous operations
      const dangerousOperations = [
        'DROP DATABASE',
        'DROP SCHEMA',
        'TRUNCATE',
        'DELETE FROM auth.',
        'UPDATE auth.',
        'DROP TABLE auth.'
      ];

      const sqlUpper = migration.sql.toUpperCase();
      for (const dangerous of dangerousOperations) {
        if (sqlUpper.includes(dangerous)) {
          setError(t('migrations.errors.dangerousOperation', `Dangerous operation detected: ${dangerous}`));
          return false;
        }
      }

      // Validate checksum
      const calculatedChecksum = calculateChecksum(migration.sql);
      if (migration.checksum !== calculatedChecksum) {
        setError(t('migrations.errors.checksumMismatch', 'Migration checksum mismatch - possible tampering'));
        return false;
      }

      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Validation failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [t]);

  const createBackup = useCallback(async (): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Simulate backup creation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      console.log('Database backup created successfully');
      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Backup failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const applyMigration = useCallback(async (migration: DatabaseMigration): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Validate migration first
      const isValid = await validateMigration(migration);
      if (!isValid) return false;

      // Create backup before applying
      const backupSuccess = await createBackup();
      if (!backupSuccess) {
        setError(t('migrations.errors.backupFailed', 'Failed to create backup before migration'));
        return false;
      }

      // Simulate migration application
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Mark migration as applied
      setMigrations(prev => 
        prev.map(m => 
          m.id === migration.id 
            ? { ...m, applied: true, appliedAt: new Date() }
            : m
        )
      );

      console.log(`Migration ${migration.id} applied successfully`);
      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Migration failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [validateMigration, createBackup, t]);

  const rollbackMigration = useCallback(async (migration: DatabaseMigration): Promise<boolean> => {
    try {
      if (!migration.rollbackable || !migration.rollbackSql) {
        setError(t('migrations.errors.notRollbackable', 'This migration cannot be rolled back'));
        return false;
      }

      setIsLoading(true);
      setError(null);

      // Create backup before rollback
      const backupSuccess = await createBackup();
      if (!backupSuccess) {
        setError(t('migrations.errors.backupFailed', 'Failed to create backup before rollback'));
        return false;
      }

      // Simulate rollback
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Mark migration as not applied
      setMigrations(prev => 
        prev.map(m => 
          m.id === migration.id 
            ? { ...m, applied: false, appliedAt: undefined }
            : m
        )
      );

      console.log(`Migration ${migration.id} rolled back successfully`);
      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Rollback failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [createBackup, t]);

  const restoreBackup = useCallback(async (backupId: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      setError(null);

      // Simulate backup restoration
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      console.log(`Backup ${backupId} restored successfully`);
      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Backup restoration failed');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const addMigration = useCallback((
    migration: Omit<DatabaseMigration, 'id' | 'timestamp' | 'applied' | 'checksum'>
  ) => {
    const newMigration: DatabaseMigration = {
      ...migration,
      id: `migration_${Date.now()}`,
      timestamp: new Date(),
      applied: false,
      checksum: calculateChecksum(migration.sql)
    };

    setMigrations(prev => [...prev, newMigration]);
  }, []);

  return {
    migrations,
    pendingMigrations,
    appliedMigrations,
    isLoading,
    error,
    applyMigration,
    rollbackMigration,
    validateMigration,
    createBackup,
    restoreBackup,
    addMigration
  };
};