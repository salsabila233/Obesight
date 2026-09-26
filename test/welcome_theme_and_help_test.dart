import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/auth/welcome_screen.dart';
import 'package:obesight/screens/settings/help_center_screen.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:obesight/widgets/animated_illustration.dart';
import 'package:obesight/widgets/antigravity_floating.dart';

void main() {
  group('1. Tampilan Awal / Welcome Screen Tests', () {
    testWidgets('WelcomeScreen renders floating logo and illustration_woman_original.png without container box',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WelcomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Logo renders inside AntigravityFloating
      expect(find.byType(AntigravityFloating), findsWidgets);
      expect(find.text('ObeSight'), findsOneWidget);

      // Verify illustration renders with illustration_woman_original.png
      final imageFinders = find.byType(Image);
      expect(imageFinders, findsWidgets);

      bool foundOriginalIllustration = false;
      for (final element in tester.elementList(imageFinders)) {
        final imageWidget = element.widget as Image;
        if (imageWidget.image is AssetImage) {
          final assetImage = imageWidget.image as AssetImage;
          if (assetImage.assetName == 'assets/illustration_woman_original.png') {
            foundOriginalIllustration = true;
          }
        }
      }
      expect(foundOriginalIllustration, isTrue);

      // Buttons render
      expect(find.text('Daftar'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Masuk'),
        ),
        findsOneWidget,
      );
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    });

    testWidgets('AnimatedIllustration does not render boxy background container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedIllustration(maxHeight: 200),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Image is illustration_woman_original.png
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect((imageWidget.image as AssetImage).assetName, 'assets/illustration_woman_original.png');
    });
  });

  group('2. Mode Gelap (Dark Mode) Global Tests', () {
    test('AppTheme.themeModeNotifier toggles theme globally', () {
      // Set to light
      AppTheme.setThemeMode(ThemeMode.light);
      expect(AppTheme.currentThemeMode, ThemeMode.light);
      expect(AppTheme.isDark, isFalse);

      // Toggle to dark
      AppTheme.toggleDarkMode(true);
      expect(AppTheme.currentThemeMode, ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);

      // Verify darkTheme definition
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, const Color(0xFF0F172A));
      expect(dark.cardColor, const Color(0xFF1E293B));

      // Reset to light for following tests
      AppTheme.setThemeMode(ThemeMode.light);
    });
  });

  group('3. Pusat Bantuan (Help Center) Contact Integration Tests', () {
    testWidgets('HelpCenterScreen renders official email and WhatsApp contacts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HelpCenterScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify official email is displayed
      expect(find.text('adminobesight@gmail.com'), findsOneWidget);

      // Verify WhatsApp phone number is displayed
      expect(find.text('+62 856-0277-8748'), findsOneWidget);

      // Verify official website is displayed
      expect(find.text('www.obesight.com'), findsOneWidget);
    });
  });
}
