import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/services/admin_user_service.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dokter Hendra Account Isolated Deletion & Management Tests', () {
    test('1. AdminUserService filters out Hendra accounts and keeps legitimate users intact', () async {
      final service = AdminUserService.instance;

      final sampleUsers = <UserModel>[
        UserModel(
          id: 'user_1',
          name: 'Zahra Fitriana',
          username: 'zahra',
          email: 'zahra@example.com',
          role: UserRole.user,
        ),
        UserModel(
          id: 'user_hendra',
          name: 'Dr. Hendra Wijaya, Sp.GK',
          username: 'hendra',
          email: 'hendra@example.com',
          role: UserRole.user,
        ),
        UserModel(
          id: 'user_2',
          name: 'Budi Santoso',
          username: 'budi',
          email: 'budi@example.com',
          role: UserRole.user,
        ),
      ];

      service.setMockUsers(sampleUsers);

      final fetched = await service.fetchUsers();
      // Only legitimate users should be present; Hendra must be filtered out
      expect(fetched.any((u) => u.name.toLowerCase().contains('hendra')), isFalse);
      expect(fetched.any((u) => u.id == 'user_1'), isTrue);
      expect(fetched.any((u) => u.id == 'user_2'), isTrue);
    });

    test('2. AdminUserService.deleteUserAccount deletes target user strictly without affecting others', () async {
      final service = AdminUserService.instance;

      final sampleUsers = <UserModel>[
        UserModel(
          id: 'user_alpha',
          name: 'Pasien Alpha',
          username: 'alpha',
          email: 'alpha@example.com',
          role: UserRole.user,
        ),
        UserModel(
          id: 'user_target',
          name: 'Dokter Hendra',
          username: 'hendra_user',
          email: 'hendra_duplicate@example.com',
          role: UserRole.user,
        ),
        UserModel(
          id: 'user_beta',
          name: 'Pasien Beta',
          username: 'beta',
          email: 'beta@example.com',
          role: UserRole.user,
        ),
      ];

      service.setMockUsers(sampleUsers);

      final success = await service.deleteUserAccount('user_target');
      expect(success, isTrue);

      final remaining = await service.fetchUsers();
      // Target deleted
      expect(remaining.any((u) => u.id == 'user_target'), isFalse);
      // Other users remain intact!
      expect(remaining.any((u) => u.id == 'user_alpha'), isTrue);
      expect(remaining.any((u) => u.id == 'user_beta'), isTrue);
      expect(remaining.length, 2);
    });

    test('3. AuthService.defaultAdminName is Admin ObeSight, not Dokter Hendra', () {
      expect(AuthService.defaultAdminName, 'Admin ObeSight');
      expect(AuthService.defaultAdminName.toLowerCase().contains('hendra'), isFalse);
    });

    testWidgets('4. AdminUserScreeningDetailScreen has Delete User action in AppBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final targetUser = UserModel(
        id: 'user_delete_test',
        name: 'Pengguna Uji Hapus',
        username: 'uji_hapus',
        email: 'uji_hapus@example.com',
        role: UserRole.user,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminUserScreeningDetailScreen(
            userId: targetUser.id,
            initialUser: targetUser,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Delete icon is present
      final deleteBtn = find.byTooltip('Hapus Akun Pengguna');
      expect(deleteBtn, findsOneWidget);

      // Tap delete icon to open confirmation dialog
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify dialog appears with warning and user name
      expect(find.text('Hapus Akun Pengguna?'), findsOneWidget);
      expect(find.textContaining('Apakah Anda yakin ingin menghapus akun "Pengguna Uji Hapus"'), findsOneWidget);
      expect(find.text('Hapus Akun'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tap 'Batal' to dismiss dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Akun Pengguna?'), findsNothing);
    });

    test('5. AdminUserService excludes adminobesight@gmail.com and admin accounts from user list', () async {
      final service = AdminUserService.instance;

      final sampleUsers = <UserModel>[
        UserModel(
          id: 'user_regular',
          name: 'Pasien Zahra',
          username: 'zahra',
          email: 'zahra@example.com',
          role: UserRole.user,
        ),
        UserModel(
          id: 'admin_account',
          name: 'Admin ObeSight',
          username: 'admin',
          email: 'adminobesight@gmail.com',
          role: UserRole.admin,
        ),
      ];

      service.setMockUsers(sampleUsers);

      final fetched = await service.fetchUsers();
      // Admin account must NOT appear in the user list
      expect(fetched.any((u) => u.email.toLowerCase() == 'adminobesight@gmail.com'), isFalse);
      expect(fetched.any((u) => u.isAdmin || u.role == UserRole.admin), isFalse);
      expect(fetched.any((u) => u.id == 'user_regular'), isTrue);
      expect(fetched.length, 1);
    });
  });
}
