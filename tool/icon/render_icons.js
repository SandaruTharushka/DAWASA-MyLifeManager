// Renders tool/icon/dawasa_icon.svg to the PNG launcher icons used on
// Android 7.x (Android 8+ uses the adaptive vector icon).
//
//   NODE_PATH=$(npm root -g) node tool/icon/render_icons.js
//
// Requires Node.js with the "playwright" package and a Chromium build.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..', '..');
const svg = fs.readFileSync(path.join(__dirname, 'dawasa_icon.svg'), 'utf8');
const targets = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  async function render(size, file) {
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(
      `<html><body style="margin:0;background:transparent">` +
        svg.replace('<svg ', `<svg style="display:block;width:${size}px;height:${size}px" `) +
        `</body></html>`,
    );
    await page.screenshot({ path: file, omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
    console.log(file);
  }
  for (const [dir, size] of Object.entries(targets)) {
    await render(size, path.join(root, 'android/app/src/main/res', dir, 'ic_launcher.png'));
  }
  await render(512, path.join(root, 'website/public/icon-512.png'));
  await render(192, path.join(root, 'website/public/icon-192.png'));
  await browser.close();
})();
