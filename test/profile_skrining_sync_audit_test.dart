import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/screens/skrining/skrining_result_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/services/random_forest_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('A. Sinkronisasi Nama Profil dengan SkriningResultScreen', () {
    testWidgets('1. Menampilkan nama tersimpan dan valid pada profil pengguna', (tester) async {
      const user = UserModel(
        id: 'usr_audit_01',
        name: 'Budi Santoso',
        email: 'budi@example.com',
        username: 'budisantoso',
        role: UserRole.user,
      );

      AuthService().updateUserProfile(
        userId: user.id,
        name: 'Budi Santoso',
      );

      final testData = SkriningData(
        gender: 'Laki-laki',
        age: 25,
        height: 170,
        weight: 65,
        aiCategoryTitle: 'Normal\nWeight',
        aiCategoryBadge: 'Berat badan berada dalam rentang ideal',
        isPredictionSuccess: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testData, user: user),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Zahra Fitriana'), findsNothing);
    });

    testWidgets('2. Nama profil diperbarui, lalu hasil skrining menampilkan nama terbaru', (tester) async {
      const initialUser = UserModel(
        id: 'usr_audit_02',
        name: 'Nama Lama',
        email: 'user2@example.com',
        username: 'user2',
        role: UserRole.user,
      );

      // Inisialisasi awal
      await AuthService().updateUserProfile(
        userId: initialUser.id,
        name: 'Nama Lama',
      );

      // Perbarui nama profil
      await AuthService().updateUserProfile(
        userId: initialUser.id,
        name: 'Salsabila Putri',
      );

      final testData = SkriningData(
        gender: 'Perempuan',
        age: 22,
        height: 160,
        weight: 50,
        aiCategoryTitle: 'Normal\nWeight',
        aiCategoryBadge: 'Berat badan berada dalam rentang ideal',
        isPredictionSuccess: true,
      );

      // Buka SkriningResultScreen dengan instance awal initialUser
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testData, user: initialUser),
        ),
      );
      await tester.pumpAndSettle();

      // Hasil skrining harus menampilkan nama terbaru 'Salsabila Putri', BUKAN 'Nama Lama' dan BUKAN 'Zahra Fitriana'
      expect(find.text('Salsabila Putri'), findsOneWidget);
      expect(find.text('Nama Lama'), findsNothing);
      expect(find.text('Zahra Fitriana'), findsNothing);
    });

    testWidgets('3. Profil tanpa nama menampilkan fallback wajar (Pengguna ObeSight) dan bukan dummy Zahra', (tester) async {
      const unnamedUser = UserModel(
        id: 'usr_audit_empty',
        name: '',
        email: 'empty@example.com',
        username: 'emptyuser',
        role: UserRole.user,
      );

      await AuthService().updateUserProfile(
        userId: unnamedUser.id,
        name: '',
      );

      final testData = SkriningData(
        gender: 'Perempuan',
        age: 20,
        height: 160,
        weight: 55,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testData, user: unnamedUser),
        ),
      );
      await tester.pumpAndSettle();

      // Menampilkan fallback wajar 'Pengguna ObeSight' dan bukan dummy 'Zahra Fitriana'
      expect(find.text('Pengguna ObeSight'), findsOneWidget);
      expect(find.text('Zahra Fitriana'), findsNothing);
    });

    testWidgets('4. Data satu pengguna tidak tercampur dengan pengguna lain', (tester) async {
      await AuthService().updateUserProfile(
        userId: 'user_A',
        name: 'Pengguna Alpha',
      );
      await AuthService().updateUserProfile(
        userId: 'user_B',
        name: 'Pengguna Beta',
      );

      const userA = UserModel(
        id: 'user_A',
        name: 'Pengguna Alpha',
        email: 'a@mail.com',
        username: 'a',
        role: UserRole.user,
      );
      const userB = UserModel(
        id: 'user_B',
        name: 'Pengguna Beta',
        email: 'b@mail.com',
        username: 'b',
        role: UserRole.user,
      );

      final testData = SkriningData(height: 160, weight: 50);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testData, user: userA),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengguna Alpha'), findsOneWidget);
      expect(find.text('Pengguna Beta'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testData, user: userB),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengguna Beta'), findsOneWidget);
      expect(find.text('Pengguna Alpha'), findsNothing);
    });
  });

  group('B. Audit Penghapusan 2 Bagian UI Hasil Skrining', () {
    testWidgets('5. UI keyakinan AI dan penyelarasan Kemenkes tidak tampil di widget tree', (tester) async {
      const user = UserModel(
        id: 'usr_ui_audit',
        name: 'Test UI Audit',
        email: 'test@ui.com',
        username: 'testui',
        role: UserRole.user,
      );

      final testDataWithAi = SkriningData(
        gender: 'Perempuan',
        age: 23,
        height: 165,
        weight: 72,
        aiConfidence: 89.5,
        isClinicallyAdjusted: true,
        clinicalAdjustmentReason: 'Penyesuaian batas KMK No 509',
        isPredictionSuccess: true,
        aiCategoryTitle: 'Overweight\nLevel I',
        aiCategoryBadge: 'Berat badan sedikit diatas rentang ideal',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SkriningResultScreen(data: testDataWithAi, user: user),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kedua teks yang dihapus benar-benar TIDAK muncul
      expect(find.textContaining('AI Random Forest • Keyakinan'), findsNothing);
      expect(find.text('Diselaraskan dengan ambang batas IMT Kemenkes'), findsNothing);

      // Namun data utama dan kategori tetap tampil sempurna
      expect(find.text('Hasil Skrining'), findsOneWidget);
      expect(find.text('Test UI Audit'), findsOneWidget);
      expect(find.text('Overweight\nLevel I'), findsOneWidget);
      expect(find.text('Berat badan sedikit diatas rentang ideal'), findsOneWidget);
    });
  });

  group('C. Audit Random Forest Service & Model Integrity', () {
    test('6. RandomForestService memuat dan mengevaluasi pohon keputusan dengan benar', () async {
      final mockModelJson = jsonEncode({
        'classes': ['Normal_Weight', 'Overweight_Level_I'],
        'trees': [
          {
            'left': [-1],
            'right': [-1],
            'feature': [-1],
            'threshold': [0.0],
            'values': [0], // indeks 0 merujuk ke kelas Normal_Weight
          }
        ]
      });

      final rf = RandomForestService.instance;
      rf.loadModelFromString(mockModelJson);
      expect(rf.isLoaded, isTrue);

      final dummyData = SkriningData(
        gender: 'Perempuan',
        age: 23,
        height: 165,
        weight: 55,
      );

      final prediction = await rf.predict(dummyData);
      expect(prediction.rawClass, equals('Normal_Weight'));
      expect(prediction.confidence, greaterThan(0));
    });
  });

  group('D. Audit Persistensi Sesi & Foto Profil', () {
    test('7. Pembaruan nama profil tidak menghapus photoPath dan avatar', () async {
      await AuthService().updateUserProfile(
        userId: 'usr_photo_test',
        name: 'Foto Tester',
        photoPath: '/storage/emulated/0/photo.jpg',
        avatar: 'custom',
      );

      var profile = AuthService().getUserProfile('usr_photo_test');
      expect(profile['photo_path'], equals('/storage/emulated/0/photo.jpg'));
      expect(profile['avatar'], equals('custom'));

      // Ubah hanya nama
      await AuthService().updateUserProfile(
        userId: 'usr_photo_test',
        name: 'Nama Diperbarui',
      );

      profile = AuthService().getUserProfile('usr_photo_test');
      expect(profile['name'], equals('Nama Diperbarui'));
      // Foto harus tetap ada dan tidak terhapus
      expect(profile['photo_path'], equals('/storage/emulated/0/photo.jpg'));
      expect(profile['avatar'], equals('custom'));
    });
  });
}
