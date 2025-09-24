// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_state_management/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyEphemeralApp());

    // Add a counter and verify it starts at 0
    await tester.tap(find.byIcon(Icons.add)); // taps the Add Counter button
    await tester.pump();

    expect(find.textContaining('Value: 0'), findsOneWidget);

    // Tap the per-tile increment button (add_circle_outline)
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    expect(find.textContaining('Value: 1'), findsOneWidget);
  });
}
