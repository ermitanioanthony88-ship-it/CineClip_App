import 'package:flutter_test/flutter_test.dart';

import 'package:cineclip/main.dart';

void main() {
  testWidgets('splash screen transitions to home after five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const CineClipApp());

    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4999));
    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your next story starts here.'), findsOneWidget);
    expect(find.text('Turn Moments Into Movies'), findsNothing);
  });
}
