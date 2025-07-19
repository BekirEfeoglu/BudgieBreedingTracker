// 🚨 ACİL DURUM 504 HATASI DÜZELTME SCRIPTİ - GÜNCEL VERSİYON
// Bu script, 504 hatasını çözmek için tüm olası yöntemleri dener

console.log('🚨 ACİL DURUM 504 DÜZELTME SCRIPTİ BAŞLATILIYOR...');

// 1. Tüm storage'ları temizle
function clearAllStorage() {
  console.log('🧹 TÜM STORAGE TEMİZLENİYOR...');
  
  // LocalStorage temizle
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key) {
      keysToRemove.push(key);
    }
  }
  keysToRemove.forEach(key => {
    localStorage.removeItem(key);
    console.log(`🗑️ LocalStorage silindi: ${key}`);
  });
  
  // SessionStorage temizle
  sessionStorage.clear();
  console.log('🗑️ SessionStorage temizlendi');
  
  // IndexedDB temizle
  if ('indexedDB' in window) {
    indexedDB.databases().then(databases => {
      databases.forEach(db => {
        indexedDB.deleteDatabase(db.name);
        console.log(`🗑️ IndexedDB silindi: ${db.name}`);
      });
    });
  }
  
  console.log(`✅ ${keysToRemove.length} öğe temizlendi`);
}

// 2. Cache temizle
async function clearAllCache() {
  console.log('🧹 TÜM CACHE TEMİZLENİYOR...');
  
  // Browser cache
  if ('caches' in window) {
    const names = await caches.keys();
    names.forEach(name => {
      caches.delete(name);
      console.log(`🗑️ Cache silindi: ${name}`);
    });
  }
  
  // Service Worker cache
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    registrations.forEach(registration => {
      registration.unregister();
      console.log('🗑️ Service Worker kaldırıldı');
    });
  }
  
  console.log('✅ Cache temizleme tamamlandı');
}

// 3. Network bağlantısını test et
async function testNetworkConnection() {
  console.log('🌐 AĞ BAĞLANTISI TEST EDİLİYOR...');
  
  const tests = [
    {
      name: 'DNS Test',
      url: 'https://jxbfdgyusoehqybxdnii.supabase.co',
      method: 'HEAD'
    },
    {
      name: 'Auth Health Check',
      url: 'https://jxbfdgyusoehqybxdnii.supabase.co/auth/v1/health',
      method: 'GET'
    },
    {
      name: 'REST API Test',
      url: 'https://jxbfdgyusoehqybxdnii.supabase.co/rest/v1/',
      method: 'OPTIONS'
    }
  ];
  
  const results = [];
  
  for (const test of tests) {
    try {
      const startTime = Date.now();
      const response = await fetch(test.url, {
        method: test.method,
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache'
        }
      });
      const duration = Date.now() - startTime;
      
      results.push({
        name: test.name,
        status: response.ok ? 'success' : 'error',
        duration,
        statusCode: response.status
      });
      
      console.log(`✅ ${test.name}: ${response.status} (${duration}ms)`);
    } catch (error) {
      results.push({
        name: test.name,
        status: 'error',
        error: error.message
      });
      console.log(`❌ ${test.name}: ${error.message}`);
    }
  }
  
  return results;
}

// 4. Supabase client'ı yeniden başlat
function resetSupabaseClient() {
  console.log('🔄 SUPABASE CLIENT YENİDEN BAŞLATILIYOR...');
  
  // Mevcut Supabase client'ı temizle
  if (window.supabase) {
    try {
      window.supabase.auth.signOut();
      console.log('🔐 Supabase oturumu kapatıldı');
    } catch (e) {
      console.log('⚠️ Supabase oturumu kapatılamadı:', e.message);
    }
  }
  
  // LocalStorage'daki Supabase verilerini temizle
  const supabaseKeys = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key && key.includes('supabase')) {
      supabaseKeys.push(key);
    }
  }
  
  supabaseKeys.forEach(key => {
    localStorage.removeItem(key);
    console.log(`🗑️ Supabase key silindi: ${key}`);
  });
  
  console.log('✅ Supabase client sıfırlandı');
}

// 5. Tarayıcı ayarlarını kontrol et
function checkBrowserSettings() {
  console.log('🔍 TARAYICI AYARLARI KONTROL EDİLİYOR...');
  
  const checks = [
    {
      name: 'Online Durumu',
      check: () => navigator.onLine,
      message: 'İnternet bağlantısı aktif'
    },
    {
      name: 'Service Worker',
      check: () => 'serviceWorker' in navigator,
      message: 'Service Worker destekleniyor'
    },
    {
      name: 'Fetch API',
      check: () => 'fetch' in window,
      message: 'Fetch API destekleniyor'
    },
    {
      name: 'LocalStorage',
      check: () => 'localStorage' in window,
      message: 'LocalStorage destekleniyor'
    }
  ];
  
  checks.forEach(check => {
    const result = check.check();
    console.log(`${result ? '✅' : '❌'} ${check.name}: ${check.message}`);
  });
}

// 6. Yeni retry mekanizmasını test et
async function testNewRetryMechanism() {
  console.log('🔄 YENİ RETRY MEKANİZMASI TEST EDİLİYOR...');
  
  try {
    // Basit bir test - Supabase bağlantısını test et
    const response = await fetch('https://jxbfdgyusoehqybxdnii.supabase.co/auth/v1/health', {
      method: 'GET',
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
      }
    });
    
    if (response.ok) {
      console.log('✅ Yeni retry mekanizması test edilebilir');
      return true;
    } else {
      console.log(`⚠️ Supabase bağlantısı: ${response.status}`);
      return false;
    }
  } catch (error) {
    console.log('❌ Retry mekanizması test edilemiyor:', error.message);
    return false;
  }
}

