const fs = require('fs');
const path = require('path');

const sourceApk = 'C:\\Users\\Emanu\\.gemini\\antigravity\\scratch\\dnd_wiki\\build\\app\\outputs\\flutter-apk\\app-release.apk';
const destDir = 'g:\\Il mio Drive\\DnD\\Catalogo\\dnd_wiki';
const destApk = path.join(destDir, 'app-release.apk');

try {
  console.log(`Checking source APK: ${sourceApk}`);
  if (!fs.existsSync(sourceApk)) {
    throw new Error('Source APK does not exist!');
  }

  console.log(`Ensuring destination directory exists: ${destDir}`);
  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }

  console.log(`Copying APK to destination: ${destApk}`);
  fs.copyFileSync(sourceApk, destApk);

  const stats = fs.statSync(destApk);
  console.log(`APK successfully copied! Size: ${(stats.size / (1024 * 1024)).toFixed(2)} MB`);
} catch (err) {
  console.error('Failed to copy APK:', err.message);
  process.exit(1);
}
