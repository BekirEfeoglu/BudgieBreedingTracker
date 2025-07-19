// 🚨 ACİL AUTH FIX SCRIPTİ
// Bu script 401 hatalarını acil olarak çözer

console.log('🚨 ACİL AUTH FIX BAŞLATILIYOR...');

// 1. Tüm auth verilerini temizle
function clearAllAuthData() {
  console.log('🗑️ TÜM AUTH VERİLERİ TEMİZLENİYOR...');
  
  // LocalStorage'ı temizle
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key && (
      key.includes('supabase') || 
      key.includes('auth') || 
      key.includes('session') ||
      key.includes('token')
    )) {
      keysToRemove.push(key);
    }
  }
  
  keysToRemove.forEach(key => {
    localStorage.removeItem(key);
    console.log(`🗑️ ${key} silindi`);
  });
  
  // SessionStorage'ı temizle
  const sessionKeysToRemove = [];
  for (let i = 0; i < sessionStorage.length; i++) {
    const key = sessionStorage.key(i);
    if (key && (
      key.includes('supabase') || 
      key.includes('auth') || 
      key.includes('session') ||
      key.includes('token')
    )) {
      sessionKeysToRemove.push(key);
    }
  }
  
  sessionKeysToRemove.forEach(key => {
    sessionStorage.removeItem(key);
    console.log(`🗑️ SessionStorage: ${key} silindi`);
  });
  
  // IndexedDB'yi temizle (mümkünse)
  if ('indexedDB' in window) {
    try {
      indexedDB.deleteDatabase('supabase');
      console.log('🗑️ IndexedDB supabase veritabanı silindi');
    } catch (error) {
      console.log('⚠️ IndexedDB temizleme başarısız:', error.message);
    }
  }
  
  console.log('✅ Tüm auth verileri temizlendi');
}

// 2. Supabase client'ı yeniden başlat
async function resetSupabaseClient() {
  console.log('🔄 SUPABASE CLIENT YENİDEN BAŞLATILIYOR...');
  
  try {
    // Mevcut supabase client'ı varsa oturumu kapat
    if (window.supabase) {
      try {
        await window.supabase.auth.signOut();
        console.log('✅ Mevcut oturum kapatıldı');
      } catch (error) {
        console.log('⚠️ Oturum kapatma hatası (normal):', error.message);
      }
    }
    
    // Global supabase referansını temizle
    window.supabase = null;
    
    console.log('✅ Supabase client sıfırlandı');
    
  } catch (error) {
    console.log('❌ Supabase client sıfırlama hatası:', error.message);
  }
}

// 3. Browser cache'ini temizle
function clearBrowserCache() {
  console.log('🧹 BROWSER CACHE TEMİZLENİYOR...');
  
  // Cache API'yi temizle
  if ('caches' in window) {
    caches.keys().then(cacheNames => {
      cacheNames.forEach(cacheName => {
        caches.delete(cacheName);
        console.log(`🗑️ Cache silindi: ${cacheName}`);
      });
    });
  }
  
  // Service Worker'ları temizle
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(registrations => {
      registrations.forEach(registration => {
        registration.unregister();
        console.log('🗑️ Service Worker kaldırıldı');
      });
    });
  }
  
  console.log('✅ Browser cache temizlendi');
}

// 4. Network bağlantısını test et
async function testNetworkConnection() {
  console.log('🌐 AĞ BAĞLANTISI TEST EDİLİYOR...');
  
  try {
    // Supabase endpoint'ini test et
    const response = await fetch('https://jxbfdgyusoehqybxdnii.supabase.co/rest/v1/', {
      method: 'HEAD',
      mode: 'no-cors'
    });
    
    console.log('✅ Supabase endpoint erişilebilir');
    return true;
  } catch (error) {
    console.log('❌ Supabase endpoint erişilemiyor:', error.message);
    return false;
  }
}

// 5. Yeni auth session oluştur
async function createNewAuthSession() {
  console.log('🆕 YENİ AUTH SESSION OLUŞTURULUYOR...');
  
  try {
    // Supabase client'ı yeniden oluştur
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı, sayfa yenilenmeli');
      return false;
    }
    
    // Session durumunu kontrol et
    const { data: { session }, error } = await window.supabase.auth.getSession();
    
    if (error) {
      console.log('❌ Session kontrolü başarısız:', error.message);
      return false;
    }
    
    if (session) {
      console.log('✅ Yeni session mevcut');
      console.log(`   User ID: ${session.user.id}`);
      console.log(`   Email: ${session.user.email}`);
      return true;
    } else {
      console.log('ℹ️ Session yok - login gerekli');
      return false;
    }
    
  } catch (error) {
    console.log('❌ Yeni session oluşturma hatası:', error.message);
    return false;
  }
}

