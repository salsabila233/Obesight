import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/profile/edit_profile_screen.dart';
import 'package:obesight/screens/profile/profile_screen.dart';
import 'package:obesight/services/auth_service.dart';

void main() {
  testWidgets('ProfileScreen displays synchronized name, email, and joined date in month and year format', (WidgetTester tester) async {
    const testUser = UserModel(
      id: 'test_user_01',
      name: 'Aisyah Lailatul Fitri Hapsari',
      email: 'aisyah.hapsari@gmail.com',
      username: 'aisyahhapsari',
      role: UserRole.user,
    );

    AuthService().updateUserProfile(
      userId: 'test_user_01',
      name: 'Aisyah Lailatul Fitri Hapsari',
      email: 'aisyah.hapsari@gmail.com',
      joined: 'Bergabung sejak Juni 2026',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    // Verify name and email synchronization
    expect(find.text('Aisyah Lailatul Fitri Hapsari'), findsWidgets);
    expect(find.text('aisyah.hapsari@gmail.com'), findsWidgets);

    // Verify joined date format
    expect(find.text('Bergabung sejak Juni 2026'), findsOneWidget);

    // Verify Edit Profile button is present
    expect(find.text('Edit Profil'), findsOneWidget);
  });

  testWidgets('EditProfileScreen shows confirmation dialog on back when changes are made', (WidgetTester tester) async {
    const testUser = UserModel(
      id: 'test_user_02',
      name: 'Aisyah Lailatul Fitri Hapsari',
      email: 'aisyah.hapsari@gmail.com',
      username: 'aisyahhapsari',
      role: UserRole.user,
    );

    final initialProfile = {
      'name': 'Aisyah Lailatul Fitri Hapsari',
      'email': 'aisyah.hapsari@gmail.com',
      'dob': '12 Juli 2003',
      'gender': 'Perempuan',
      'phone': '089334212098',
      'joined': 'Bergabung sejak Juni 2026',
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

    // Edit the name field to trigger changes
    final nameField = find.widgetWithText(TextFormField, 'Aisyah Lailatul Fitri Hapsari');
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Aisyah Lailatul Fitri Updated');
    await tester.pumpAndSettle();

    // Tap back button in AppBar
    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog text
    expect(find.text('Batalkan perubahan pada profil Anda?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Simpan'),
      ),
      findsOneWidget,
    );
  });
}
