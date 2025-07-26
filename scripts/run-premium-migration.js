const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Environment variables
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://jxbfdgyusoehqybxdnii.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY environment variable is required');
  console.log('💡 Please set your service role key:');
  console.log('   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function runPremiumMigration() {
  try {
    console.log('🚀 Premium subscription system migration başlatılıyor...');
    
    // Migration dosyasını oku
    const migrationPath = path.join(__dirname, '../supabase/migrations/20250201000000-add-premium-subscription-system.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('📄 Migration dosyası okundu');
    
    // Migration'ı çalıştır
    const { data, error } = await supabase.rpc('exec_sql', { sql: migrationSQL });
    
    if (error) {
      console.error('❌ Migration hatası:', error);
      throw error;
    }
    
    console.log('✅ Premium subscription system migration başarıyla tamamlandı!');
    console.log('📊 Migration sonucu:', data);
    
    // Varsayılan planları kontrol et
    console.log('🔍 Varsayılan planlar kontrol ediliyor...');
    const { data: plans, error: plansError } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true);
    
    if (plansError) {
      console.error('❌ Plan kontrolü hatası:', plansError);
    } else {
      console.log('✅ Varsayılan planlar yüklendi:');
      plans.forEach(plan => {
        console.log(`   - ${plan.display_name}: ₺${plan.price_monthly}/ay, ₺${plan.price_yearly}/yıl`);
      });
    }
    
    console.log('🎉 Premium sistem kurulumu tamamlandı!');
    
  } catch (error) {
    console.error('💥 Migration sırasında hata oluştu:', error);
    process.exit(1);
  }
}

// Script'i çalıştır
runPremiumMigration(); 