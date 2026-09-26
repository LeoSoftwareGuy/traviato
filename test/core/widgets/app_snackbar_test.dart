import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/core/theme/app_motion.dart';
import 'package:traviato/core/widgets/app_snackbar.dart';
import 'package:traviato/core/widgets/show_failure_snackbar.dart';

const _almost = Duration(milliseconds: 100);

/// Pumps a screen with a button that runs [show], taps it, and lets the
/// snackbar finish animating in.
Future<void> _showFrom(
  WidgetTester tester,
  void Function(BuildContext context) show, {
  bool screenReader = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(accessibleNavigation: screenReader),
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => show(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

/// Still showing just before [duration], gone once it has elapsed.
Future<void> _expectDismissedAfter(
  WidgetTester tester,
  String message,
  Duration duration,
) async {
  expect(find.text(message), findsOneWidget);
  await tester.pump(duration - _almost);
  expect(find.text(message), findsOneWidget, reason: 'too early to dismiss');
  await tester.pump(_almost * 2);
  await tester.pumpAndSettle();
  expect(find.text(message), findsNothing, reason: 'should have dismissed');
}

void main() {
  testWidgets('info messages dismiss after the info duration', (
    tester,
  ) async {
    await _showFrom(tester, (c) => showAppSnackbar(c, 'Saved'));
    await _expectDismissedAfter(
      tester,
      'Saved',
      AppMotion.snackbarInfoDuration,
    );
  });

  testWidgets('errors dismiss after the error duration', (tester) async {
    await _showFrom(
      tester,
      (c) => showAppSnackbar(c, 'Oops', kind: AppSnackbarKind.error),
    );
    await _expectDismissedAfter(
      tester,
      'Oops',
      AppMotion.snackbarErrorDuration,
    );
  });

  testWidgets('a message with an action still auto-dismisses', (
    tester,
  ) async {
    await _showFrom(
      tester,
      (c) => showAppSnackbar(
        c,
        'Limit reached',
        kind: AppSnackbarKind.error,
        actionLabel: 'Upgrade',
        onAction: () {},
      ),
    );
    await _expectDismissedAfter(
      tester,
      'Limit reached',
      AppMotion.snackbarActionDuration,
    );
  });

  testWidgets('an action message stays up while a screen reader is on', (
    tester,
  ) async {
    await _showFrom(
      tester,
      (c) => showAppSnackbar(
        c,
        'Limit reached',
        actionLabel: 'Upgrade',
        onAction: () {},
      ),
      screenReader: true,
    );
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Limit reached'), findsOneWidget);
  });

  testWidgets('a new message replaces the current one', (tester) async {
    await _showFrom(tester, (c) {
      showAppSnackbar(c, 'First');
      showAppSnackbar(c, 'Second');
    });
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets(
    'the free-plan photo limit Upgrade snackbar no longer sticks (#153)',
    (tester) async {
      await _showFrom(
        tester,
        (c) => showFailureSnackbar(
          c,
          PresentationFailureException(const PhotoLimitFailure()),
        ),
      );
      final message = const PhotoLimitFailure().message;
      expect(find.text('Upgrade'), findsOneWidget);
      await _expectDismissedAfter(
        tester,
        message,
        AppMotion.snackbarActionDuration,
      );
    },
  );
}
