import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/presentation/widgets/move_photo_day_sheet.dart';
import 'package:traviato/l10n/app_localizations.dart';

Future<bool?> _ask(
  WidgetTester tester, {
  required int count,
  String? tap,
}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async => result = await MovePhotoDaySheet.ask(
              context,
              count: count,
              takenOn: DateTime(2026, 4, 12),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (tap != null) {
    await tester.tap(find.byKey(Key(tap)));
    await tester.pumpAndSettle();
  }
  return result;
}

void main() {
  testWidgets('one photo: names the day it was taken; Move moves', (
    tester,
  ) async {
    await _ask(tester, count: 1);
    expect(find.text('This photo was taken on Sun 12 Apr'), findsOneWidget);
    expect(find.text('Add it to Sun 12 Apr instead?'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Keep here'), findsOneWidget);
  });

  testWidgets('Move is true, Keep here false', (tester) async {
    expect(await _ask(tester, count: 1, tap: 'move-photo-move'), isTrue);
    expect(await _ask(tester, count: 1, tap: 'move-photo-keep'), isFalse);
  });

  testWidgets('a batch asks once for all of them', (tester) async {
    await _ask(tester, count: 3);
    expect(find.text('3 photos were taken on other days'), findsOneWidget);
    expect(
      find.text('Add them to the days they were taken instead?'),
      findsOneWidget,
    );
  });
}
