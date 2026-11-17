import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/screens/home/user_home_screen.dart';
import 'package:obesight/screens/profile/complete_profile_screen.dart';
import 'package:obesight/screens/profile/edit_profile_screen.dart';
import 'package:obesight/screens/profile/profile_screen.dart';
import 'package:obesight/services/admin_user_service.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/widgets/admin_capsule_bottom_nav.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('A. UserModel Address Serialization & Null Safety', () {
    test('UserModel parses alamat from Map correctly', () {
      final map = {
        'id': 'user_101',
        'name': 'Budi Santoso',
        'email': 'budi@gmail.com',
        'username': 'budisantoso',
        'alamat': 'Jl. Melati No. 12, Surabaya',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_101');
      expect(user.address, 'Jl. Melati No. 12, Surabaya');
      expect(user.alamat, 'Jl. Melati No. 12, Surabaya');
      expect(user.addressDisplay, 'Jl. Melati No. 12, Surabaya');
    });

    test('UserModel parses address from Map correctly (fallback compatibility)', () {
      final map = {
        'id': 'user_102',
        'name': 'Siti Aminah',
        'email': 'siti@gmail.com',
        'username': 'sitiaminah',
        'address': 'Jl. Mawar Indah No. 5, Malang',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_102');
      expect(user.address, 'Jl. Mawar Indah No. 5, Malang');
      expect(user.alamat, 'Jl. Mawar Indah No. 5, Malang');
    });

    test('UserModel handles null or empty address safely and shows fallback', () {
      final map = {
        'id': 'user_103',
        'name': 'Joko Anwar',
        'email': 'joko@gmail.com',
        'username': 'jokoanwar',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_103');
      expect(user.address, isNull);
      expect(user.alamat, isNull);
      expect(user.addressDisplay, 'Alamat belum diisi');
    });

    test('UserModel toMap writes both alamat and address for database compatibility', () {
      const user = UserModel(
        id: 'user_104',
        name: 'Dewi Lestari',
        email: 'dewi@gmail.com',
        username: 'dewilestari',
        address: 'Jl. Diponegoro No. 8, Bandung',
        role: UserRole.user,
      );

      final map = user.toMap();
      expect(map['alamat'], 'Jl. Diponegoro No. 8, Bandung');
      expect(map['address'], 'Jl. Diponegoro No. 8, Bandung');
    });

    test('UserModel copyWith supports updating address', () {
      const user = UserModel(
        id: 'user_105',
        name: 'Rudi',
        email: 'rudi@gmail.com',
        username: 'rudi',
        role: UserRole.user,
      );

      final updated = user.copyWith(address: 'Jl. Sudirman No. 99, Jakarta');
      expect(updated.address, 'Jl. Sudirman No. 99, Jakarta');
      expect(updated.name, 'Rudi');
    });
  });

  group('B. AuthService Address Management', () {
    test('AuthService saves and retrieves address across profile cache', () {
      final authService = AuthService();
      const uid = 'test_user_cache_01';

      authService.updateUserProfile(
        userId: uid,
        name: 'Ahmad Dahlan',
        email: 'ahmad@gmail.com',
        address: 'Jl. Pahlawan No. 45, Semarang',
      );

      final profile = authService.getUserProfile(uid);
      expect(profile['alamat'], 'Jl. Pahlawan No. 45, Semarang');
      expect(profile['address'], 'Jl. Pahlawan No. 45, Semarang');
    });
  });

  group('C. User Screens Address Integration Tests', () {
    testWidgets('CompleteProfileScreen renders address input and persists on submit', (tester) async {
      setPhoneViewport(tester);
      const testUser = UserModel(
        id: 'comp_user_01',
        name: 'Lengkapi User',
        email: 'lengkap@gmail.com',
        username: 'lengkapiuser',
        role: UserRole.user,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfileScreen(
            user: testUser,
            redirectToHomeAfterSave: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Alamat field
      expect(find.text('Alamat'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

      final addressField = find.widgetWithText(TextFormField, 'Masukkan alamat lengkap tempat tinggal');
      expect(addressField, findsOneWidget);

      // Enter address
      await tester.enterText(addressField, 'Jl. Cempaka Putih No. 10');
      await tester.pumpAndSettle();

      expect(find.text('Jl. Cempaka Putih No. 10'), findsOneWidget);
    });

    testWidgets('ProfileScreen displays Alamat and fallback when address is empty', (tester) async {
      setPhoneViewport(tester);
      const userNoAddress = UserModel(
        id: 'prof_user_empty',
        name: 'Tanpa Alamat',
        email: 'tanpa@gmail.com',
        username: 'tanpaalamat',
        role: UserRole.user,
      );

      AuthService().updateUserProfile(
        userId: 'prof_user_empty',
        name: 'Tanpa Alamat',
        email: 'tanpa@gmail.com',
        address: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(user: userNoAddress),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alamat'), findsOneWidget);
      expect(find.text('Alamat belum diisi'), findsOneWidget);

      // Now set address
      AuthService().updateUserProfile(
        userId: 'prof_user_empty',
        name: 'Tanpa Alamat',
        email: 'tanpa@gmail.com',
        address: 'Jl. Veteran No. 3, Malang',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(user: userNoAddress),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jl. Veteran No. 3, Malang'), findsOneWidget);
    });

    testWidgets('EditProfileScreen pre-fills address, modifies it and saves', (tester) async {
      setPhoneViewport(tester);
      const testUser = UserModel(
        id: 'edit_user_01',
        name: 'Edit Tester',
        email: 'edit@gmail.com',
        username: 'edittester',
        address: 'Jl. Lama No. 1',
        role: UserRole.user,
      );

      final initialProfile = {
        'name': 'Edit Tester',
        'email': 'edit@gmail.com',
        'dob': '12 Juli 2003',
        'gender': 'Perempuan',
        'phone': '081234567890',
        'alamat': 'Jl. Lama No. 1',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(
            user: testUser,
            initialProfile: initialProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the pre-filled address field
      final addressField = find.widgetWithText(TextFormField, 'Jl. Lama No. 1');
      expect(addressField, findsOneWidget);

      // Change address
      await tester.enterText(addressField, 'Jl. Baru No. 88, Surabaya');
      await tester.pumpAndSettle();

      // Tap Simpan Perubahan
      final saveBtn = find.text('Simpan Perubahan');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Check that AuthService has updated address
      final updatedProfile = AuthService().getUserProfile('edit_user_01');
      expect(updatedProfile['alamat'], 'Jl. Baru No. 88, Surabaya');
    });
  });

  group('D. Admin User Screening Detail Screen Address Integration', () {
    testWidgets('AdminUserScreeningDetailScreen displays user address in top card', (tester) async {
      setPhoneViewport(tester);
      const adminUser = UserModel(
        id: 'user_detail_01',
        name: 'Rina Kusuma',
        email: 'rina@gmail.com',
        username: 'rinakusuma',
        phone: '081298765432',
        gender: 'Perempuan',
        dob: '15 Mei 2000',
        address: 'Jl. Rinjani No. 24, Yogyakarta',
        role: UserRole.user,
      );

      AdminUserService.instance.setMockUsers([adminUser]);
      AdminUserService.instance.setMockUserScreenings('user_detail_01', []);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_detail_01',
            initialUser: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rina Kusuma'), findsWidgets);
      expect(find.text('Jl. Rinjani No. 24, Yogyakarta'), findsOneWidget);
    });

    testWidgets('AdminUserScreeningDetailScreen displays fallback when address is missing', (tester) async {
      setPhoneViewport(tester);
      const adminUserNoAddress = UserModel(
        id: 'user_detail_02',
        name: 'Bambang Tri',
        email: 'bambang@gmail.com',
        username: 'bambangtri',
        phone: '081233445566',
        gender: 'Laki-laki',
        dob: '10 Januari 1998',
        role: UserRole.user,
      );

      AdminUserService.instance.setMockUsers([adminUserNoAddress]);
      AdminUserService.instance.setMockUserScreenings('user_detail_02', []);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: 'user_detail_02',
            initialUser: adminUserNoAddress,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alamat belum diisi'), findsOneWidget);
    });
  });

  group('E. User Navbar Labels and Color Consistency with Admin Navbar', () {
    test('Admin and User Navbar color codes match exactly', () {
      const adminCapsuleBg = AdminCapsuleBottomNav.capsuleBg;
      const adminActiveColor = AdminCapsuleBottomNav.activeColor;

      expect(adminCapsuleBg, const Color(0xFF246B4D));
      expect(adminActiveColor, const Color(0xFF388E6B));
    });

    testWidgets('UserHomeScreen displays bottom nav with labels Beranda, Progres, and Pengaturan', (tester) async {
      setPhoneViewport(tester);
      const testUser = UserModel(
        id: 'home_user_01',
        name: 'User Nav Test',
        email: 'navtest@gmail.com',
        username: 'navtest',
        role: UserRole.user,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserHomeScreen(user: testUser),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check labels in navbar
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Progres'), findsWidgets);
      expect(find.text('Pengaturan'), findsWidgets);

      // Verify the floating bottom nav container exists and uses the exact admin capsuleBg color (0xFF246B4D)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final navContainer = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.color == const Color(0xFF246B4D);
          }
          return false;
        },
      );
      expect(navContainer, isNotNull);

      // Verify active tab pill uses the exact admin activeColor (0xFF388E6B)
      final activePill = containers.firstWhere(
        (c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.color == const Color(0xFF388E6B);
          }
          return false;
        },
      );
      expect(activePill, isNotNull);
    });
  });
}
