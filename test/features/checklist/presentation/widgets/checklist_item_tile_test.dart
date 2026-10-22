import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_item_entity.dart';
import 'package:traviato/features/checklist/presentation/widgets/checklist_item_tile.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_checklist_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ChecklistItemEntity item,
  required VoidCallback onToggle,
  bool isToggling = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChecklistItemTile(
          item: item,
          isToggling: isToggling,
          onToggle: onToggle,
        ),
      ),
    ),
  );
}

Future<void> _pumpIn(
  WidgetTester tester,
  Locale locale,
  ChecklistItemEntity item,
) {
  return tester.pumpWidget(
    localizedApp(
      locale: locale,
      home: Scaffold(
        body: ChecklistItemTile(
          item: item,
          isToggling: false,
          onToggle: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('title language (#285)', () {
    testWidgets('a seeded item follows the UI language, whatever language '
        'it was written in', (tester) async {
      final item = buildChecklistItemEntity(
        title: 'Паспорт',
        suggestionCode: 'passport',
      );

      await _pumpIn(tester, const Locale('en'), item);
      await tester.pumpAndSettle();
      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Паспорт'), findsNothing);

      await _pumpIn(tester, const Locale('ru'), item);
      await tester.pumpAndSettle();
      expect(find.text('Паспорт'), findsOneWidget);
    });

    testWidgets("the user's own item keeps its text", (tester) async {
      await _pumpIn(
        tester,
        const Locale('en'),
        buildChecklistItemEntity(title: 'Мой фотоаппарат'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Мой фотоаппарат'), findsOneWidget);
    });

    testWidgets('a code this build does not know falls back to the stored '
        'title', (tester) async {
      await _pumpIn(
        tester,
        const Locale('en'),
        buildChecklistItemEntity(
          title: 'Kompass',
          suggestionCode: 'compass_from_the_future',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kompass'), findsOneWidget);
    });
  });

  testWidgets('tapping the title toggles the item', (tester) async {
    var toggles = 0;
    await _pump(
      tester,
      item: buildChecklistItemEntity(title: 'Passport'),
      onToggle: () => toggles++,
    );

    await tester.tap(find.text('Passport'));

    expect(toggles, 1);
  });

  testWidgets('tapping the Essential badge toggles the item', (tester) async {
    var toggles = 0;
    await _pump(
      tester,
      item: buildChecklistItemEntity(isEssential: true),
      onToggle: () => toggles++,
    );

    await tester.tap(find.text('Essential'));

    expect(toggles, 1);
  });

  testWidgets('tapping the check circle still toggles the item', (
    tester,
  ) async {
    var toggles = 0;
    await _pump(
      tester,
      item: buildChecklistItemEntity(id: 'i1'),
      onToggle: () => toggles++,
    );

    await tester.tap(find.byKey(const Key('checklist-item-check-i1')));

    expect(toggles, 1);
  });

  testWidgets('taps are ignored while a toggle is in flight', (tester) async {
    var toggles = 0;
    await _pump(
      tester,
      item: buildChecklistItemEntity(title: 'Passport'),
      onToggle: () => toggles++,
      isToggling: true,
    );

    await tester.tap(find.text('Passport'));

    expect(toggles, 0);
  });

  testWidgets('exposes the row as one checkable control', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      item: buildChecklistItemEntity(id: 'i1', isChecked: true),
      onToggle: () {},
    );

    expect(
      tester.getSemantics(find.byKey(const Key('checklist-item-row-i1'))),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Passport',
      ),
    );
    handle.dispose();
  });
}
