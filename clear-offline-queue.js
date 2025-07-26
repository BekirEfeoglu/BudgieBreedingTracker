// Offline Queue Temizleme Scripti
// Bu dosyayı browser console'da çalıştırın

console.log('🧹 Offline queue temizleniyor...');

// LocalStorage'daki offline queue'yu temizle
localStorage.removeItem('offlineQueue');

// Diğer potansiyel cache'leri de temizle
localStorage.removeItem('offline_sync_queue');
localStorage.removeItem('sync_queue');
localStorage.removeItem('pending_operations');

// Cache storage'ı da temizle (eğer varsa)
if ('caches' in window) {
  caches.keys().then(names => {
    names.forEach(name => {
      if (name.includes('offline') || name.includes('sync')) {
        caches.delete(name);
        console.log(`🗑️ Cache silindi: ${name}`);
      }
    });
  });
}

console.log('✅ Offline queue başarıyla temizlendi!');
console.log('🔄 Sayfayı yenileyin ve tekrar deneyin.'); 