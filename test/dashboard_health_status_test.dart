import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/user_home_screen.dart';
import 'package:obesight/services/screening_history_service.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('1. Pengguna baru tanpa riwayat skrining melihat status belum ada data dan bukan nilai bawaan', (tester) async {
    final newUser = UserModel(
      id: 'test_user_empty',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      username: 'budisantoso',
      role: UserRole.user,
      isBiodataComplete: true,
      dob: '1995-05-15',
      gender: 'Laki-laki',
      phone: '08123456789',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UserHomeScreen(user: newUser),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verifikasi bahwa angka 19.4 atau nilai dummy TIDAK muncul
    expect(find.text('19.4'), findsNothing);
    expect(find.text('Normal Weight'), findsNothing);
    expect(find.text('Risiko Terkendali'), findsNothing);

    // Verifikasi bahwa status yang ditampilkan adalah kondisi belum ada data
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Belum ada data'), findsNWidgets(2)); // 1 untuk Kategori IMT, 1 untuk Risiko Obesitas
    expect(find.text('IMT'), findsOneWidget);
    expect(find.text('Risiko Obesitas'), findsOneWidget);
  });

  testWidgets('2. Pengguna dengan riwayat skrining menampilkan hasil skrining terakhir yang valid', (tester) async {
    final existingUser = UserModel(
      id: 'test_user_with_screening',
      name: 'Siti Aminah',
      email: 'siti@example.com',
      username: 'sitiaminah',
      role: UserRole.user,
      isBiodataComplete: true,
      dob: '1998-08-20',
      gender: 'Perempuan',
      phone: '08987654321',
    );

    // Simpan data skrining ke ScreeningHistoryService
    final skriningData = SkriningData(
      gender: 'Perempuan',
      age: 25,
      height: 160,
      weight: 60, // IMT: 60 / (1.6 * 1.6) = 23.4 (Overweight Level I)
      familyHistory: 'Ya',
      highCalorieFood: 'Ya',
      vegetableIntake: 'Kadang-kadang',
      mainMealFrequency: '3 kali sehari',
      snackFrequency: 'Sering',
      smoking: 'Tidak',
      waterIntake: '1-2 Liter',
      monitorCalories: 'Tidak',
      physicalActivity: '1-2 hari',
      screenTime: '3-5 jam',
      alcohol: 'Tidak pernah',
      transportation: 'Kendaraan bermotor pribadi',
      aiRawClass: 'Overweight_Level_I',
      aiClinicalClass: 'Overweight_Level_I',
      aiCategoryKey: 'Overweight',
      aiCategoryTitle: 'Overweight Level I',
      isPredictionSuccess: true,
    );

    await ScreeningHistoryService.instance.addHistory(
      existingUser.id,
      skriningData,
      email: existingUser.email,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UserHomeScreen(user: existingUser),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Nilai IMT harus persis dari data skrining: 23.4
    expect(find.text('23.4'), findsOneWidget);
    // Kategori IMT harus dari skrining yang sama
    expect(find.text('Overweight Level I'), findsOneWidget);
    // Risiko obesitas harus dari skrining yang sama (Risiko Meningkat)
    expect(find.text('Risiko Meningkat'), findsOneWidget);

    // Data default tidak boleh muncul
    expect(find.text('19.4'), findsNothing);
    expect(find.text('Risiko Terkendali'), findsNothing);
  });

  testWidgets('3. Melakukan skrining baru memperbarui Status Kesehatan di Dashboard secara otomatis', (tester) async {
    final activeUser = UserModel(
      id: 'test_user_dynamic',
      name: 'Rian Pratama',
      email: 'rian@example.com',
      username: 'rianpratama',
      role: UserRole.user,
      isBiodataComplete: true,
      dob: '2000-01-01',
      gender: 'Laki-laki',
      phone: '081122334455',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UserHomeScreen(user: activeUser),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Awal: Belum ada data
    expect(find.text('-'), findsOneWidget);
    expect(find.text('Belum ada data'), findsNWidgets(2));

    // Pengguna menyelesaikan skrining pertama
    final screening1 = SkriningData(
      gender: 'Laki-laki',
      age: 24,
      height: 175,
      weight: 65, // IMT: 65 / (1.75 * 1.75) = 21.2 (Normal Weight)
      familyHistory: 'Tidak',
      highCalorieFood: 'Tidak',
      vegetableIntake: 'Selalu',
      mainMealFrequency: '3 kali sehari',
      snackFrequency: 'Kadang-kadang',
      smoking: 'Tidak',
      waterIntake: '> 2 Liter',
      monitorCalories: 'Ya',
      physicalActivity: '3-4 hari',
      screenTime: '0-2 jam',
      alcohol: 'Tidak pernah',
      transportation: 'Jalan kaki',
      aiRawClass: 'Normal_Weight',
      aiClinicalClass: 'Normal_Weight',
      aiCategoryKey: 'Normal',
      aiCategoryTitle: 'Normal Weight',
      isPredictionSuccess: true,
    );

    await ScreeningHistoryService.instance.addHistory(
      activeUser.id,
      screening1,
      email: activeUser.email,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Dashboard otomatis ter-update menampilkan skrining pertama
    expect(find.text('21.2'), findsOneWidget);
    expect(find.text('Normal Weight'), findsOneWidget);
    expect(find.text('Risiko Terkendali'), findsOneWidget);

    // Pengguna melakukan skrining kedua dengan data baru
    final screening2 = SkriningData(
      gender: 'Laki-laki',
      age: 24,
      height: 175,
      weight: 73, // IMT: 73 / (1.75 * 1.75) = 23.8 (Overweight Level I)
      familyHistory: 'Ya',
      highCalorieFood: 'Ya',
      vegetableIntake: 'Jarang',
      mainMealFrequency: '3 kali sehari',
      snackFrequency: 'Sering',
      smoking: 'Tidak',
      waterIntake: '1-2 Liter',
      monitorCalories: 'Tidak',
      physicalActivity: 'Tidak pernah',
      screenTime: '3-5 jam',
      alcohol: 'Tidak pernah',
      transportation: 'Kendaraan bermotor pribadi',
      aiRawClass: 'Overweight_Level_I',
      aiClinicalClass: 'Overweight_Level_I',
      aiCategoryKey: 'Overweight',
      aiCategoryTitle: 'Overweight Level I',
      isPredictionSuccess: true,
    );

    await ScreeningHistoryService.instance.addHistory(
      activeUser.id,
      screening2,
      email: activeUser.email,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Dashboard otomatis ter-update menampilkan skrining TERBARU
    expect(find.text('23.8'), findsOneWidget);
    expect(find.text('Overweight Level I'), findsOneWidget);
    expect(find.text('Risiko Meningkat'), findsOneWidget);
    // Skrining lama tidak lagi tampil di dashboard ringkasan
    expect(find.text('21.2'), findsNothing);
  });
}
