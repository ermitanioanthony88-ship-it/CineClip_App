import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cineclip/main.dart';

void main() {
  testWidgets('onboarding shows once and remains complete after relaunch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CineClipApp());

    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4999));
    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your Photos,\nYour Story'), findsOneWidget);
    expect(find.text('Turn Moments Into Movies'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Make It Move'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Save and Share'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Your next story starts here.'), findsOneWidget);
    final onboardingCompleted =
        (await SharedPreferences.getInstance()).getBool(
          'onboarding_completed',
        ) ??
        false;
    expect(onboardingCompleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CineClipApp(onboardingCompleted: onboardingCompleted),
    );
    await tester.pumpAndSettle();
    expect(find.text('Turn Moments Into Movies'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Your next story starts here.'), findsOneWidget);
    expect(find.text('Your Photos,\nYour Story'), findsNothing);
  });
}
