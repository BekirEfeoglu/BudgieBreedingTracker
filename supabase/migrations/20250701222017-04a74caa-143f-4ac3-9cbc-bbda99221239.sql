-- Fix backup_jobs_backup_type_check constraint to allow 'manual' type
ALTER TABLE backup_jobs DROP CONSTRAINT IF EXISTS backup_jobs_backup_type_check;

-- Add updated constraint that includes 'manual' as a valid backup type
ALTER TABLE backup_jobs ADD CONSTRAINT backup_jobs_backup_type_check 
CHECK (backup_type IN ('full', 'incremental', 'manual', 'automatic', 'scheduled'));