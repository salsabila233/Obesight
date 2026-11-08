import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/settings/change_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget() {
    return const MaterialApp(home: ChangePasswordScreen());
  }

  group('ChangePasswordScreen UI and Confirmation Tests', () {
    testWidgets(
      '1. Header has lowered title "Ubah Kata Sandi" and no illustration',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Title should be present
        expect(find.text('Ubah Kata Sandi'), findsOneWidget);

        // Verify AppBar toolbarHeight is increased to lower the curved line
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight, 68.0);

        // Verify woman illustration is removed
        expect(
          find.byWidgetPredicate((w) {
            if (w is Image && w.image is AssetImage) {
              final asset = w.image as AssetImage;
              return asset.assetName.contains('illustration_woman');
            }
            return false;
          }),
          findsNothing,
        );

        // Verify Keamanan Akun heading is directly visible
        expect(find.text('Keamanan Akun'), findsOneWidget);
        expect(
          find.text(
            'Gunakan kombinasi kata sandi yang kuat untuk melindungi data kesehatan dan akun ObeSight Anda.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('2. Back confirmation dialog when there are unsaved inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter some text into new password field
      final newPasswordField = find.widgetWithText(
        TextFormField,
        'Masukkan kata sandi baru',
      );
      await tester.enterText(newPasswordField, 'Secret123');
      await tester.pump();

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(
        find.text(
          'Anda memiliki perubahan kata sandi yang belum disimpan. Apakah Anda yakin ingin keluar tanpa menyimpan perubahan?',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Tetap di Halaman'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Keluar'), findsOneWidget);

      // Tap "Tetap di Halaman": dialog dismisses, screen remains open
      await tester.tap(find.widgetWithText(OutlinedButton, 'Tetap di Halaman'));
      await tester.pumpAndSettle();
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Secret123'), findsOneWidget);

      // Tap back again, then tap "Keluar"
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
      await tester.pumpAndSettle();

      // Returns to previous screen
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets(
      '3. Save confirmation dialog appears when Simpan is pressed with valid inputs',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Fill in fields
        final oldPassField = find.widgetWithText(
          TextFormField,
          'Masukkan kata sandi lama',
        );
        final newPassField = find.widgetWithText(
          TextFormField,
          'Masukkan kata sandi baru',
        );
        final confirmPassField = find.widgetWithText(
          TextFormField,
          'Ulangi kata sandi baru',
        );

        await tester.enterText(oldPassField, 'OldPassword1');
        await tester.enterText(newPassField, 'NewPassword2');
        await tester.enterText(confirmPassField, 'NewPassword2');
        await tester.pump();

        // Tap Simpan Kata Sandi
        final simpanButton = find.widgetWithText(
          ElevatedButton,
          'Simpan Kata Sandi',
        );
        await tester.ensureVisible(simpanButton);
        await tester.tap(simpanButton);
        await tester.pumpAndSettle();

        // Save confirmation dialog must be displayed
        expect(find.text('Konfirmasi Perubahan Kata Sandi'), findsOneWidget);
        expect(
          find.text(
            'Apakah Anda yakin ingin menyimpan kata sandi baru? Setelah dikonfirmasi, kata sandi lama akan diganti dengan kata sandi baru.',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Batal'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Ya, Simpan'),
          findsOneWidget,
        );

        // Tap Batal: dialog dismisses, inputs are kept intact
        await tester.tap(find.widgetWithText(OutlinedButton, 'Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Konfirmasi Perubahan Kata Sandi'), findsNothing);
        expect(find.text('OldPassword1'), findsOneWidget);
        expect(find.text('NewPassword2'), findsNWidgets(2));
      },
    );
  });
}
