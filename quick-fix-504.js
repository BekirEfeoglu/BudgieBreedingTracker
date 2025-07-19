// 504 Hatası Hızlı Düzeltme Scripti
// Bu script, Supabase bağlantı sorunlarını çözmek için kullanılır

console.log('🔧 504 Hatası Düzeltme Scripti Başlatılıyor...');

// 1. LocalStorage temizleme
function clearLocalStorage() {
  console.log('🧹 LocalStorage temizleniyor...');
  const keysToRemove = [];
  
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key && (
      key.includes('supabase') || 
      key.includes('auth') || 
      key.includes('rate') ||
      key.includes('session')
    )) {
      keysToRemove.push(key);
    }
  }
  
  keysToRemove.forEach(key => {
    localStorage.removeItem(key);
    console.log(`🗑️ Silindi: ${key}`);
  });
  
  console.log(`✅ ${keysToRemove.length} öğe temizlendi`);
}

// 2. SessionStorage temizleme
function clearSessionStorage() {
  console.log('🧹 SessionStorage temizleniyor...');
  sessionStorage.clear();
  console.log('✅ SessionStorage temizlendi');
}

// 3. Cache temizleme
function clearCache() {
  console.log('🧹 Cache temizleniyor...');
  
  if ('caches' in window) {
    caches.keys().then(names => {
      names.forEach(name => {
        caches.delete(name);
        console.log(`🗑️ Cache silindi: ${name}`);
      });
    });
  }
  
  console.log('✅ Cache temizleme tamamlandı');
}

// 4. Bağlantı testi
async function testConnection() {
  console.log('🌐 Bağlantı test ediliyor...');
  
  try {
    const response = await fetch('https://jxbfdgyusoehqybxdnii.supabase.co/auth/v1/health', {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (response.ok) {
      console.log('✅ Supabase bağlantısı başarılı');
      return true;
    } else {
      console.log(`❌ Supabase bağlantısı başarısız: ${response.status}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Bağlantı hatası: ${error.message}`);
    return false;
  }
}

// 5. Ana düzeltme fonksiyonu
async function fix504Error() {
  console.log('🚀 504 Hatası düzeltme işlemi başlatılıyor...');
  
  // Adım 1: Storage temizleme
  clearLocalStorage();
  clearSessionStorage();
  clearCache();
  
  // Adım 2: Kısa bekleme
  console.log('⏳ 2 saniye bekleniyor...');
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Adım 3: Bağlantı testi
  const connectionOk = await testConnection();
  
  if (connectionOk) {
    console.log('🎉 Düzeltme tamamlandı! Şimdi hesap oluşturmayı deneyebilirsiniz.');
    console.log('💡 Öneriler:');
    console.log('   • Sayfayı yenileyin (Ctrl+F5)');
    console.log('   • Farklı bir tarayıcı deneyin');
    console.log('   • VPN kullanıyorsanız kapatın');
    console.log('   • İnternet bağlantınızı kontrol edin');
  } else {
    console.log('⚠️ Bağlantı sorunu devam ediyor. Lütfen:');
    console.log('   • İnternet bağlantınızı kontrol edin');
    console.log('   • Birkaç dakika bekleyin');
    console.log('   • Farklı bir ağ deneyin');
  }
}

// 6. Otomatik çalıştırma
if (typeof window !== 'undefined') {
  // Tarayıcı ortamında çalıştır
  window.fix504Error = fix504Error;
  window.clearLocalStorage = clearLocalStorage;
  window.clearSessionStorage = clearSessionStorage;
  window.clearCache = clearCache;
  window.testConnection = testConnection;
  
  console.log('📋 Kullanılabilir fonksiyonlar:');
  console.log('   • fix504Error() - Tüm düzeltmeleri çalıştırır');
  console.log('   • clearLocalStorage() - LocalStorage temizler');
  console.log('   • clearSessionStorage() - SessionStorage temizler');
  console.log('   • clearCache() - Cache temizler');
  console.log('   • testConnection() - Bağlantıyı test eder');
  
  console.log('🚀 Otomatik düzeltme başlatılıyor...');
  fix504Error();
} else {
  // Node.js ortamında çalıştır
  console.log('Node.js ortamında çalıştırılıyor...');
  fix504Error();
} 