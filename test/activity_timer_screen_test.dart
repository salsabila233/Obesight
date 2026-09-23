import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';

void main() {
  testWidgets('ActivityTimerScreen displays single centered timer and presets', (WidgetTester tester) async {
    // Set standard mobile screen size for test
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final activity = {
      'id': 'jogging',
      'title': 'Jogging',
      'targetText': '30-60 menit',
      'heroImg': 'assets/progress/clean/hero_jogging.png',
      'specs': {'calories': '300 kkal'},
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ActivityTimerScreen(activity: activity),
      ),
    );
    await tester.pump();

    // Verify Target header
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('30-60 menit'), findsOneWidget);

    // Verify initial single centered timer text is '00:00'
    expect(find.text('00:00'), findsOneWidget);

    // Verify no stacked '59:59' exists
    expect(find.text('59:59'), findsNothing);

    // Verify preset options are present
    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('45:00'), findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Selesaikan Aktivitas'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Tap on preset '30:00'
    await tester.tap(find.text('30:00'));
    await tester.pump();

    // Now '30:00' should be displayed both in preset button and main timer circle
    expect(find.text('30:00'), findsNWidgets(2));

    // Tap on preset '45:00'
    await tester.tap(find.text('45:00'));
    await tester.pump();

    // Now '45:00' should be in the main circle as well
    expect(find.text('45:00'), findsNWidgets(2));
  });
}
