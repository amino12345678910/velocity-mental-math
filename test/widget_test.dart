// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:velocity_math/main.dart';
import 'package:velocity_math/screens/login_screen.dart';

void main() {
  setUp(() {
     GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App starts and shows Home Screen', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VelocityMathApp());
    await tester.pumpAndSettle();

    // Verify that we are on the LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    
    // Check for LOGIN button text
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
