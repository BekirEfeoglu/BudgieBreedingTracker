// Kayıt Olma Debug Scripti
// Bu dosyayı tarayıcı console'unda çalıştırın

console.log('🔧 Kayıt Olma Debug Başlatılıyor...');

// 1. Mevcut durumu kontrol et
console.log('📊 Mevcut Durum:');
console.log('- LocalStorage boyutu:', localStorage.length);
console.log('- SessionStorage boyutu:', sessionStorage.length);

// Rate limit verilerini kontrol et
const rateLimitKeys = [];
for (let i = 0; i < localStorage.length; i++) {
  const key = localStorage.key(i);
  if (key && key.includes('rateLimit')) {
    rateLimitKeys.push(key);
  }
}
console.log('- Rate limit anahtarları:', rateLimitKeys);

// 2. Tüm rate limit verilerini temizle
console.log('🧹 Rate limit verileri temizleniyor...');
rateLimitKeys.forEach(key => {
  localStorage.removeItem(key);
  console.log(`✅ ${key} temizlendi`);
});

// 3. Tüm localStorage'ı temizle (Supabase rate limit için)
console.log('🧹 Tüm localStorage temizleniyor...');
localStorage.clear();
sessionStorage.clear();

// 4. Rate limiting'i devre dışı bırak
localStorage.setItem('rateLimitDisabled', 'true');
console.log('🚫 Rate limiting devre dışı bırakıldı');

// 5. Supabase bağlantısını test et
console.log('🔗 Supabase bağlantısı test ediliyor...');

// Supabase'i yükle
async function testSupabase() {
  try {
    const { createClient } = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2');
    
    const supabase = createClient(
      "https://jxbfdgyusoehqybxdnii.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0yeW8cunOtrKGGakLv_7yZi1vbV1Q1fXsJJeg"
    );
    
    console.log('✅ Supabase client oluşturuldu');
    
    // Bağlantı testi
    const { data, error } = await supabase.from('profiles').select('count').limit(1);
    
    if (error) {
      console.log('❌ Supabase bağlantı hatası:', error.message);
    } else {
      console.log('✅ Supabase bağlantısı başarılı');
    }
    
    // Kayıt testi
    console.log('🔄 Kayıt testi başlatılıyor...');
    
    const testEmail = 'test' + Date.now() + '@example.com';
    const testPassword = 'Test123';
    
    console.log('📧 Test e-posta:', testEmail);
    console.log('🔐 Test şifre:', testPassword);
    
    const { data: signupData, error: signupError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
      options: {
        emailRedirectTo: 'https://www.budgiebreedingtracker.com/',
        data: {
          first_name: 'Test',
          last_name: 'Kullanıcı',
        },
      },
    });
    
    console.log('📡 Kayıt yanıtı:');
    console.log('- Veri var mı:', !!signupData);
    console.log('- Hata var mı:', !!signupError);
    
    if (signupError) {
      console.log('❌ Kayıt hatası:', signupError.message);
      console.log('- Hata kodu:', signupError.status);
      console.log('- Hata tipi:', signupError.name);
    } else {
      console.log('✅ Kayıt başarılı!');
      console.log('- Kullanıcı ID:', signupData.user?.id);
      console.log('- E-posta onayı gerekli:', !signupData.user?.email_confirmed_at);
    }
    
  } catch (error) {
    console.log('💥 Beklenmeyen hata:', error.message);
  }
}

// Test'i çalıştır
testSupabase();

console.log('🎉 Debug tamamlandı!');
console.log('💡 Şimdi uygulamada kayıt olmayı deneyin.'); 