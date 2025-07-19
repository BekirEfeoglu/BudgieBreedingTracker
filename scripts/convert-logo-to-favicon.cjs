#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🎨 Logo\'dan Favicon Oluşturma');
console.log('=============================');

const logoPath = path.join(__dirname, '..', 'logo.png');
const publicPath = path.join(__dirname, '..', 'public');

console.log('\n📁 Kontrol edilen dosyalar:');
console.log(`   Logo: ${logoPath}`);
console.log(`   Public: ${publicPath}`);

if (fs.existsSync(logoPath)) {
  console.log('\n✅ Logo dosyası bulundu!');
  console.log('\n🔧 Yapılacaklar:');
  console.log('1. logo.png dosyasını public/ klasörüne kopyalayın');
  console.log('2. Dosya adını budgie-icon.png olarak değiştirin');
  console.log('3. Online favicon generator kullanın');
  console.log('4. Tüm boyutlarda simge oluşturun');
  
  console.log('\n📋 Önerilen adımlar:');
  console.log('1. https://realfavicongenerator.net/ adresine gidin');
  console.log('2. logo.png dosyasını yükleyin');
  console.log('3. "Generate" butonuna tıklayın');
  console.log('4. ZIP dosyasını indirin ve public/ klasörüne çıkartın');
  
} else {
  console.log('\n❌ Logo dosyası bulunamadı!');
  console.log('\n📋 Alternatif yöntemler:');
  console.log('1. Yeni simge hazırlayın (512x512px)');
  console.log('2. Online favicon generator kullanın');
  console.log('3. Manuel olarak dosyaları değiştirin');
}

console.log('\n✅ Tamamlandığında:');
console.log('   - Tarayıcı sekmesinde yeni simge görünecek');
console.log('   - Mobil cihazlarda ana ekran simgesi değişecek');
console.log('   - PWA kurulumunda yeni simge kullanılacak');

console.log('\n⚠️  Önemli:');
console.log('   - Tarayıcı cache\'ini temizleyin (Ctrl+F5)');
console.log('   - Tüm boyutlarda simge olmalı');
console.log('   - PNG formatı önerilir'); 