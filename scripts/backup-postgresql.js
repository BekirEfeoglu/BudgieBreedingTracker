#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const AWS = require('aws-sdk');
const { format } = require('date-fns');

// AWS S3 Konfigürasyonu
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'eu-west-1'
});

// Supabase Konfigürasyonu
const SUPABASE_HOST = 'db.jxbfdgyusoehqybxdnii.supabase.co';
const SUPABASE_DB = 'postgres';
const SUPABASE_USER = 'postgres';
const SUPABASE_PASSWORD = process.env.SUPABASE_DB_PASSWORD;

// S3 Bucket Konfigürasyonu
const BUCKET_NAME = process.env.S3_BUCKET_NAME || 'budgie-breeding-backups';

class PostgreSQLBackup {
  constructor() {
    this.backupDir = path.join(__dirname, '../backups');
    this.ensureBackupDir();
  }

  ensureBackupDir() {
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  async createBackup() {
    const timestamp = format(new Date(), 'yyyy-MM-dd_HH-mm-ss');
    const backupPath = path.join(this.backupDir, `backup_${timestamp}.sql`);
    
    console.log(`🔄 PostgreSQL yedekleme başlatılıyor: ${timestamp}`);

    try {
      // 1. PostgreSQL dump oluştur
      await this.createPostgreSQLDump(backupPath);
      console.log('✅ PostgreSQL dump oluşturuldu');

      // 2. S3'e yükle
      await this.uploadToS3(backupPath, timestamp);
      console.log('✅ S3\'e yüklendi');

      // 3. Yerel dosyayı temizle
      fs.unlinkSync(backupPath);
      console.log('✅ Yerel dosya temizlendi');

      // 4. Eski yedekleri temizle
      await this.cleanupOldBackups();

      console.log('🎉 Yedekleme tamamlandı!');
      return { success: true, timestamp, backupPath };

    } catch (error) {
      console.error('❌ Yedekleme hatası:', error);
      return { success: false, error: error.message };
    }
  }

  createPostgreSQLDump(backupPath) {
    return new Promise((resolve, reject) => {
      const command = `PGPASSWORD="${SUPABASE_PASSWORD}" pg_dump -h ${SUPABASE_HOST} -U ${SUPABASE_USER} -d ${SUPABASE_DB} -f "${backupPath}" --no-password --verbose`;

      console.log('📤 PostgreSQL dump komutu çalıştırılıyor...');
      
      exec(command, (error, stdout, stderr) => {
        if (error) {
          console.error('❌ pg_dump hatası:', error);
          reject(error);
          return;
        }
        
        if (stderr) {
          console.warn('⚠️ pg_dump uyarısı:', stderr);
        }
        
        console.log('✅ pg_dump başarılı');
        resolve();
      });
    });
  }

  async uploadToS3(backupPath, timestamp) {
    const fileContent = fs.readFileSync(backupPath);
    const fileName = `daily/${format(new Date(), 'yyyy-MM-dd')}/backup_${timestamp}.sql`;

    const params = {
      Bucket: BUCKET_NAME,
      Key: fileName,
      Body: fileContent,
      ContentType: 'application/sql',
      Metadata: {
        'backup-date': timestamp,
        'database': 'budgie-breeding',
        'version': '1.0'
      }
    };

    try {
      await s3.upload(params).promise();
      console.log(`📤 S3'e yüklendi: ${fileName}`);
    } catch (error) {
      console.error('❌ S3 yükleme hatası:', error);
      throw error;
    }
  }

  async cleanupOldBackups() {
    try {
      // 30 günden eski yedekleri listele
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const params = {
        Bucket: BUCKET_NAME,
        Prefix: 'daily/'
      };

      const objects = await s3.listObjectsV2(params).promise();
      const oldObjects = objects.Contents.filter(obj => {
        const objectDate = new Date(obj.LastModified);
        return objectDate < thirtyDaysAgo;
      });

      if (oldObjects.length > 0) {
        const deleteParams = {
          Bucket: BUCKET_NAME,
          Delete: {
            Objects: oldObjects.map(obj => ({ Key: obj.Key }))
          }
        };

        await s3.deleteObjects(deleteParams).promise();
        console.log(`🗑️ ${oldObjects.length} eski yedek silindi`);
      }
    } catch (error) {
      console.warn('⚠️ Eski yedek temizleme hatası:', error);
    }
  }

  async listBackups() {
    try {
      const params = {
        Bucket: BUCKET_NAME,
        Prefix: 'daily/'
      };

      const objects = await s3.listObjectsV2(params).promise();
      return objects.Contents.map(obj => ({
        key: obj.Key,
        size: obj.Size,
        lastModified: obj.LastModified
      }));
    } catch (error) {
      console.error('❌ Yedek listesi hatası:', error);
      return [];
    }
  }

  async restoreBackup(backupKey) {
    try {
      console.log(`🔄 Yedek geri yükleniyor: ${backupKey}`);

      // S3'den yedek dosyasını indir
      const params = {
        Bucket: BUCKET_NAME,
        Key: backupKey
      };

      const { Body } = await s3.getObject(params).promise();
      const backupPath = path.join(this.backupDir, 'restore_temp.sql');
      
      fs.writeFileSync(backupPath, Body);

      // PostgreSQL'e geri yükle
      await this.restorePostgreSQLDump(backupPath);

      // Geçici dosyayı temizle
      fs.unlinkSync(backupPath);

      console.log('✅ Yedek geri yüklendi!');
      return { success: true };

    } catch (error) {
      console.error('❌ Geri yükleme hatası:', error);
      return { success: false, error: error.message };
    }
  }

  restorePostgreSQLDump(backupPath) {
    return new Promise((resolve, reject) => {
      const command = `PGPASSWORD="${SUPABASE_PASSWORD}" psql -h ${SUPABASE_HOST} -U ${SUPABASE_USER} -d ${SUPABASE_DB} -f "${backupPath}" --no-password`;

      console.log('📥 PostgreSQL geri yükleme komutu çalıştırılıyor...');
      
      exec(command, (error, stdout, stderr) => {
        if (error) {
          console.error('❌ psql hatası:', error);
          reject(error);
          return;
        }
        
        if (stderr) {
          console.warn('⚠️ psql uyarısı:', stderr);
        }
        
        console.log('✅ psql geri yükleme başarılı');
        resolve();
      });
    });
  }
}

// CLI Komutları
async function main() {
  const backup = new PostgreSQLBackup();
  const command = process.argv[2];

  switch (command) {
    case 'backup':
      await backup.createBackup();
      break;
    
    case 'list':
      const backups = await backup.listBackups();
      console.log('📋 Mevcut yedekler:');
      backups.forEach(b => {
        console.log(`  - ${b.key} (${b.size} bytes, ${b.lastModified})`);
      });
      break;
    
    case 'restore':
      const backupKey = process.argv[3];
      if (!backupKey) {
        console.error('❌ Yedek anahtarı belirtilmedi');
        process.exit(1);
      }
      await backup.restoreBackup(backupKey);
      break;
    
    default:
      console.log(`
🦜 Budgie Breeding PostgreSQL Yedekleme Sistemi

Kullanım:
  node backup-postgresql.js backup    - Yedek oluştur
  node backup-postgresql.js list      - Yedekleri listele
  node backup-postgresql.js restore <key> - Yedek geri yükle

Gerekli Environment Variables:
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_REGION (opsiyonel, varsayılan: eu-west-1)
  S3_BUCKET_NAME (opsiyonel, varsayılan: budgie-breeding-backups)
  SUPABASE_DB_PASSWORD
      `);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = PostgreSQLBackup; 