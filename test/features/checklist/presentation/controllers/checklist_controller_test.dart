import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';
import 'package:traviato/features/checklist/presentation/controllers/checklist_controller.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';

import '../../fakes/fake_checklist_repository.dart';

ProviderContainer _buildContainer(FakeChecklistRepository repo) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [checklistRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  test('populates from suggestions when the checklist is empty', () async {
    final repo = FakeChecklistRepository()
      ..itemsResult = const Right([])
      ..populateResult = Right([
        buildChecklistItemEntity(id: 'i1', title: 'Passport'),
      ]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final state = await container.read(
      checklistControllerProvider('t1').future,
    );

    expect(repo.populateCallCount, 1);
    expect(state.items, hasLength(1));
    expect(state.items.single.title, 'Passport');
  });

  test('does not populate when the checklist already has items', () async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    await container.read(checklistControllerProvider('t1').future);

    expect(repo.populateCallCount, 0);
  });

  test('computes overall and per-category progress', () async {
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
        buildChecklistItemEntity(
          id: 'i3',
          category: ChecklistCategory.clothingShoes,
          isChecked: true,
        ),
      ]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);

    final state = await container.read(
      checklistControllerProvider('t1').future,
    );

    expect(state.totalCount, 3);
    expect(state.checkedCount, 2);
    expect(state.progressPercent, 67);
    expect(state.countFor(ChecklistCategory.travelEssentials), 2);
    expect(state.checkedCountFor(ChecklistCategory.travelEssentials), 1);
    expect(state.countFor(ChecklistCategory.clothingShoes), 1);
  });

  test('selectCategory updates the selected category', () async {
    final repo = FakeChecklistRepository()
      ..itemsResult = Right([buildChecklistItemEntity(id: 'i1')]);
    final container = _buildContainer(repo);
    addTearDown(container.dispose);
    container.listen(checklistControllerProvider('t1'), (_, _) {});

    await container.read(checklistControllerProvider('t1').future);
    final notifier = container.read(checklistControllerProvider('t1').notifier);

    notifier.selectCategory(ChecklistCategory.gadgetsTech);

    final state = container.read(checklistControllerProvider('t1')).value!;
    expect(state.selectedCategory, ChecklistCategory.gadgetsTech);
  });

  test(
    'applyItemUpserted adds a new item and replaces an existing one',
    () async {
      final repo = FakeChecklistRepository()..itemsResult = const Right([]);
      final container = _buildContainer(repo);
      addTearDown(container.dispose);
      container.listen(checklistControllerProvider('t1'), (_, _) {});

      await container.read(checklistControllerProvider('t1').future);
      final notifier = container.read(
        checklistControllerProvider('t1').notifier,
      );

      final item = buildChecklistItemEntity(id: 'i1', title: 'Passport');
      notifier.applyItemUpserted(item);
      expect(
        container
            .read(checklistControllerProvider('t1'))
            .value
            ?.items
            .single
            .title,
        'Passport',
      );

      final updated = buildChecklistItemEntity(
        id: 'i1',
        title: 'Passport',
        isChecked: true,
      );
      notifier.applyItemUpserted(updated);
      final state = container.read(checklistControllerProvider('t1')).value!;
      expect(state.items, hasLength(1));
      expect(state.items.single.isChecked, isTrue);
    },
  );
}
