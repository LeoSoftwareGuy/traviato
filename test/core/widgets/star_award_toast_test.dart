import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/core/theme/app_motion.dart';
import 'package:traviato/core/widgets/star_award_toast.dart';

void main() {
  setUpAll(() {
    // Avoid GoogleFonts attempting a runtime network fetch during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget harness() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showStarToast(context, '✦ +2 stars · photo logged'),
              child: const Text('award'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the award text and auto-dismisses', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('award'));
    await tester.pump();

    expect(find.text('✦ +2 stars · photo logged'), findsOneWidget);

    await tester.pump(
      AppMotion.awardPopDuration + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    expect(find.text('✦ +2 stars · photo logged'), findsNothing);
  });

  testWidgets('a new award replaces a pending one', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('award'));
    await tester.pump();
    expect(find.text('✦ +2 stars · photo logged'), findsOneWidget);

    final context = tester.element(find.text('award'));
    showStarToast(context, '✦ Packed — nice');
    await tester.pump();

    expect(find.text('✦ +2 stars · photo logged'), findsNothing);
    expect(find.text('✦ Packed — nice'), findsOneWidget);

    // The pre-empted toast's timer must not tear down the replacement.
    await tester.pump(
      AppMotion.awardPopDuration + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();
    expect(find.text('✦ Packed — nice'), findsNothing);
  });
}
