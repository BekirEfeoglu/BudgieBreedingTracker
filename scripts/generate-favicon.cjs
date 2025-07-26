#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🎨 Favicon Oluşturma Aracı');
console.log('========================');

// Simge boyutları
const sizes = [16, 32, 48, 64, 128, 192, 512];

console.log('\n📋 Gerekli simge boyutları:');
sizes.forEach(size => {
  console.log(`   - ${size}x${size}px`);
});

console.log('\n📁 Değiştirilecek dosyalar:');
console.log('   - public/favicon.ico (16x16, 32x32, 48x48)');
console.log('   - public/favicon.png (32x32 veya 64x64)');
console.log('   - public/budgie-icon.png (512x512)');
console.log('   - public/icons/icon-*.png (tüm boyutlar)');

console.log('\n🔧 Manuel Yapılacaklar:');
console.log('1. Yeni simgenizi hazırlayın (en az 512x512px)');
console.log('2. Online favicon generator kullanın:');
console.log('   - https://realfavicongenerator.net/');
console.log('   - https://favicon.io/');
console.log('   - https://www.favicon-generator.org/');
console.log('3. Oluşturulan dosyaları public/ klasörüne kopyalayın');
console.log('4. Tarayıcı cache\'ini temizleyin (Ctrl+F5)');

console.log('\n✅ Tamamlandığında:');
console.log('   - Tarayıcı sekmesinde yeni simge görünecek');
console.log('   - Mobil cihazlarda ana ekran simgesi değişecek');
console.log('   - PWA kurulumunda yeni simge kullanılacak');

console.log('\n⚠️  Önemli Notlar:');
console.log('   - Simge PNG formatında olmalı');
console.log('   - Şeffaf arka plan önerilir');
console.log('   - Tüm boyutlarda net görünmeli');
console.log('   - Cache temizleme gerekebilir'); 