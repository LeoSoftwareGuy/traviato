import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';
import 'package:traviato/features/checklist/presentation/pages/checklist_page.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';

import '../../fakes/fake_checklist_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeChecklistRepository repo,
}) async {
  final router = GoRouter(
    initialLocation: '/checklist',
    routes: [
      GoRoute(
        path: '/checklist',
        builder: (context, state) => const ChecklistPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/back',
        builder: (context, state) => const Scaffold(body: Text('back')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [checklistRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('renders category tabs with counts', (tester) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([
        buildChecklistItemEntity(
          id: 'i1',
          category: ChecklistCategory.travelEssentials,
          isChecked: true,
        ),
        buildChecklistItemEntity(
          id: 'i2',
          category: ChecklistCategory.travelEssentials,
        ),
      ]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    // Appears both in the tab pill and the section header below it.
    expect(find.text('Travel essentials'), findsNWidgets(2));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('1 of 2 packed'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('shows the essential badge on flagged items', (tester) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([
        buildChecklistItemEntity(id: 'i1', isEssential: true),
      ]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('Essential'), findsOneWidget);
  });

  testWidgets('tapping the check circle toggles the item', (tester) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checklist-item-check-i1')));
    await tester.pumpAndSettle();

    expect(repo.toggleCallCount, 1);
  });

  testWidgets('submitting the add-item input adds to the selected category', (
    tester,
  ) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Sunglasses');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.addCustomItemCallCount, 1);
  });

  testWidgets('shows the empty state for a category with no items', (
    tester,
  ) async {
    final repo = FakeChecklistRepository()..itemsResult = const Right([]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('No items in this category yet.'), findsOneWidget);
  });

  testWidgets('swiping an item left deletes it', (tester) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')]);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('checklist-item-dismiss-i1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(repo.deleteCallCount, 1);
    expect(repo.lastDeletedId, 'i1');
    expect(find.byKey(const Key('checklist-item-dismiss-i1')), findsNothing);
  });

  testWidgets('a failed swipe delete keeps the item and shows an error', (
    tester,
  ) async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')])
      ..deleteResult = const Left(NetworkFailure());
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('checklist-item-dismiss-i1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(repo.deleteCallCount, 1);
    expect(find.byKey(const Key('checklist-item-dismiss-i1')), findsOneWidget);
    expect(find.text('Please check your connection.'), findsOneWidget);
  });
}
