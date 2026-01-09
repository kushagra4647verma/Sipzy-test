// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:userapp/app.dart';

void main() {
  // Mock Supabase initialization for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SipZy App Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const SipZyApp());

      // Wait for initial render
      await tester.pump();

      // App should build without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Theme is applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const SipZyApp());
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });
  });
}
