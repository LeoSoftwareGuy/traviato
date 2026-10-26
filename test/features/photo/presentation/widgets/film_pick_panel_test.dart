import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/presentation/widgets/film_pick_panel.dart';
import 'package:traviato/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FilmPick pick,
  bool isAutoPicked = false,
  ValueChanged<FilmPick>? onChanged,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360 - 2 * 18,
            child: FilmPickPanel(
              pick: pick,
              isAutoPicked: isAutoPicked,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

String _hint(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('film-pick-hint'))).data!;

void main() {
  group('FilmPickPanel (#294)', () {
    testWidgets('shows the eyebrow and all three segments', (tester) async {
      await _pump(tester, pick: FilmPick.auto);

      expect(find.text('▸ IN THE FILM'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Always'), findsOneWidget);
      expect(find.text('Leave out'), findsOneWidget);
    });

    testWidgets('the hint follows the pick and whether the film chose it', (
      tester,
    ) async {
      await _pump(tester, pick: FilmPick.auto, isAutoPicked: true);
      expect(_hint(tester), 'Film chose this one');

      await _pump(tester, pick: FilmPick.auto);
      expect(_hint(tester), 'Not picked right now');

      await _pump(tester, pick: FilmPick.always);
      expect(_hint(tester), 'Your pick · gets a main moment');

      await _pump(tester, pick: FilmPick.never);
      expect(_hint(tester), "Won't appear anywhere");
    });

    testWidgets('tapping another segment reports it; the current one is a '
        'no-op', (tester) async {
      final changes = <FilmPick>[];
      await _pump(tester, pick: FilmPick.auto, onChanged: changes.add);

      await tester.tap(find.byKey(const Key('film-pick-never')));
      await tester.tap(find.byKey(const Key('film-pick-auto')));
      await tester.pump();

      expect(changes, [FilmPick.never]);
    });

    testWidgets('segments are at least 38 tall', (tester) async {
      await _pump(tester, pick: FilmPick.always);
      for (final pick in FilmPick.values) {
        expect(
          tester.getSize(find.byKey(Key('film-pick-${pick.name}'))).height,
          greaterThanOrEqualTo(38),
        );
      }
    });

    testWidgets('lays out without overflow in Russian at 360pt', (
      tester,
    ) async {
      await _pump(tester, pick: FilmPick.always, locale: const Locale('ru'));
      expect(tester.takeException(), isNull);
      expect(find.text('Не брать'), findsOneWidget);
    });
  });
}
