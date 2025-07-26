// JWT TOKEN VE AUTHENTICATION DEBUG SCRIPT
// Bu dosyayı browser console'da çalıştırın

console.log('🔍 JWT Token ve Authentication Debug Başlatılıyor...');

// 1. LocalStorage'dan token'ları kontrol et
console.log('📦 LocalStorage Token Kontrolü:');
const supabaseTokens = localStorage.getItem('sb-etkvuonkmmzihsjwbcrl-auth-token');
if (supabaseTokens) {
  try {
    const tokens = JSON.parse(supabaseTokens);
    console.log('✅ Supabase token bulundu:', {
      access_token: tokens.access_token ? `${tokens.access_token.substring(0, 20)}...` : 'YOK',
      refresh_token: tokens.refresh_token ? `${tokens.refresh_token.substring(0, 20)}...` : 'YOK',
      expires_at: tokens.expires_at ? new Date(tokens.expires_at * 1000).toLocaleString() : 'YOK',
      expires_in: tokens.expires_in || 'YOK',
      token_type: tokens.token_type || 'YOK',
      user_id: tokens.user?.id || 'YOK',
      user_email: tokens.user?.email || 'YOK'
    });
    
    // Token'ın geçerliliğini kontrol et
    if (tokens.expires_at) {
      const now = Math.floor(Date.now() / 1000);
      const isExpired = tokens.expires_at < now;
      console.log('⏰ Token Geçerlilik Durumu:', {
        şu_an: new Date(now * 1000).toLocaleString(),
        son_kullanma: new Date(tokens.expires_at * 1000).toLocaleString(),
        süresi_dolmuş: isExpired,
        kalan_süre_dakika: Math.floor((tokens.expires_at - now) / 60)
      });
    }
  } catch (error) {
    console.error('❌ Token parse hatası:', error);
  }
} else {
  console.log('❌ Supabase token bulunamadı');
}

// 2. Supabase client'ın mevcut durumunu kontrol et
console.log('\n🔧 Supabase Client Durumu:');
if (window.supabase) {
  console.log('✅ Supabase client mevcut');
  
  // Session'ı kontrol et
  window.supabase.auth.getSession().then(({ data, error }) => {
    if (error) {
      console.error('❌ Session alma hatası:', error);
    } else {
      console.log('📋 Mevcut Session:', {
        hasSession: !!data.session,
        userId: data.session?.user?.id || 'YOK',
        userEmail: data.session?.user?.email || 'YOK',
        expiresAt: data.session?.expires_at ? new Date(data.session.expires_at * 1000).toLocaleString() : 'YOK',
        accessToken: data.session?.access_token ? `${data.session.access_token.substring(0, 20)}...` : 'YOK'
      });
    }
  });
} else {
  console.log('❌ Supabase client bulunamadı');
}

// 3. React context'ten auth durumunu kontrol et
console.log('\n⚛️ React Auth Context Durumu:');
if (window.React && window.React.useContext) {
  // Auth context'i bulmaya çalış
  console.log('✅ React mevcut, context kontrol ediliyor...');
} else {
  console.log('❌ React context erişilemiyor');
}

// 4. Network isteklerini izle
console.log('\n🌐 Network İstekleri İzleniyor...');
const originalFetch = window.fetch;
window.fetch = function(...args) {
  const url = args[0];
  const options = args[1] || {};
  
  // Supabase isteklerini filtrele
  if (typeof url === 'string' && url.includes('supabase.co')) {
    console.log('📡 Supabase İsteği:', {
      url: url,
      method: options.method || 'GET',
      hasAuthHeader: options.headers && options.headers.Authorization ? '✅ VAR' : '❌ YOK',
      hasApiKey: options.headers && options.headers.apikey ? '✅ VAR' : '❌ YOK',
      authHeaderValue: options.headers && options.headers.Authorization ? 
        options.headers.Authorization.substring(0, 20) + '...' : 'YOK'
    });
  }
  
  return originalFetch.apply(this, args);
};

// 5. Test isteği gönder
console.log('\n🧪 Test İsteği Gönderiliyor...');
fetch('https://etkvuonkmmzihsjwbcrl.supabase.co/rest/v1/birds?select=count', {
  method: 'GET',
  headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzandiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE',
    'Authorization': `Bearer ${supabaseTokens ? JSON.parse(supabaseTokens).access_token : 'NO_TOKEN'}`
  }
})
.then(response => {
  console.log('📊 Test İsteği Sonucu:', {
    status: response.status,
    statusText: response.statusText,
    ok: response.ok,
    headers: Object.fromEntries(response.headers.entries())
  });
  return response.json();
})
.then(data => {
  console.log('📋 Test İsteği Verisi:', data);
})
.catch(error => {
  console.error('❌ Test İsteği Hatası:', error);
});

// 6. Manuel token yenileme testi
console.log('\n🔄 Manuel Token Yenileme Testi:');
if (window.supabase) {
  window.supabase.auth.refreshSession().then(({ data, error }) => {
    if (error) {
      console.error('❌ Token yenileme hatası:', error);
    } else {
      console.log('✅ Token yenileme başarılı:', {
        hasNewSession: !!data.session,
        newUserId: data.session?.user?.id || 'YOK',
        newExpiresAt: data.session?.expires_at ? new Date(data.session.expires_at * 1000).toLocaleString() : 'YOK'
      });
    }
  });
}

// 7. Auth state listener testi
console.log('\n👂 Auth State Listener Testi:');
if (window.supabase) {
  const { data: { subscription } } = window.supabase.auth.onAuthStateChange((event, session) => {
    console.log('🔐 Auth State Change:', {
      event,
      hasSession: !!session,
      userId: session?.user?.id || 'YOK',
      userEmail: session?.user?.email || 'YOK'
    });
  });
  
  // 5 saniye sonra listener'ı kapat
  setTimeout(() => {
    subscription.unsubscribe();
    console.log('👂 Auth state listener kapatıldı');
  }, 5000);
}

// 8. LocalStorage temizleme testi (isteğe bağlı)
console.log('\n🧹 LocalStorage Temizleme Seçeneği:');
console.log('Eğer token sorunları devam ederse, aşağıdaki komutu çalıştırabilirsiniz:');
console.log('localStorage.removeItem("sb-etkvuonkmmzihsjwbcrl-auth-token"); location.reload();');

console.log('\n🎯 Debug tamamlandı! Yukarıdaki sonuçları kontrol edin.'); 