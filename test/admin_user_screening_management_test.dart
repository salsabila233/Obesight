import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/admin/admin_user_list_screen.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/admin_user_service.dart';
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

    testWidgets(
      '4. AdminUserListScreen renders AdminCapsuleBottomNav with identical design to Beranda Admin',
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

        // Verifikasi keberadaan kelima menu navbar
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Pengguna'), findsAtLeastNWidgets(1));
        expect(find.text('Artikel'), findsOneWidget);
        expect(find.text('Laporan'), findsOneWidget);
        expect(find.text('Pengaturan'), findsOneWidget);

        // Verifikasi ikon navbar
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
        expect(find.byIcon(Icons.article_outlined), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      },
    );

    testWidgets(
      '5. AdminUserListScreen displays all users globally (including 6 admins & regular users) without filtering by logged in admin',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Siapkan 6 akun admin dan beberapa akun pengguna umum
        final testUsers = [
          UserModel(
            id: 'admin_1',
            name: 'Admin Utama Satu',
            email: 'admin1@obesight.com',
            username: 'admin1',
            role: UserRole.admin,
            phone: '081111111111',
            createdAt: DateTime(2026, 1, 1),
          ),
          UserModel(
            id: 'admin_2',
            name: 'Admin Utama Dua',
            email: 'admin2@obesight.com',
            username: 'admin2',
            role: UserRole.admin,
            phone: '082222222222',
            createdAt: DateTime(2026, 1, 2),
          ),
          UserModel(
            id: 'admin_3',
            name: 'Admin Utama Tiga',
            email: 'admin3@obesight.com',
            username: 'admin3',
            role: UserRole.admin,
            createdAt: DateTime(2026, 1, 3),
          ),
          UserModel(
            id: 'admin_4',
            name: 'Admin Utama Empat',
            email: 'admin4@obesight.com',
            username: 'admin4',
            role: UserRole.admin,
            createdAt: DateTime(2026, 1, 4),
          ),
          UserModel(
            id: 'admin_5',
            name: 'Admin Utama Lima',
            email: 'admin5@obesight.com',
            username: 'admin5',
            role: UserRole.admin,
            createdAt: DateTime(2026, 1, 5),
          ),
          UserModel(
            id: 'admin_6',
            name: 'Admin Utama Enam',
            email: 'admin6@obesight.com',
            username: 'admin6',
            role: UserRole.admin,
            createdAt: DateTime(2026, 1, 6),
          ),
          UserModel(
            id: 'user_regular_1',
            name: 'Siti Rahmawati',
            email: 'siti.rahmawati@gmail.com',
            username: 'sitirahma',
            role: UserRole.user,
            phone: '081234567890',
            createdAt: DateTime(2026, 2, 1),
          ),
          UserModel(
            id: 'user_regular_2',
            name: 'Budi Hartono',
            email: 'budi.hartono@gmail.com',
            username: 'budihartono',
            role: UserRole.user,
            phone: '089876543210',
            createdAt: DateTime(2026, 2, 2),
          ),
        ];

        // Set mock users di service
        final service = AdminUserService.instance;
        service.setMockUsers(testUsers);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminUserListScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Pastikan akun admin dan pengguna reguler muncul tanpa filter
        expect(find.text('Admin Utama Satu'), findsOneWidget);
        expect(find.text('Admin Utama Dua'), findsOneWidget);
        expect(find.text('Admin'), findsAtLeastNWidgets(2));

        // Scroll untuk melihat pengguna reguler di bawah
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(find.text('Budi Hartono'), findsOneWidget);

        // Uji pencarian pengguna
        await tester.enterText(find.byType(TextField), 'Budi');
        await tester.pumpAndSettle();

        expect(find.text('Budi Hartono'), findsOneWidget);
        expect(find.text('Admin Utama Satu'), findsNothing);

        // Bersihkan pencarian
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Admin Utama Satu'), findsOneWidget);
      },
    );

    testWidgets(
      '6. AdminUserListScreen bottom nav navigates correctly with onTabSelected callback',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int selectedIndex = -1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AdminUserListScreen(
              onTabSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Beranda
        await tester.tap(find.text('Beranda'));
        await tester.pumpAndSettle();
        expect(selectedIndex, 0);

        // Tap Artikel
        await tester.tap(find.text('Artikel'));
        await tester.pumpAndSettle();
        expect(selectedIndex, 2);

        // Tap Laporan
        await tester.tap(find.text('Laporan'));
        await tester.pumpAndSettle();
        expect(selectedIndex, 3);

        // Tap Pengaturan
        await tester.tap(find.text('Pengaturan'));
        await tester.pumpAndSettle();
        expect(selectedIndex, 4);
      },
    );
  });
}
