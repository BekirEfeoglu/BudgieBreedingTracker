const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const sizes = [
  { dir: 'mipmap-mdpi', size: 48 },
  { dir: 'mipmap-hdpi', size: 72 },
  { dir: 'mipmap-xhdpi', size: 96 },
  { dir: 'mipmap-xxhdpi', size: 144 },
  { dir: 'mipmap-xxxhdpi', size: 192 },
];

const src = path.resolve(__dirname, '../logo.png');
const resBase = path.resolve(__dirname, '../app/src/main/res');

sizes.forEach(({ dir, size }) => {
  const outDir = path.join(resBase, dir);
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  sharp(src)
    .resize(size, size)
    .png()
    .toFile(path.join(outDir, 'ic_launcher.png'), (err) => {
      if (err) console.error(`${dir} için hata:`, err);
      else console.log(`${dir} için ${size}x${size} ikon oluşturuldu.`);
    });
}); 