import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javerage_timer/core/app/timer_app.dart';

void main() {
  testWidgets('Timer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TimerApp());

    // Verify that the app bar title is 'Timer'.
    expect(find.text('Timer'), findsOneWidget);

    // Verify that the initial time is displayed.
    expect(find.text('01:00'), findsOneWidget);

    // Verify that the action buttons are displayed.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.replay), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}