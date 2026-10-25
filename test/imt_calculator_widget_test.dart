import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/imt_form_screen.dart';
import 'package:obesight/screens/home/imt_result_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const testUser = UserModel(
    id: 'test_user_widget_imt_001',
    name: 'Zahra Fitriana',
    email: 'zahra@example.com',
    username: 'zahra',
    role: UserRole.user,
  );

  setUp(() {
    AuthService().updateUserBmi(
      userId: testUser.id,
      bmi: 22.5,
      category: 'Normal',
      risk: 'Rendah',
      weight: 65.0,
      height: 170.0,
      gender: 'Laki-laki',
      age: 21,
    );
  });

  Widget buildTestWidget({
    double? initialWeight,
    double? initialHeight,
    int? initialAge,
    String? initialGender,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ImtFormScreen(
        user: testUser,
        initialWeight: initialWeight,
        initialHeight: initialHeight,
        initialAge: initialAge,
        initialGender: initialGender,
      ),
    );
  }

  group('Kalkulator IMT Widget Tests (Perilaku Alur dan Logika)', () {
    testWidgets('(a) Saat layar baru dibuka, tidak ada teks peringatan / error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Memastikan tidak ada teks error / validasi yang muncul di layar
      expect(find.textContaining('Harap masukkan'), findsNothing);
      expect(find.textContaining('wajib diisi'), findsNothing);
      expect(find.textContaining('tidak valid'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('(b) Setelah input valid dan tombol hitung ditekan sekali, hasil langsung tampil tanpa dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Isi input: Usia: 21 (index 0), Tinggi Badan: 170 (index 1), Berat Badan: 65 (index 2)
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '170');
      await tester.enterText(textFields.at(2), '65');
      await tester.pumpAndSettle();

      // Tekan tombol "Hitung IMT" 1 kali
      final hitungBtn = find.widgetWithText(ElevatedButton, 'Hitung IMT');
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pumpAndSettle();

      // Hasil langsung tampil di ImtResultScreen tanpa menunggu atau konfirmasi ganda
      expect(find.byType(ImtResultScreen), findsOneWidget);
      expect(find.text('22,5'), findsOneWidget);
      expect(find.text('Normal'), findsWidgets);
      expect(find.text('Risiko Obesitas: Rendah'), findsOneWidget);
      expect(find.text('65 KG'), findsOneWidget);
      expect(find.text('170 CM'), findsOneWidget);

      // Verifikasi AuthService tersinkronisasi
      final updatedBmi = AuthService().getUserBmi(testUser.id);
      expect(updatedBmi['bmi'], 22.5);
      expect(updatedBmi['category'], 'Normal');
      expect(updatedBmi['risk'], 'Rendah');
    });

    testWidgets('(c) Input tidak valid menampilkan peringatan HANYA setelah tombol ditekan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Kosongkan berat badan
      await tester.enterText(textFields.at(2), '');
      await tester.pumpAndSettle();

      // Sebelum tombol ditekan, tidak ada peringatan
      expect(find.textContaining('Harap masukkan berat badan yang valid'), findsNothing);

      // Tekan tombol hitung
      final hitungBtn = find.widgetWithText(ElevatedButton, 'Hitung IMT');
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pumpAndSettle();

      // Sekarang peringatan tampil setelah tombol ditekan
      expect(find.text('Harap masukkan berat badan yang valid (20 - 350 kg)'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      // Tidak navigasi ke hasil
      expect(find.byType(ImtResultScreen), findsNothing);

      // Perbaiki berat badan menjadi valid, tetapi kosongkan tinggi badan
      await tester.enterText(textFields.at(2), '60');
      await tester.enterText(textFields.at(1), '');
      await tester.pumpAndSettle();

      // Tekan tombol hitung lagi
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pumpAndSettle();

      // Peringatan tinggi badan tampil
      expect(find.text('Harap masukkan tinggi badan yang valid (50 - 260 cm)'), findsOneWidget);
      expect(find.byType(ImtResultScreen), findsNothing);
    });

    testWidgets('Menerima input dengan koma desimal (misal 65,5 kg dan 170,0 cm) dan menghitung dengan benar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '170,0');
      await tester.enterText(textFields.at(2), '65,5');
      await tester.pumpAndSettle();

      // Tekan tombol hitung
      final hitungBtn = find.widgetWithText(ElevatedButton, 'Hitung IMT');
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pumpAndSettle();

      // 65.5 / (1.7^2) = 22.66 -> 22,7
      expect(find.byType(ImtResultScreen), findsOneWidget);
      expect(find.text('22,7'), findsOneWidget);
      expect(find.text('Normal'), findsWidgets);
    });

    testWidgets('Menekan tombol berkali-kali secara cepat tidak membuka halaman hasil ganda', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '170');
      await tester.enterText(textFields.at(2), '65');
      await tester.pumpAndSettle();

      final hitungBtn = find.widgetWithText(ElevatedButton, 'Hitung IMT');
      await tester.ensureVisible(hitungBtn);

      // Tekan 3 kali berturut-turut tanpa menunggu pumpAndSettle
      await tester.tap(hitungBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(hitungBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(hitungBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tetap hanya 1 halaman ImtResultScreen
      expect(find.byType(ImtResultScreen), findsOneWidget);

      // Tekan back (pop) sekali harus kembali ke ImtFormScreen, bukan halaman duplikat
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ImtFormScreen), findsOneWidget);
      expect(find.byType(ImtResultScreen), findsNothing);
    });
  });
}
