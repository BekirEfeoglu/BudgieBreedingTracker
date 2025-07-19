// 🔍 401 UNAUTHORIZED HATALARINI DEBUG ETME SCRIPTİ
// Bu script, auth token'larını ve session durumunu kontrol eder

console.log('🔍 401 UNAUTHORIZED HATALARINI DEBUG EDİLİYOR...');

// 1. Mevcut auth durumunu kontrol et
async function checkAuthStatus() {
  console.log('\n📋 MEVCUT AUTH DURUMU:');
  
  try {
    // Supabase client'ın mevcut olup olmadığını kontrol et
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı!');
      return;
    }
    
    console.log('✅ Supabase client mevcut');
    
    // Mevcut session'ı al
    const { data: { session }, error } = await window.supabase.auth.getSession();
    
    if (error) {
      console.log('❌ Session alma hatası:', error.message);
      return;
    }
    
    if (session) {
      console.log('✅ Aktif session mevcut');
      console.log(`   User ID: ${session.user.id}`);
      console.log(`   Email: ${session.user.email}`);
      console.log(`   Access Token: ${session.access_token ? 'Mevcut' : 'Yok'}`);
      console.log(`   Refresh Token: ${session.refresh_token ? 'Mevcut' : 'Yok'}`);
      console.log(`   Expires At: ${new Date(session.expires_at * 1000).toLocaleString()}`);
      
      // Token'ın geçerli olup olmadığını kontrol et
      const now = Math.floor(Date.now() / 1000);
      const isExpired = session.expires_at < now;
      console.log(`   Token Geçerli: ${!isExpired ? '✅ Evet' : '❌ Hayır (Süresi dolmuş)'}`);
      
    } else {
      console.log('❌ Aktif session yok');
    }
    
  } catch (error) {
    console.log('❌ Auth durumu kontrolü başarısız:', error.message);
  }
}

// 2. LocalStorage'daki auth verilerini kontrol et
function checkLocalStorage() {
  console.log('\n📦 LOCALSTORAGE AUTH VERİLERİ:');
  
  const authKeys = [
    'supabase.auth.token',
    'supabase.auth.refreshToken',
    'supabase.auth.expiresAt',
    'supabase.auth.expiresIn',
    'supabase.auth.tokenType',
    'supabase.auth.user'
  ];
  
  authKeys.forEach(key => {
    const value = localStorage.getItem(key);
    if (value) {
      console.log(`✅ ${key}: ${value.substring(0, 100)}...`);
    } else {
      console.log(`❌ ${key}: Yok`);
    }
  });
}

// 3. Token'ı yenilemeyi dene
async function refreshToken() {
  console.log('\n🔄 TOKEN YENİLEME DENENİYOR...');
  
  try {
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı');
      return;
    }
    
    const { data, error } = await window.supabase.auth.refreshSession();
    
    if (error) {
      console.log('❌ Token yenileme hatası:', error.message);
      return;
    }
    
    if (data.session) {
      console.log('✅ Token başarıyla yenilendi');
      console.log(`   Yeni expires at: ${new Date(data.session.expires_at * 1000).toLocaleString()}`);
    } else {
      console.log('❌ Token yenilenemedi - session yok');
    }
    
  } catch (error) {
    console.log('❌ Token yenileme başarısız:', error.message);
  }
}

// 4. Test API çağrısı yap
async function testApiCall() {
  console.log('\n🧪 TEST API ÇAĞRISI YAPILIYOR...');
  
  try {
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı');
      return;
    }
    
    // Basit bir API çağrısı yap
    const { data, error } = await window.supabase
      .from('profiles')
      .select('count')
      .limit(1);
    
    if (error) {
      console.log('❌ API çağrısı başarısız:', error.message);
      console.log('   Error code:', error.code);
      console.log('   Error details:', error.details);
      console.log('   Error hint:', error.hint);
    } else {
      console.log('✅ API çağrısı başarılı');
      console.log('   Data:', data);
    }
    
  } catch (error) {
    console.log('❌ API test başarısız:', error.message);
  }
}

