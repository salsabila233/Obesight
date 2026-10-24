import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/admin/admin_user_list_screen.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserModel TM 10 Unit Tests', () {
    test(
      'UserModel properly parses and formats createdAt, joined, and age',
      () {
        final user = UserModel(
          id: 'usr_test_1',
          name: 'Siti Rahma',
          email: 'siti@example.com',
          username: 'sitirahma',
          role: UserRole.user,
          dob: '15 Juli 2002',
          gender: 'Perempuan',
          phone: '081234567890',
          createdAt: DateTime(2025, 3, 10, 14, 30),
        );

        expect(user.id, 'usr_test_1');
        expect(user.isAdmin, false);
        expect(user.joinedFormatted, '10 Maret 2025');
        expect(user.age, isNotNull);
        expect(user.age! > 0, true);
        expect(user.genderAndAgeFormatted, contains('Perempuan'));
        expect(user.genderAndAgeFormatted, contains('tahun'));
      },
    );

    test('UserModel.fromMap parses diverse map structures correctly', () {
      final map = {
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'phone': '08987654321',
        'gender': 'Laki-laki',
        'dob': '2000-05-20',
        'role': 'user',
        'joined': 'Bergabung sejak 2024',
        'isBiodataComplete': true,
        'bmiScore': 24.5,
        'bmiCategory': 'Overweight',
        'obesityRisk': 'Sedang',
      };

      final user = UserModel.fromMap(map, 'doc_budi_123');
      expect(user.id, 'doc_budi_123');
      expect(user.name, 'Budi Santoso');
      expect(user.joinedFormatted, 'Bergabung sejak 2024');
      expect(user.genderAndAgeFormatted, contains('Laki-laki'));
      expect(user.isBiodataComplete, true);
    });
  });

  group('Admin User List & Screening Detail Widget Tests', () {
    testWidgets(
      '1. AdminUserListScreen renders AppBar with Sage Green #529471 and search bar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminUserListScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.widgetWithText(AppBar, 'Pengguna'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Cari'), findsOneWidget);
      },
    );

    testWidgets(
      '2. AdminUserScreeningDetailScreen renders header, BMI gauge, and information cards',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dummyUser = UserModel(
          id: 'test_user_uid_456',
          name: 'Aisyah Putri',
          email: 'aisyah@example.com',
          username: 'aisyahputri',
          role: UserRole.user,
          dob: '12 Januari 2001',
          gender: 'Perempuan',
          phone: '085211223344',
          joined: 'Bergabung sejak 2025',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AdminUserScreeningDetailScreen(
              userId: dummyUser.id,
              initialUser: dummyUser,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Header verification
        expect(find.text('Detail Profil Skrining'), findsOneWidget);
        expect(find.text('Aisyah Putri'), findsAtLeastNWidgets(1));
        expect(find.text('aisyah@example.com'), findsAtLeastNWidgets(1));
        expect(find.text('085211223344'), findsAtLeastNWidgets(1));

        // Section titles
        expect(find.text('Hasil Skrining Terakhir'), findsOneWidget);
        expect(find.text('Informasi Pribadi'), findsOneWidget);
        expect(find.text('Riwayat Singkat'), findsOneWidget);
        expect(find.text('Tanggal Lahir'), findsOneWidget);
        expect(find.text('Jenis Kelamin'), findsOneWidget);
      },
    );

    testWidgets(
      '3. AdminHomeScreen Total Pengguna card navigates to AdminUserListScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final adminUser = UserModel(
          id: 'adm_01',
          name: 'Admin Obesight',
          email: 'admin@obesight.com',
          username: 'admin',
          role: UserRole.admin,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AdminHomeScreen(user: adminUser),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Total Pengguna'), findsOneWidget);

        // Tap Total Pengguna Card
        await tester.tap(find.text('Total Pengguna'));
        await tester.pumpAndSettle();

        // Should now be on AdminUserListScreen
        expect(find.text('Cari'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        // Returned back to Beranda Admin
        expect(find.text('Selamat datang, Admin! 👋'), findsOneWidget);
      },
    );
  });
}
