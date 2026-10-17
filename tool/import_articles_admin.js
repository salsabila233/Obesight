/**
 * Script Impor Artikel ke Cloud Firestore Menggunakan Firebase Admin SDK
 * 
 * HANYA DIJALANKAN DENGAN AUTENTIKASI RESMI GOOGLE / FIREBASE ADMIN SDK.
 * 
 * Cara Penggunaan:
 * 1. Unduh Service Account Key dari Firebase Console:
 *    Project Settings -> Service Accounts -> "Generate new private key"
 * 2. Simpan file key tersebut di luar repository atau di folder lokal (misal: serviceAccountKey.json)
 *    (File ini sudah diabaikan oleh .gitignore dan TIDAK akan masuk ke git)
 * 3. Jalankan script ini:
 *    node tool/import_articles_admin.js serviceAccountKey.json
 * 
 * Atau gunakan environment variable:
 *    set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json
 *    node tool/import_articles_admin.js
 */

const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  const checkOnly = args.includes('--check-only');
  const force = args.includes('--force');

  // Cari path service account key dari argumen pertama yang bukan flag
  const keyArg = args.find(a => !a.startsWith('--'));
  const envKey = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const keyPath = keyArg || envKey;

  console.log('====================================================');
  console.log('OBESIGHT — IMPOR ARTIKEL CLOUD FIRESTORE (ADMIN SDK)');
  console.log(`Mode checkOnly : ${checkOnly}`);
  console.log(`Mode force     : ${force}`);
  console.log('====================================================');

  if (!keyPath) {
    console.error('\n[PETUNJUK AUTENTIKASI]');
    console.error('Firebase Admin SDK memerlukan kredensial Service Account resmi.');
    console.error('Langkah mendapatkan Service Account Key:');
    console.error('  1. Buka Firebase Console -> Project Settings -> Service accounts.');
    console.error('  2. Klik tombol "Generate new private key".');
    console.error('  3. Simpan file JSON hasil download ke direktori proyek sebagai "serviceAccountKey.json".');
    console.error('     (File ini aman karena sudah terdaftar di .gitignore)');
    console.error('  4. Jalankan kembali: node tool/import_articles_admin.js serviceAccountKey.json\n');
    process.exit(1);
  }

  const resolvedKeyPath = path.resolve(keyPath);
  if (!fs.existsSync(resolvedKeyPath)) {
    console.error(`[ERROR] File kredensial tidak ditemukan pada path: ${resolvedKeyPath}`);
    process.exit(1);
  }

  // Muat firebase-admin
  let admin;
  try {
    admin = require('firebase-admin');
  } catch (_) {
    console.error('\n[INFO] Modul firebase-admin belum terpasang.');
    console.error('Jalankan: npm install --no-save firebase-admin');
    process.exit(1);
  }

  const serviceAccount = require(resolvedKeyPath);

  // Validasi ketat: Project ID WAJIB 'obesight'
  const serviceProjectId = serviceAccount.project_id;
  if (serviceProjectId && serviceProjectId !== 'obesight') {
    console.error(`\n[ERROR] Project ID dalam file service account adalah '${serviceProjectId}'.`);
    console.error(`Script ini secara khusus dikonfigurasi HANYA untuk project 'obesight'.`);
    console.error(`Proses dihentikan demi keamanan data.\n`);
    process.exit(1);
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'obesight'
    });
    console.log(`[OK] Firebase Admin initialized untuk project: obesight`);
  }

  const db = admin.firestore();

  // Baca data artikel
  const dataPath = path.join(__dirname, 'articles_seed_data.json');
  if (!fs.existsSync(dataPath)) {
    console.error(`[ERROR] File data artikel tidak ditemukan: ${dataPath}`);
    process.exit(1);
  }

  const rawData = fs.readFileSync(dataPath, 'utf8');
  const articles = JSON.parse(rawData);

  console.log(`[..] Memeriksa ${articles.length} dokumen artikel di koleksi 'articles'...`);

  let created = 0;
  let skipped = 0;
  let existing = 0;
  let missing = 0;

  for (const article of articles) {
    const docId = article.id;
    const docRef = db.collection('articles').doc(docId);
    const docSnap = await docRef.get();

    if (docSnap.exists) {
      existing++;
      if (checkOnly) {
        skipped++;
        console.log(`  • ${docId}: SUDAH ADA di Firestore.`);
        continue;
      }

      if (!force) {
        skipped++;
        console.log(`  • ${docId}: SUDAH ADA. Dilewati agar tidak menimpa data di Firebase Console.`);
      } else {
        await docRef.set({
          title: article.title,
          snippet: article.snippet,
          date: article.date || '',
          content: article.content,
          category: article.category,
          readTime: article.readTime,
          imageAsset: article.imageAsset,
          imageUrl: article.imageUrl || '',
          headerColorHex: article.headerColorHex,
          iconName: article.iconName,
          author: article.author,
          isPublished: article.isPublished,
          publishedAt: admin.firestore.Timestamp.fromDate(new Date(article.publishedAt)),
          updatedAt: admin.firestore.Timestamp.fromDate(new Date(article.updatedAt)),
          takeaways: article.takeaways || []
        });
        created++;
        console.log(`  • ${docId}: BERHASIL diperbarui (force overwrite).`);
      }
    } else {
      missing++;
      if (checkOnly) {
        console.log(`  • ${docId}: BELUM ADA di Firestore.`);
        continue;
      }

      await docRef.set({
        title: article.title,
        snippet: article.snippet,
        date: article.date || '',
        content: article.content,
        category: article.category,
        readTime: article.readTime,
        imageAsset: article.imageAsset,
        imageUrl: article.imageUrl || '',
        headerColorHex: article.headerColorHex,
        iconName: article.iconName,
        author: article.author,
        isPublished: article.isPublished,
        publishedAt: admin.firestore.Timestamp.fromDate(new Date(article.publishedAt)),
        updatedAt: admin.firestore.Timestamp.fromDate(new Date(article.updatedAt)),
        takeaways: article.takeaways || []
      });
      created++;
      console.log(`  • ${docId}: BERHASIL dibuat.`);
    }
  }

  console.log('\n--- RINGKASAN HASIL ---');
  console.log(`Total dokumen target : ${articles.length}`);
  console.log(`Dokumen sudah ada    : ${existing}`);
  console.log(`Dokumen belum ada    : ${missing}`);
  console.log(`Dokumen baru dibuat  : ${created}`);
  console.log(`Dokumen dilewati     : ${skipped}`);
  console.log('====================================================\n');
}

main().catch(err => {
  console.error('[ERROR] Gagal memproses impor:', err);
  process.exit(1);
});