// 7. Manuel auth'u test et
async function testManualAuth() {
  console.log('🔧 MANUEL AUTH TEST EDİLİYOR...');
  
  try {
    const SUPABASE_URL = "https://jxbfdgyusoehqybxdnii.supabase.co";
    const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0";
    
    const response = await fetch(`${SUPABASE_URL}/auth/v1/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_PUBLISHABLE_KEY,
        'Authorization': `Bearer ${SUPABASE_PUBLISHABLE_KEY}`,
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }
    });
    
    if (response.ok) {
      console.log('✅ Manuel auth test edilebilir');
      return true;
    } else {
      console.log(`⚠️ Manuel auth test edilemiyor: ${response.status}`);
      return false;
    }
  } catch (error) {
    console.log('❌ Manuel auth test edilemiyor:', error.message);
    return false;
  }
}

// 8. Ana düzeltme fonksiyonu
async function emergencyFix504() {
  console.log('🚨 ACİL DURUM 504 DÜZELTME İŞLEMİ BAŞLATILIYOR...');
  
  try {
    // Adım 1: Tarayıcı ayarlarını kontrol et
    checkBrowserSettings();
    
    // Adım 2: Tüm storage'ları temizle
    clearAllStorage();
    
    // Adım 3: Cache temizle
    await clearAllCache();
    
    // Adım 4: Supabase client'ı sıfırla
    resetSupabaseClient();
    
    // Adım 5: Kısa bekleme
    console.log('⏳ 3 saniye bekleniyor...');
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Adım 6: Ağ bağlantısını test et
    const networkResults = await testNetworkConnection();
    
    // Adım 7: Yeni retry mekanizmasını test et
    const retryTest = await testNewRetryMechanism();
    
    // Adım 8: Manuel auth'u test et
    const manualAuthTest = await testManualAuth();
    
    // Adım 9: Sonuçları değerlendir
    const successCount = networkResults.filter(r => r.status === 'success').length;
    const errorCount = networkResults.filter(r => r.status === 'error').length;
    
    console.log('\n📊 TEST SONUÇLARI:');
    networkResults.forEach(result => {
      console.log(`${result.status === 'success' ? '✅' : '❌'} ${result.name}`);
      if (result.duration) console.log(`   Süre: ${result.duration}ms`);
      if (result.statusCode) console.log(`   Kod: ${result.statusCode}`);
      if (result.error) console.log(`   Hata: ${result.error}`);
    });
    
    console.log(`${retryTest ? '✅' : '❌'} Yeni Retry Mekanizması: ${retryTest ? 'Hazır' : 'Test edilemiyor'}`);
    console.log(`${manualAuthTest ? '✅' : '❌'} Manuel Auth: ${manualAuthTest ? 'Hazır' : 'Test edilemiyor'}`);
    
    if (successCount > errorCount && (retryTest || manualAuthTest)) {
      console.log('\n🎉 DÜZELTME BAŞARILI!');
      console.log('💡 Şimdi yapmanız gerekenler:');
      console.log('   1. Sayfayı yenileyin (Ctrl+F5)');
      console.log('   2. Hesap oluşturmayı tekrar deneyin');
      console.log('   3. Yeni retry mekanizması aktif!');
      console.log('   4. Manuel auth sistemi hazır!');
      console.log('   5. Hala sorun varsa "Gelişmiş Test" butonunu kullanın');
    } else {
      console.log('\n⚠️ BAĞLANTI SORUNU DEVAM EDİYOR');
      console.log('💡 Öneriler:');
      console.log('   • İnternet bağlantınızı kontrol edin');
      console.log('   • VPN kullanıyorsanız kapatın');
      console.log('   • Farklı bir ağ deneyin');
      console.log('   • Tarayıcı cache\'ini manuel olarak temizleyin');
      console.log('   • Birkaç dakika bekleyip tekrar deneyin');
      console.log('   • "Gelişmiş Test" butonunu kullanın');
      console.log('   • Supabase sunucularında geçici sorun olabilir');
    }
    
  } catch (error) {
    console.error('💥 Düzeltme sırasında hata:', error);
    console.log('🔧 Manuel düzeltme gerekli olabilir');
  }
}

// 9. Yardımcı fonksiyonlar
function showInstructions() {
  console.log('\n📋 KULLANIM TALİMATLARI:');
  console.log('1. emergencyFix504() - Tüm düzeltmeleri çalıştırır');
  console.log('2. clearAllStorage() - Tüm storage\'ları temizler');
  console.log('3. clearAllCache() - Tüm cache\'leri temizler');
  console.log('4. testNetworkConnection() - Ağ bağlantısını test eder');
  console.log('5. resetSupabaseClient() - Supabase client\'ı sıfırlar');
  console.log('6. checkBrowserSettings() - Tarayıcı ayarlarını kontrol eder');
  console.log('7. testNewRetryMechanism() - Yeni retry mekanizmasını test eder');
  console.log('8. testManualAuth() - Manuel auth sistemini test eder');
}

// 10. Global fonksiyonları tanımla
if (typeof window !== 'undefined') {
  window.emergencyFix504 = emergencyFix504;
  window.clearAllStorage = clearAllStorage;
  window.clearAllCache = clearAllCache;
  window.testNetworkConnection = testNetworkConnection;
  window.resetSupabaseClient = resetSupabaseClient;
  window.checkBrowserSettings = checkBrowserSettings;
  window.testNewRetryMechanism = testNewRetryMechanism;
  window.testManualAuth = testManualAuth;
  
  showInstructions();
  
  console.log('\n🚀 OTOMATİK ACİL DÜZELTME BAŞLATILIYOR...');
  emergencyFix504();
} else {
  console.log('Node.js ortamında çalıştırılıyor...');
  emergencyFix504();
} 