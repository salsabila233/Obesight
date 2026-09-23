const fs = require('fs');
const zlib = require('zlib');
const jpeg = require('jpeg-js');

const pdfPath = 'C:/Users/david/.gemini/antigravity-ide/brain/9c01aaae-a59e-451b-9046-19fafbd9ec7d/.user_uploaded/media_1790170322398.pdf';
const buf = fs.readFileSync(pdfPath);
const str = buf.toString('latin1');

const regex = /<<([^>]*?\/Subtype\s*\/Image[^>]*?)>>\s*stream\r?\n([\s\S]*?)\r?\nendstream/g;
let m;
let idx = 0;
const images = [];

while ((m = regex.exec(str)) !== null) {
  idx++;
  const header = m[1];
  const streamData = Buffer.from(m[2], 'latin1');
  const widthM = header.match(/\/Width\s+(\d+)/);
  const heightM = header.match(/\/Height\s+(\d+)/);
  const width = widthM ? parseInt(widthM[1]) : 0;
  const height = heightM ? parseInt(heightM[1]) : 0;
  images.push({ idx, header, width, height, data: streamData });
}

function createPng(width, height, rgbaBuffer) {
  function crc32(buf) {
    let table = [];
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let k = 0; k < 8; k++) {
        c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      table[i] = c;
    }
    let crc = 0 ^ (-1);
    for (let i = 0; i < buf.length; i++) {
      crc = (crc >>> 8) ^ table[(crc ^ buf[i]) & 0xFF];
    }
    return (crc ^ (-1)) >>> 0;
  }

  function makeChunk(type, data) {
    const len = data.length;
    const buf = Buffer.alloc(len + 12);
    buf.writeUInt32BE(len, 0);
    buf.write(type, 4, 4, 'ascii');
    data.copy(buf, 8);
    const crc = crc32(buf.slice(4, 8 + len));
    buf.writeUInt32BE(crc, 8 + len);
    return buf;
  }

  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8;
  ihdrData[9] = 6; // RGBA
  ihdrData[10] = 0;
  ihdrData[11] = 0;
  ihdrData[12] = 0;
  const ihdrChunk = makeChunk('IHDR', ihdrData);

  const scanlines = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    const rowOffset = y * (width * 4 + 1);
    scanlines[rowOffset] = 0;
    rgbaBuffer.copy(scanlines, rowOffset + 1, y * width * 4, (y + 1) * width * 4);
  }

  const idatData = zlib.deflateSync(scanlines);
  const idatChunk = makeChunk('IDAT', idatData);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

function processJpegWithMask(jpegImg, maskImg, outPath) {
  const decoded = jpeg.decode(jpegImg.data, { useTArray: true });
  const alpha = zlib.inflateSync(maskImg.data);
  const rgba = Buffer.alloc(decoded.width * decoded.height * 4);
  
  for (let i = 0; i < decoded.width * decoded.height; i++) {
    rgba[i * 4] = decoded.data[i * 4];
    rgba[i * 4 + 1] = decoded.data[i * 4 + 1];
    rgba[i * 4 + 2] = decoded.data[i * 4 + 2];
    rgba[i * 4 + 3] = alpha[i] !== undefined ? alpha[i] : 255;
  }
  const pngBuf = createPng(decoded.width, decoded.height, rgba);
  fs.writeFileSync(outPath, pngBuf);
  console.log('Saved transparent PNG:', outPath, `${decoded.width}x${decoded.height}`);
}

// 1. Hands with chart (Image 13 + Mask 14)
processJpegWithMask(images[12], images[13], 'assets/bmi_hero_hands.png');

// 2. Magnifying glass (Image 15 + Mask 16)
processJpegWithMask(images[14], images[15], 'assets/bmi_magnifying_glass.png');

// 3. Clipboard check (Image 17 + Mask 18)
const img17 = images[16];
const img18 = images[17];
const rgb = zlib.inflateSync(img17.data);
const alpha = zlib.inflateSync(img18.data);
const rgba = Buffer.alloc(img17.width * img17.height * 4);
for (let i = 0; i < img17.width * img17.height; i++) {
  rgba[i * 4] = rgb[i * 3];
  rgba[i * 4 + 1] = rgb[i * 3 + 1];
  rgba[i * 4 + 2] = rgb[i * 3 + 2];
  rgba[i * 4 + 3] = alpha[i];
}
fs.writeFileSync('assets/bmi_clipboard_check.png', createPng(img17.width, img17.height, rgba));
console.log('Saved transparent PNG: assets/bmi_clipboard_check.png');

// 4. Woman running (Image 19 + Mask 20)
processJpegWithMask(images[18], images[19], 'assets/bmi_woman_running.png');

console.log('All 4 assets processed successfully!');
