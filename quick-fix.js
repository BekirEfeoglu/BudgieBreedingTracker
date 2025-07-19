// 🚨 HIZLI DÜZELTME KODU - Console'da çalıştırın

console.log('🧹 Hızlı düzeltme başlatılıyor...');

// 1. Tüm storage'ları temizle
localStorage.clear();
sessionStorage.clear();
console.log('✅ LocalStorage ve SessionStorage temizlendi');

// 2. Cookies'i temizle
document.cookie.split(";").forEach(function(c) { 
  document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
});
console.log('✅ Cookies temizlendi');

// 3. IP adresini kontrol et
fetch('https://api.ipify.org?format=json')
  .then(response => response.json())
  .then(data => {
    console.log('🌐 Mevcut IP Adresi:', data.ip);
    console.log('⚠️ Bu IP rate limit\'e takılmış olabilir');
    console.log('💡 VPN kullanmanız önerilir');
  })
  .catch(error => {
    console.log('❌ IP adresi alınamadı:', error);
  });

// 4. Test e-postası oluştur
const testEmail = `test${Date.now()}@gmail.com`;
console.log('📧 Test e-postası:', testEmail);
console.log('🔐 Test şifresi: Test123456');

// 5. Supabase session'ı temizle
if (window.supabase) {
  window.supabase.auth.signOut().then(() => {
    console.log('🔐 Supabase session temizlendi');
  });
}

// 6. Sayfayı yenile
console.log('🔄 Sayfa 3 saniye sonra yenilenecek...');
setTimeout(() => {
  window.location.reload();
}, 3000);

console.log('🎯 Şimdi VPN açın ve tekrar deneyin!'); 