import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:obesight/firebase_options.dart';
import 'package:obesight/services/article_service.dart';

/// Script Seeding Terisolasi untuk 6 Artikel Awal ObeSight
///
/// HANYA DIJALANKAN SECARA EKSPLISIT ATAS PERSETUJUAN PENGGUNA.
///
/// Cara menjalankan:
/// dart run tool/seed_articles.dart
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flag opsional jika ingin memeriksa tanpa menulis: --check-only
  final checkOnly = args.contains('--check-only');
  // Flag opsional jika ingin menimpa secara paksa: --force
  final forceOverwrite = args.contains('--force');

  stdout.writeln('====================================================');
  stdout.writeln('OBESIGHT — SEEDING DATA ARTIKEL KE CLOUD FIRESTORE');
  stdout.writeln('Mode checkOnly      : $checkOnly');
  stdout.writeln('Mode forceOverwrite : $forceOverwrite');
  stdout.writeln('====================================================');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      stdout.writeln('[OK] Firebase initialized untuk project: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    }

    stdout.writeln('[..] Memeriksa koleksi articles di Cloud Firestore...');
    final result = await ArticleService().seedInitialArticles(
      forceOverwrite: forceOverwrite,
      checkOnly: checkOnly,
    );

    stdout.writeln('\n--- HASIL SEEDING / PEMERIKSAAN ---');
    stdout.writeln('Total dokumen target : ${result['total']}');
    stdout.writeln('Dokumen sudah ada    : ${result['existing']}');
    stdout.writeln('Dokumen belum ada    : ${result['missing']}');
    stdout.writeln('Dokumen baru dibuat  : ${result['created']}');
    stdout.writeln('Dokumen dilewati     : ${result['skipped']}');

    final details = result['details'] as Map<String, String>;
    details.forEach((docId, msg) {
      stdout.writeln('  • $docId : $msg');
    });

    if ((result['skipped'] as int) > 0 && !forceOverwrite) {
      stdout.writeln('\n[CATATAN] Dokumen yang sudah ada dilewati untuk mencegah data di Firebase Console tertimpa.');
      stdout.writeln('Jika ingin memperbarui paksa, jalankan dengan argumen: --force');
    }

    stdout.writeln('====================================================\n');
  } catch (e, stackTrace) {
    stderr.writeln('[ERROR] Gagal menjalankan seeding: $e');
    stderr.writeln(stackTrace);
    exit(1);
  }
}
