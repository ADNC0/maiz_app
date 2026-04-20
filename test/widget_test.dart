// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maiz_app/main.dart';

void main() {
  testWidgets('Smoke test loads login screen', (WidgetTester tester) async {
    // Build the app with a simple initial home (login should show).
    await tester.pumpWidget(
        MaizApp(initialHome: const SizedBox(), navigatorKey: navigatorKey));

    // Expect at least one TextField or button from login screen is present.
    expect(find.byType(TextField), findsOneWidget);
  });
}
