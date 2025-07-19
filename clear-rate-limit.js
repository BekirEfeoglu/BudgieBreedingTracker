// Rate Limit Temizleme Scripti
// Bu dosyayı tarayıcı console'unda çalıştırın

console.log('🧹 Rate limit verileri temizleniyor...');

// Tüm rate limit verilerini temizle
const keysToRemove = [];
for (let i = 0; i < localStorage.length; i++) {
  const key = localStorage.key(i);
  if (key && key.startsWith('rateLimit_')) {
    keysToRemove.push(key);
  }
}

keysToRemove.forEach(key => {
  localStorage.removeItem(key);
  console.log(`✅ ${key} temizlendi`);
});

// Rate limiting'i devre dışı bırak
localStorage.setItem('rateLimitDisabled', 'true');
console.log('🚫 Rate limiting devre dışı bırakıldı');

console.log('🎉 Rate limit temizleme tamamlandı!');
console.log('Artık kayıt olmayı deneyebilirsiniz.'); 