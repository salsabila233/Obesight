import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/article_model.dart';
import 'package:obesight/services/rest_reminder_service.dart';
import 'package:obesight/screens/article/health_article_list_screen.dart';
import 'package:obesight/screens/article/health_article_detail_screen.dart';
import 'package:obesight/screens/progress/rest_reminder_setting_screen.dart';
import 'package:obesight/widgets/curved_header_scaffold.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  group('Uji Komponen CurvedHeaderScaffold & Fitur Artikel Kesehatan', () {
    testWidgets('CurvedHeaderScaffold standar menampilkan header hijau pinned dan sheet melengkung (radius 28)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CurvedHeaderScaffold(
            title: 'Judul Percobaan',
            body: ListView(
              children: const [
                Text('Konten Lembaran 1'),
                Text('Konten Lembaran 2'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header title and back button
      expect(find.text('Judul Percobaan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Verifikasi container melengkung dengan radius 28
      final containerFinders = find.byType(Container);
      bool foundCurvedSheet = false;
      for (final element in containerFinders.evaluate()) {
        final container = element.widget as Container;
        if (container.decoration is BoxDecoration) {
          final box = container.decoration as BoxDecoration;
          if (box.borderRadius is BorderRadius) {
            final br = box.borderRadius as BorderRadius;
            if (br.topLeft == const Radius.circular(28) && br.topRight == const Radius.circular(28)) {
              foundCurvedSheet = true;
              break;
            }
          }
        }
      }
      expect(foundCurvedSheet, isTrue, reason: 'Harus ada container sheet dengan BorderRadius radius 28');
    });

    testWidgets('HealthArticleListScreen menggunakan header melengkung sticky dan konten ter-scroll', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HealthArticleListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header hijau pinned
      expect(find.text('Daftar Artikel Kesehatan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Komponen CurvedHeaderScaffold digunakan
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);

      // Banner Edukasi Kesehatan dan form pencarian muncul di dalam konten scrollable
      expect(find.text('EDUKASI KESEHATAN'), findsOneWidget);
      expect(find.text('Informasi & Panduan Gaya Hidup Sehat'), findsOneWidget);
      expect(find.text('Cari judul artikel...'), findsOneWidget);

      // Verifikasi container dengan radius 28 ada
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRadius28 = containers.any((c) {
        if (c.decoration is BoxDecoration) {
          final b = c.decoration as BoxDecoration;
          if (b.borderRadius is BorderRadius) {
            final br = b.borderRadius as BorderRadius;
            return br.topLeft == const Radius.circular(28) && br.topRight == const Radius.circular(28);
          }
        }
        return false;
      });
      expect(hasRadius28, isTrue);

      // Test scrolling konten
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);
      await tester.drag(listFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Header tetap pinned di atas
      expect(find.text('Daftar Artikel Kesehatan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('HealthArticleDetailScreen menampilkan collapsible photo header dan curved sheet radius 28', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testArticle = ArticleModel(
        id: 'test_1',
        title: 'Porsi Piring Sehat',
        category: 'Nutrisi',
        snippet: 'Ringkasan porsi piring sehat',
        readTime: '3 Menit Baca',
        date: '19 Oktober 2026',
        imageAsset: 'assets/logo.png',
        icon: Icons.restaurant_rounded,
        headerColor: const Color(0xFF36785A),
        content: 'Paragraf 1 isi artikel kesehatan.',
        takeaways: ['Poin Penting 1', 'Poin Penting 2'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HealthArticleDetailScreen(article: testArticle),
        ),
      );
      await tester.pumpAndSettle();

      // Memakai CurvedHeaderScaffold
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);

      // Memakai SliverAppBar pinned: true
      final sliverAppBarFinder = find.byType(SliverAppBar);
      expect(sliverAppBarFinder, findsOneWidget);
      final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
      expect(sliverAppBar.pinned, isTrue);
      expect(sliverAppBar.expandedHeight, 250);

      // Tombol back selalu ada
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Isi artikel
      expect(find.text('Porsi Piring Sehat'), findsWidgets);
      expect(find.text('3 Menit Baca'), findsOneWidget);
      expect(find.text('Ringkasan porsi piring sehat'), findsOneWidget);
      expect(find.text('Poin Penting untuk Diingat'), findsOneWidget);
      expect(find.text('Poin Penting 1'), findsOneWidget);

      // Scroll konten ke atas dan pastikan SliverAppBar tetap pinned
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('RestReminderSettingScreen kini menggunakan CurvedHeaderScaffold dengan sudut melengkung', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RestReminderSettingScreen(type: RestType.day),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);
      expect(find.text('Masukkan Data Istirahat'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });
}
