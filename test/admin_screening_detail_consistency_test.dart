import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/screening_history_model.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/services/admin_user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user_test_123',
    name: 'Budi Santoso',
    email: 'budi@example.com',
    username: 'budisantoso',
    phone: '081234567890',
    gender: 'Laki-laki',
    dob: '1998-05-20',
    role: UserRole.user,
  );

  final normalScreening = ScreeningHistoryItem(
    id: 'scr_normal_1',
    userId: 'user_test_123',
    date: DateTime(2026, 11, 15, 10, 30),
    bmi: 21.5,
    risk: 'Risiko Terkendali',
    category: 'Normal Weight',
    skriningData: SkriningData(
      gender: 'Laki-laki',
      age: 28,
      height: 170,
      weight: 62,
      isPredictionSuccess: true,
      aiCategoryTitle: 'Normal Weight',
      aiCategoryKey: 'Normal',
      aiCategoryBadge: 'Ideal',
    ),
  );

  final overweightScreening = ScreeningHistoryItem(
    id: 'scr_overweight_1',
    userId: 'user_test_123',
    date: DateTime(2026, 10, 10, 14, 15),
    bmi: 24.2,
    risk: 'Risiko Meningkat',
    category: 'Overweight Level I',
    skriningData: SkriningData(
      gender: 'Laki-laki',
      age: 28,
      height: 170,
      weight: 70,
      isPredictionSuccess: true,
      aiCategoryTitle: 'Overweight Level I',
      aiCategoryKey: 'Overweight',
      aiCategoryBadge: 'Level 1',
    ),
  );

  final insufficientWeightScreening = ScreeningHistoryItem(
    id: 'scr_underweight_1',
    userId: 'user_test_123',
    date: DateTime(2026, 9, 5, 8, 0),
    bmi: 17.2,
    risk: 'Perlu Perhatian',
    category: 'Insufficient Weight',
    skriningData: SkriningData(
      gender: 'Laki-laki',
      age: 28,
      height: 175,
      weight: 52,
      isPredictionSuccess: true,
      aiCategoryTitle: 'Insufficient Weight',
      aiCategoryKey: 'Underweight',
      aiCategoryBadge: 'Kurang',
    ),
  );

  group('Perbaikan Integrasi & Konsistensi Skrining Admin', () {
    test('ScreeningHistoryItem.fromMap properly reconstructs normal weight category', () {
      final mapData = {
        'id': 'scr_1',
        'userId': 'user_test_123',
        'date': '2026-11-15T10:30:00.000',
        'bmi': 21.5,
        'category': 'Normal Weight',
        'categoryTitle': 'Normal Weight',
        'classificationCategory': 'Normal',
        'risk': 'Risiko Terkendali',
        'height': 170.0,
        'weight': 62.0,
      };

      final item = ScreeningHistoryItem.fromMap(mapData);
      expect(item.category, equals('Normal Weight'));
      expect(item.skriningData.categoryTitle, contains('Normal'));
      expect(item.bmi, closeTo(21.45, 0.1));
    });

    testWidgets('Detail profil skrining menampilkan klasifikasi konsisten (Normal Weight di kedua bagian)', (tester) async {
      AdminUserService.instance.setMockUserScreenings('user_test_123', [normalScreening]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_test_123',
            initialUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan teks "Normal Weight" muncul di kedua bagian (Hasil Skrining Terakhir & Riwayat Singkat)
      final normalWeightFinder = find.text('Normal Weight');
      expect(normalWeightFinder, findsNWidgets(2));

      // Pastikan badge "Ideal" muncul di kedua bagian
      expect(find.text('Ideal'), findsAtLeastNWidgets(1));

      // PENTING: Pada Riwayat Singkat, jangan ada badge atau klasifikasi "Level 1" ketika data sebenarnya adalah Normal Weight
      expect(find.text('Level 1'), findsNothing);

      // Verifikasi Scaffold backgroundColor adalah putih (Colors.white), bukan sageGreen
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('Detail profil skrining menampilkan klasifikasi Overweight secara konsisten jika data memang Overweight', (tester) async {
      AdminUserService.instance.setMockUserScreenings('user_test_123', [overweightScreening]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_test_123',
            initialUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan teks "Overweight" muncul
      expect(find.text('Overweight'), findsAtLeastNWidgets(1));
      expect(find.text('Level 1'), findsAtLeastNWidgets(1));

      // Scaffold background tetap putih
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('Kotak Informasi Pribadi telah dihapus dan card Hasil Skrining Terakhir hadir full width', (tester) async {
      AdminUserService.instance.setMockUserScreenings('user_test_123', [normalScreening]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_test_123',
            initialUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan tulisan "Informasi Pribadi" TIDAK ADA
      expect(find.text('Informasi Pribadi'), findsNothing);

      // Pastikan "Hasil Skrining Terakhir" ada
      expect(find.text('Hasil Skrining Terakhir'), findsOneWidget);

      // Pastikan lekukan lembaran atas dengan Radius 28 ada
      final clipRRect = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(ClipRRect),
        ).first,
      );
      expect(clipRRect.borderRadius, equals(const BorderRadius.vertical(top: Radius.circular(28))));
    });

    testWidgets('Detail profil skrining menampilkan kategori Insufficient Weight dan badge Kurang secara seragam', (tester) async {
      AdminUserService.instance.setMockUserScreenings('user_test_123', [insufficientWeightScreening]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_test_123',
            initialUser: testUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Judul harus "Insufficient Weight", bukan "Underweight"
      expect(find.text('Insufficient Weight'), findsNWidgets(2));
      expect(find.text('Underweight'), findsNothing);

      // Sub-kategori & badge harus "Kurang"
      expect(find.text('Kurang'), findsAtLeastNWidgets(1));
    });

    testWidgets('Background tetap putih secara konsisten ketika belum ada data skrining (empty state)', (tester) async {
      AdminUserService.instance.setMockUserScreenings('user_empty', []);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_empty',
            initialUser: testUser.copyWith(id: 'user_empty'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty states
      expect(find.text('Belum Ada Skrining'), findsOneWidget);
      expect(find.text('Belum ada riwayat skrining'), findsOneWidget);

      // Scaffold background tetap putih
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });
  });
}