// 6. Test API çağrısı yap
async function testApiCall() {
  console.log('🧪 TEST API ÇAĞRISI YAPILIYOR...');
  
  try {
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı');
      return false;
    }
    
    const { data, error } = await window.supabase
      .from('profiles')
      .select('count')
      .limit(1);
    
    if (error) {
      console.log('❌ API test başarısız:', error.message);
      return false;
    }
    
    console.log('✅ API test başarılı');
    return true;
    
  } catch (error) {
    console.log('❌ API test hatası:', error.message);
    return false;
  }
}

// 7. Ana emergency fix fonksiyonu
async function emergencyAuthFix() {
  console.log('🚨 ACİL AUTH FIX BAŞLATILIYOR...');
  
  try {
    // Adım 1: Tüm auth verilerini temizle
    clearAllAuthData();
    
    // Adım 2: Browser cache'ini temizle
    clearBrowserCache();
    
    // Adım 3: Supabase client'ı yeniden başlat
    await resetSupabaseClient();
    
    // Adım 4: Network bağlantısını test et
    const networkOk = await testNetworkConnection();
    if (!networkOk) {
      console.log('⚠️ Ağ bağlantısı sorunlu, devam ediliyor...');
    }
    
    // Adım 5: Kısa bir bekleme
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Adım 6: Yeni session oluştur
    const sessionOk = await createNewAuthSession();
    
    // Adım 7: API test et
    if (sessionOk) {
      const apiOk = await testApiCall();
      if (apiOk) {
        console.log('✅ ACİL FIX BAŞARILI!');
        console.log('💡 Şimdi yapmanız gerekenler:');
        console.log('   1. Sayfayı yenileyin (F5)');
        console.log('   2. Eğer hala sorun varsa, login sayfasına gidin');
        console.log('   3. Yeniden giriş yapın');
        return true;
      }
    }
    
    console.log('⚠️ ACİL FIX TAMAMLANDI AMA SESSION YOK');
    console.log('💡 Şimdi yapmanız gerekenler:');
    console.log('   1. Login sayfasına gidin');
    console.log('   2. Yeniden giriş yapın');
    console.log('   3. Eğer sorun devam ederse, farklı tarayıcı deneyin');
    
    return false;
    
  } catch (error) {
    console.error('💥 ACİL FIX HATASI:', error);
    console.log('💡 Manuel çözüm:');
    console.log('   1. Tarayıcıyı tamamen kapatın');
    console.log('   2. Tarayıcıyı yeniden açın');
    console.log('   3. Login sayfasına gidin');
    console.log('   4. Yeniden giriş yapın');
    return false;
  }
}

// 8. Otomatik sayfa yenileme
function autoRefreshPage() {
  console.log('🔄 SAYFA OTOMATİK YENİLENİYOR...');
  console.log('⏰ 3 saniye sonra sayfa yenilenecek...');
  
  setTimeout(() => {
    console.log('🔄 Sayfa yenileniyor...');
    window.location.reload();
  }, 3000);
}

// 9. Login sayfasına yönlendirme
function redirectToLogin() {
  console.log('🔀 LOGIN SAYFASINA YÖNLENDİRİLİYOR...');
  window.location.href = '/login';
}

// 10. Global fonksiyonları tanımla
if (typeof window !== 'undefined') {
  window.emergencyAuthFix = emergencyAuthFix;
  window.clearAllAuthData = clearAllAuthData;
  window.resetSupabaseClient = resetSupabaseClient;
  window.clearBrowserCache = clearBrowserCache;
  window.testNetworkConnection = testNetworkConnection;
  window.createNewAuthSession = createNewAuthSession;
  window.testApiCall = testApiCall;
  window.autoRefreshPage = autoRefreshPage;
  window.redirectToLogin = redirectToLogin;
  
  console.log('\n📋 ACİL FIX FONKSİYONLARI:');
  console.log('1. emergencyAuthFix() - Tam acil fix');
  console.log('2. clearAllAuthData() - Auth verilerini temizle');
  console.log('3. resetSupabaseClient() - Supabase client sıfırla');
  console.log('4. clearBrowserCache() - Browser cache temizle');
  console.log('5. testNetworkConnection() - Ağ bağlantısını test et');
  console.log('6. createNewAuthSession() - Yeni session oluştur');
  console.log('7. testApiCall() - API test et');
  console.log('8. autoRefreshPage() - Sayfayı otomatik yenile');
  console.log('9. redirectToLogin() - Login sayfasına git');
  
  console.log('\n🚨 OTOMATİK ACİL FIX BAŞLATILIYOR...');
  emergencyAuthFix().then(success => {
    if (success) {
      console.log('✅ Acil fix başarılı, sayfa yenileniyor...');
      setTimeout(() => {
        window.location.reload();
      }, 2000);
    } else {
      console.log('⚠️ Acil fix tamamlandı ama login gerekli');
      console.log('💡 Login sayfasına yönlendiriliyor...');
      setTimeout(() => {
        window.location.href = '/login';
      }, 3000);
    }
  });
} else {
  console.log('Node.js ortamında çalıştırılıyor...');
  emergencyAuthFix();
} 