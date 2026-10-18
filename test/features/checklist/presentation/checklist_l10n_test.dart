import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';
import 'package:traviato/features/checklist/presentation/pages/checklist_page.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:traviato/features/checklist/presentation/widgets/checklist_category_label.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../helpers/localized_app.dart';
import '../fakes/fake_checklist_repository.dart';

Future<void> _pump(WidgetTester tester, Locale locale) async {
  final router = GoRouter(
    initialLocation: '/checklist',
    routes: [
      GoRoute(
        path: '/checklist',
        builder: (context, state) => const ChecklistPage(tripId: 't1'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checklistRepositoryProvider.overrideWithValue(
          FakeChecklistRepository()
            ..itemsResult = Right([
              buildChecklistItemEntity(
                id: 'i1',
                title: 'Passport',
                isEssential: true,
              ),
              buildChecklistItemEntity(
                id: 'i2',
                title: 'Charger',
                isChecked: true,
              ),
            ]),
        ),
      ],
      child: localizedRouterApp(locale: locale, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('every category has a distinct label per language', () {
    for (final locale in const ['en', 'ru', 'et']) {
      final l10n = lookupAppLocalizations(Locale(locale));
      final labels = {
        for (final c in ChecklistCategory.values)
          checklistCategoryLabel(l10n, c),
      };
      expect(labels, hasLength(ChecklistCategory.values.length));
    }
    expect(
      checklistCategoryLabel(
        lookupAppLocalizations(const Locale('en')),
        ChecklistCategory.niceToHaves,
      ),
      ChecklistCategory.niceToHaves.displayName,
    );
  });

  testWidgets('Checklist reads in Russian', (tester) async {
    await _pump(tester, const Locale('ru'));

    expect(find.text('ЧЕК-ЛИСТ'), findsOneWidget);
    expect(find.text('Соберитесь в поездку'), findsOneWidget);
    expect(find.text('Самое нужное'), findsOneWidget);
    expect(find.text('Собрано 1 из 2'), findsOneWidget);
    expect(find.text('Важное'), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);

    await tester.tap(find.text('Passport'));
    await tester.pump();
    expect(find.text('✦ Собрано — отлично'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  for (final locale in const [Locale('en'), Locale('ru'), Locale('et')]) {
    testWidgets('Checklist lays out without overflow at 360pt in '
        '${locale.languageCode}', (tester) async {
      setScreenSize(tester);
      await _pump(tester, locale);

      expect(tester.takeException(), isNull);
    });
  }
}
