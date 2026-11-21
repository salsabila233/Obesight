import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/admin/admin_user_screening_detail_screen.dart';
import 'package:obesight/screens/profile/profile_screen.dart';
import 'package:obesight/services/admin_user_service.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/services/wilayah_service.dart';
import 'package:obesight/widgets/wilayah_dropdown_section.dart';

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

  group('1. WilayahService - Official Kemendagri Indonesian Region Dataset', () {
    test('Loads complete official provinces list (38 provinces)', () async {
      final service = WilayahService.instance;
      final provinces = await service.getProvinces();

      expect(provinces.length, greaterThanOrEqualTo(38));

      // Check key provinces (Java, Sumatera, Papua DOBs)
      final names = provinces.map((p) => p.name).toList();
      expect(names, contains('Jawa Timur'));
      expect(names, contains('DKI Jakarta'));
      expect(names, contains('Jawa Barat'));
      expect(names, contains('Bali'));
      expect(names, contains('Papua Barat Daya')); // New DOB 2022
    });

    test('Loads regencies for a specific province (Jawa Timur -> Jember, Surabaya)', () async {
      final service = WilayahService.instance;
      final prov = await service.findProvince(name: 'Jawa Timur');
      expect(prov, isNotNull);

      final regencies = await service.getRegencies(prov!.id);
      expect(regencies.isNotEmpty, isTrue);

      final regNames = regencies.map((r) => r.name).toList();
      expect(regNames.any((n) => n.toUpperCase().contains('JEMBER')), isTrue);
      expect(regNames.any((n) => n.toUpperCase().contains('SURABAYA')), isTrue);
    });

    test('Loads districts for a specific regency (Jember -> Sumbersari, Kaliwates, Patrang)', () async {
      final service = WilayahService.instance;
      final prov = await service.findProvince(name: 'Jawa Timur');
      expect(prov, isNotNull);

      final reg = await service.findRegency(prov!.id, name: 'Jember');
      expect(reg, isNotNull);

      final districts = await service.getDistricts(reg!.id);
      expect(districts.isNotEmpty, isTrue);

      final distNames = districts.map((d) => d.name).toList();
      expect(distNames.any((n) => n.toUpperCase().contains('SUMBERSARI')), isTrue);
      expect(distNames.any((n) => n.toUpperCase().contains('KALIWATES')), isTrue);
      expect(distNames.any((n) => n.toUpperCase().contains('PATRANG')), isTrue);
    });
  });

  group('2. UserModel - Structured Address & Backward Compatibility', () {
    test('Parses structured wilayah fields from Map', () {
      final map = {
        'id': 'user_201',
        'name': 'Ahmad Fauzi',
        'email': 'ahmad@example.com',
        'username': 'ahmadfauzi',
        'provinsi': 'JAWA TIMUR',
        'provinsiId': '35',
        'kabupatenKota': 'KABUPATEN JEMBER',
        'kabupatenKotaId': '35.09',
        'kecamatan': 'SUMBERSARI',
        'kecamatanId': '35.09.19',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_201');
      expect(user.provinsi, 'JAWA TIMUR');
      expect(user.provinsiId, '35');
      expect(user.kabupatenKota, 'KABUPATEN JEMBER');
      expect(user.kabupatenKotaId, '35.09');
      expect(user.kecamatan, 'SUMBERSARI');
      expect(user.kecamatanId, '35.09.19');
      expect(user.hasStructuredAddress, isTrue);
      expect(user.formattedAddress, 'Kec. SUMBERSARI, KABUPATEN JEMBER, JAWA TIMUR');
      expect(user.addressDisplay, 'Kec. SUMBERSARI, KABUPATEN JEMBER, JAWA TIMUR');
    });

    test('Generates structured addressRows for profile & admin views', () {
      final map = {
        'id': 'user_202',
        'name': 'Rina Safitri',
        'email': 'rina@example.com',
        'username': 'rinasafitri',
        'provinsi': 'JAWA BARAT',
        'kabupatenKota': 'KOTA BANDUNG',
        'kecamatan': 'COBLONG',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_202');
      final rows = user.addressRows;
      expect(rows.length, 3);
      expect(rows[0]['label'], 'Provinsi');
      expect(rows[0]['value'], 'JAWA BARAT');
      expect(rows[1]['label'], 'Kabupaten/Kota');
      expect(rows[1]['value'], 'KOTA BANDUNG');
      expect(rows[2]['label'], 'Kecamatan');
      expect(rows[2]['value'], 'COBLONG');
    });

    test('Fallback to "Alamat belum diisi" when address is empty', () {
      final map = {
        'id': 'user_203',
        'name': 'User Tanpa Alamat',
        'email': 'empty@example.com',
        'username': 'emptyuser',
        'role': 'user',
      };

      final user = UserModel.fromMap(map, 'user_203');
      expect(user.hasStructuredAddress, isFalse);
      expect(user.addressDisplay, 'Alamat belum diisi');
      expect(user.addressRows.first['value'], 'Alamat belum diisi');
    });

    test('toMap saves all 6 wilayah fields plus backward-compatible alamat & address', () {
      const user = UserModel(
        id: 'user_204',
        name: 'Bambang',
        email: 'bambang@example.com',
        username: 'bambang',
        provinsi: 'DKI JAKARTA',
        provinsiId: '31',
        kabupatenKota: 'KOTA JAKARTA SELATAN',
        kabupatenKotaId: '31.74',
        kecamatan: 'TEBET',
        kecamatanId: '31.74.01',
        role: UserRole.user,
      );

      final map = user.toMap();
      expect(map['provinsi'], 'DKI JAKARTA');
      expect(map['provinsiId'], '31');
      expect(map['kabupatenKota'], 'KOTA JAKARTA SELATAN');
      expect(map['kabupatenKotaId'], '31.74');
      expect(map['kecamatan'], 'TEBET');
      expect(map['kecamatanId'], '31.74.01');
      expect(map['alamat'], 'Kec. TEBET, KOTA JAKARTA SELATAN, DKI JAKARTA');
      expect(map['address'], 'Kec. TEBET, KOTA JAKARTA SELATAN, DKI JAKARTA');
    });
  });

  group('3. WilayahDropdownSection Widget - Cascading and Auto-clearing', () {
    testWidgets('Renders all 3 dropdowns and cascading auto-clears on parent change',
        (tester) async {
      setPhoneViewport(tester);

      WilayahSelection? capturedSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: WilayahDropdownSection(
                  isDark: false,
                  isRequired: true,
                  onChanged: (sel) {
                    capturedSelection = sel;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all 3 labels are present
      expect(find.text('Provinsi'), findsOneWidget);
      expect(find.text('Kabupaten/Kota'), findsOneWidget);
      expect(find.text('Kecamatan'), findsOneWidget);

      // Check dropdown keys
      final provFinder = find.byKey(const ValueKey('dropdown_provinsi'));
      final regFinder = find.byKey(const ValueKey('dropdown_kabupaten_kota'));
      final distFinder = find.byKey(const ValueKey('dropdown_kecamatan'));

      expect(provFinder, findsOneWidget);
      expect(regFinder, findsOneWidget);
      expect(distFinder, findsOneWidget);

      // Initially regency and district are disabled
      expect(find.text('Pilih provinsi terlebih dahulu'), findsOneWidget);
      expect(find.text('Pilih kabupaten/kota terlebih dahulu'), findsOneWidget);

      // Select Province: tap dropdown
      await tester.tap(provFinder);
      await tester.pumpAndSettle();

      // Tap 'Bali' in menu (top of list)
      final baliItem = find.text('Bali').last;
      await tester.tap(baliItem);
      await tester.pumpAndSettle();

      expect(capturedSelection?.provinsiName, 'Bali');
      expect(capturedSelection?.kabupatenKota, isNull);
      expect(capturedSelection?.kecamatan, isNull);

      // Now Regency dropdown is enabled and shows 'Pilih Kabupaten/Kota'
      expect(find.text('Pilih Kabupaten/Kota'), findsOneWidget);

      // Open regency dropdown
      await tester.tap(regFinder);
      await tester.pumpAndSettle();

      // Find 'Kabupaten Badung'
      final badungItem = find.text('Kabupaten Badung').last;
      await tester.tap(badungItem);
      await tester.pumpAndSettle();

      expect(capturedSelection?.kabupatenKotaName, 'Kabupaten Badung');
      expect(capturedSelection?.kecamatan, isNull);

      // Now District dropdown is enabled and shows 'Pilih Kecamatan'
      expect(find.text('Pilih Kecamatan'), findsOneWidget);

      // Open district dropdown
      await tester.tap(distFinder);
      await tester.pumpAndSettle();

      // Find 'Kuta'
      final kutaItem = find.text('Kuta').last;
      await tester.tap(kutaItem);
      await tester.pumpAndSettle();

      expect(capturedSelection?.isComplete, isTrue);
      expect(capturedSelection?.kecamatanName, 'Kuta');
      expect(
        capturedSelection?.formattedAddress,
        'Kec. Kuta, Kabupaten Badung, Bali',
      );

      // CASCADING RESET TEST:
      // Change Province to 'Banten' (adjacent to Bali) -> Kabupaten/Kota and Kecamatan MUST be cleared
      await tester.tap(provFinder);
      await tester.pumpAndSettle();

      final bantenItem = find.text('Banten', skipOffstage: false).last;
      await tester.ensureVisible(bantenItem);
      await tester.pumpAndSettle();
      await tester.tap(bantenItem);
      await tester.pumpAndSettle();

      expect(capturedSelection?.provinsiName, 'Banten');
      expect(capturedSelection?.kabupatenKota, isNull);
      expect(capturedSelection?.kecamatan, isNull);
      expect(capturedSelection?.isComplete, isFalse);
    });
  });

  group('4. ProfileScreen - Structured Address Rows Display', () {
    testWidgets('Displays Provinsi, Kabupaten/Kota, and Kecamatan separately',
        (tester) async {
      setPhoneViewport(tester);

      final user = const UserModel(
        id: 'user_profile_01',
        name: 'Dewi Sartika',
        email: 'dewi@example.com',
        username: 'dewisartika',
        dob: '15 Mei 1998',
        gender: 'Perempuan',
        phone: '081234567890',
        provinsi: 'JAWA BARAT',
        kabupatenKota: 'KOTA BANDUNG',
        kecamatan: 'COBLONG',
        role: UserRole.user,
      );

      AuthService().updateUserProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        dob: user.dob,
        gender: user.gender,
        phone: user.phone,
        provinsi: user.provinsi,
        kabupatenKota: user.kabupatenKota,
        kecamatan: user.kecamatan,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(user: user),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Informasi Pribadi'), findsOneWidget);

      // Verify structured labels & values
      expect(find.text('Provinsi'), findsOneWidget);
      expect(find.text('JAWA BARAT'), findsOneWidget);

      expect(find.text('Kabupaten/Kota'), findsOneWidget);
      expect(find.text('KOTA BANDUNG'), findsOneWidget);

      expect(find.text('Kecamatan'), findsOneWidget);
      expect(find.text('COBLONG'), findsOneWidget);
    });

    testWidgets('Displays "Alamat belum diisi" when address is unset',
        (tester) async {
      setPhoneViewport(tester);

      final user = const UserModel(
        id: 'user_profile_empty',
        name: 'Budi Tanpa Alamat',
        email: 'budi_empty@example.com',
        username: 'budiempty',
        role: UserRole.user,
      );

      AuthService().updateUserProfile(
        userId: user.id,
        name: user.name,
        email: user.email,
        provinsi: null,
        kabupatenKota: null,
        kecamatan: null,
        address: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(user: user),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alamat belum diisi'), findsOneWidget);
    });
  });

  group('5. AdminUserScreeningDetailScreen - Structured Address Section', () {
    testWidgets('Displays structured address section with Provinsi, Kabupaten/Kota, and Kecamatan',
        (tester) async {
      setPhoneViewport(tester);

      final user = const UserModel(
        id: 'admin_test_user_01',
        name: 'Pasien Test Admin',
        email: 'pasien@example.com',
        username: 'pasientest',
        phone: '085233445566',
        gender: 'Laki-laki',
        dob: '10 Januari 1995',
        provinsi: 'JAWA TIMUR',
        kabupatenKota: 'KABUPATEN JEMBER',
        kecamatan: 'SUMBERSARI',
        role: UserRole.user,
      );

      AdminUserService.instance.setMockUsers([user]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: user.id,
            initialUser: user,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pasien Test Admin'), findsOneWidget);
      expect(find.text('Alamat Pengguna'), findsOneWidget);

      expect(find.text('Provinsi'), findsOneWidget);
      expect(find.text('JAWA TIMUR'), findsOneWidget);

      expect(find.text('Kabupaten/Kota'), findsOneWidget);
      expect(find.text('KABUPATEN JEMBER'), findsOneWidget);

      expect(find.text('Kecamatan'), findsOneWidget);
      expect(find.text('SUMBERSARI'), findsOneWidget);
    });

    testWidgets('Displays "Alamat belum diisi" in admin detail when user has no address',
        (tester) async {
      setPhoneViewport(tester);

      final user = const UserModel(
        id: 'admin_test_user_no_addr',
        name: 'Pasien Kosong',
        email: 'kosong@example.com',
        username: 'pasienkosong',
        role: UserRole.user,
      );

      AdminUserService.instance.setMockUsers([user]);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUserScreeningDetailScreen(
            userId: user.id,
            initialUser: user,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alamat Pengguna'), findsOneWidget);
      expect(find.text('Alamat belum diisi'), findsOneWidget);
    });
  });
}