// 5. Auth'u sıfırla
async function resetAuth() {
  console.log('\n🔄 AUTH SIFIRLANIYOR...');
  
  try {
    if (!window.supabase) {
      console.log('❌ Supabase client bulunamadı');
      return;
    }
    
    // Mevcut oturumu kapat
    const { error } = await window.supabase.auth.signOut();
    
    if (error) {
      console.log('❌ Oturum kapatma hatası:', error.message);
      return;
    }
    
    console.log('✅ Oturum başarıyla kapatıldı');
    
    // LocalStorage'ı temizle
    const supabaseKeys = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.includes('supabase')) {
        supabaseKeys.push(key);
      }
    }
    
    supabaseKeys.forEach(key => {
      localStorage.removeItem(key);
      console.log(`🗑️ ${key} silindi`);
    });
    
    console.log('✅ Auth verileri temizlendi');
    
  } catch (error) {
    console.log('❌ Auth sıfırlama başarısız:', error.message);
  }
}

// 6. Manuel token kontrolü
function checkManualToken() {
  console.log('\n🔍 MANUEL TOKEN KONTROLÜ:');
  
  try {
    // LocalStorage'dan token'ı al
    const tokenData = localStorage.getItem('supabase.auth.token');
    
    if (!tokenData) {
      console.log('❌ Token verisi bulunamadı');
      return;
    }
    
    const token = JSON.parse(tokenData);
    console.log('📋 Token detayları:');
    console.log(`   Access Token: ${token.access_token ? 'Mevcut' : 'Yok'}`);
    console.log(`   Refresh Token: ${token.refresh_token ? 'Mevcut' : 'Yok'}`);
    console.log(`   Expires At: ${token.expires_at ? new Date(token.expires_at * 1000).toLocaleString() : 'Yok'}`);
    
    // Token'ın geçerli olup olmadığını kontrol et
    if (token.expires_at) {
      const now = Math.floor(Date.now() / 1000);
      const isExpired = token.expires_at < now;
      console.log(`   Token Geçerli: ${!isExpired ? '✅ Evet' : '❌ Hayır (Süresi dolmuş)'}`);
      
      if (isExpired) {
        console.log('⚠️ Token süresi dolmuş! Yenileme gerekli.');
      }
    }
    
  } catch (error) {
    console.log('❌ Manuel token kontrolü başarısız:', error.message);
  }
}

// 7. Ana debug fonksiyonu
async function debugAuth401() {
  console.log('🚀 401 UNAUTHORIZED DEBUG BAŞLATILIYOR...');
  
  try {
    // Adım 1: Mevcut auth durumunu kontrol et
    await checkAuthStatus();
    
    // Adım 2: LocalStorage'ı kontrol et
    checkLocalStorage();
    
    // Adım 3: Manuel token kontrolü
    checkManualToken();
    
    // Adım 4: Test API çağrısı yap
    await testApiCall();
    
    // Adım 5: Token yenilemeyi dene
    await refreshToken();
    
    console.log('\n✅ DEBUG TAMAMLANDI!');
    console.log('💡 Öneriler:');
    console.log('   1. Eğer token süresi dolmuşsa, yeniden giriş yapın');
    console.log('   2. Eğer session yoksa, login sayfasına gidin');
    console.log('   3. Browser cache\'ini temizleyin');
    console.log('   4. Farklı bir tarayıcı deneyin');
    
  } catch (error) {
    console.error('💥 Debug sırasında hata:', error);
  }
}

// 8. Global fonksiyonları tanımla
if (typeof window !== 'undefined') {
  window.debugAuth401 = debugAuth401;
  window.checkAuthStatus = checkAuthStatus;
  window.checkLocalStorage = checkLocalStorage;
  window.refreshToken = refreshToken;
  window.testApiCall = testApiCall;
  window.resetAuth = resetAuth;
  window.checkManualToken = checkManualToken;
  
  console.log('\n📋 KULLANIM TALİMATLARI:');
  console.log('1. debugAuth401() - Tüm kontrolleri çalıştırır');
  console.log('2. checkAuthStatus() - Auth durumunu kontrol eder');
  console.log('3. checkLocalStorage() - LocalStorage\'ı kontrol eder');
  console.log('4. refreshToken() - Token yenilemeyi dener');
  console.log('5. testApiCall() - Test API çağrısı yapar');
  console.log('6. resetAuth() - Auth\'u sıfırlar');
  console.log('7. checkManualToken() - Manuel token kontrolü yapar');
  
  console.log('\n🚀 OTOMATİK DEBUG BAŞLATILIYOR...');
  debugAuth401();
} else {
  console.log('Node.js ortamında çalıştırılıyor...');
  debugAuth401();
} 