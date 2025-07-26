const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Supabase client oluştur
const supabaseUrl = 'https://etkvuonkmmzihsjwbcrl.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNTY5NzI5MCwiZXhwIjoyMDUxMjc0ODkwfQ.qwEzdTMvIYq1KMoBLJgYmxy_4lTMRz6aQqrzDsqBZMk';

const supabase = createClient(supabaseUrl, supabaseKey);

async function applySubscriptionMigration() {
  try {
    console.log('🔄 Subscription migration başlatılıyor...');
    
    // Migration SQL dosyasını oku
    const migrationPath = path.join(__dirname, '../supabase/migrations/20250131170000_create_subscription_tables.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration SQL dosyası okundu');
    
    // SQL'i çalıştır
    const { error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
    
    if (error) {
      console.error('❌ Migration hatası:', error);
      
      // Eğer exec_sql fonksiyonu yoksa, manuel olarak tabloları oluştur
      console.log('🔄 Manuel tablo oluşturma deneniyor...');
      
      // Subscription plans tablosunu oluştur
      const { error: plansError } = await supabase.rpc('exec_sql', { 
        sql: `
          CREATE TABLE IF NOT EXISTS subscription_plans (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name VARCHAR(50) NOT NULL UNIQUE,
            display_name VARCHAR(100) NOT NULL,
            description TEXT,
            price_monthly DECIMAL(10,2) NOT NULL,
            price_yearly DECIMAL(10,2) NOT NULL,
            features JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
        `
      });
      
      if (plansError) {
        console.error('❌ Subscription plans tablosu oluşturulamadı:', plansError);
        return;
      }
      
      console.log('✅ Subscription plans tablosu oluşturuldu');
      
      // Varsayılan planları ekle
      const { error: insertError } = await supabase
        .from('subscription_plans')
        .upsert([
          {
            name: 'free',
            display_name: 'Ücretsiz',
            description: 'Temel özellikler',
            price_monthly: 0.00,
            price_yearly: 0.00,
            features: { birds: 3, incubations: 1, eggs: 6, chicks: 3, notifications: 5 }
          },
          {
            name: 'premium',
            display_name: 'Premium',
            description: 'Sınırsız özellikler ve gelişmiş analitikler',
            price_monthly: 29.99,
            price_yearly: 299.99,
            features: {
              unlimited_birds: true,
              unlimited_incubations: true,
              unlimited_eggs: true,
              unlimited_chicks: true,
              unlimited_notifications: true,
              cloud_sync: true,
              advanced_stats: true,
              genealogy: true,
              data_export: true,
              ad_free: true,
              custom_notifications: true,
              auto_backup: true
            }
          }
        ]);
      
      if (insertError) {
        console.error('❌ Varsayılan planlar eklenemedi:', insertError);
        return;
      }
      
      console.log('✅ Varsayılan planlar eklendi');
      
      // Profiles tablosuna subscription alanları ekle
      const { error: alterError } = await supabase.rpc('exec_sql', {
        sql: `
          ALTER TABLE profiles 
          ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'free',
          ADD COLUMN IF NOT EXISTS subscription_plan_id UUID,
          ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
          ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE;
        `
      });
      
      if (alterError) {
        console.error('❌ Profiles tablosu güncellenemedi:', alterError);
        return;
      }
      
      console.log('✅ Profiles tablosu güncellendi');
      
    } else {
      console.log('✅ Migration başarıyla uygulandı');
    }
    
    console.log('🎉 Subscription sistemi hazır!');
    
  } catch (error) {
    console.error('💥 Beklenmedik hata:', error);
  }
}

// Script'i çalıştır
applySubscriptionMigration(); 