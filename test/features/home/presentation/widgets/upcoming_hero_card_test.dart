import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:traviato/features/home/presentation/widgets/upcoming_hero_card.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../../checklist/fakes/fake_checklist_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';

const _labels = ['Plan', 'Expenses', 'Journal'];

Future<List<String>> _pump(WidgetTester tester, TripStatus status) async {
  final taps = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checklistRepositoryProvider.overrideWithValue(
          FakeChecklistRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpcomingHeroCard(
              trip: buildTripCard(
                status: status,
                startDate: DateTime(2026, 10, 1),
                endDate: DateTime(2026, 10, 5),
              ),
              onPlanTap: () => taps.add('Plan'),
              onChecklistTap: () {},
              onJournalTap: () => taps.add('Journal'),
              onAddExpenseTap: () => taps.add('Expenses'),
              onLongPress: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

/// The Material that carries an action button's fill — the nearest one
/// above its label.
Material _buttonMaterial(WidgetTester tester, String label) => tester
    .widgetList<Material>(
      find.ancestor(of: find.text(label), matching: find.byType(Material)),
    )
    .first;

/// A translucent rect in [tint]'s hue — the InkWell's pressed highlight.
/// Matched on hue + visible alpha rather than an exact color: the fade-in
/// quantizes alpha to 8 bits, so `tint(.1)` lands at 26/255, not 0.1.
PaintPattern _paintsHighlightOf(Color tint) =>
    paints..something((method, args) {
      if (method != #drawRect) return false;
      final color = (args[1] as Paint).color;
      return color.toARGB32() & 0xFFFFFF == tint.toARGB32() & 0xFFFFFF &&
          color.a > .05 &&
          color.a < 1;
    });

void main() {
  testWidgets('upcoming memory: Journal rests in the same neutral fill as '
      'Plan and Expenses, not the accent', (tester) async {
    await _pump(tester, TripStatus.upcoming);

    for (final label in _labels) {
      expect(
        _buttonMaterial(tester, label).color,
        AppColors.surfaceDisabled,
        reason: '$label resting fill',
      );
    }
  });

  testWidgets('current memory: Journal stays the primary action', (
    tester,
  ) async {
    await _pump(tester, TripStatus.current);

    expect(_buttonMaterial(tester, 'Plan').color, AppColors.surfaceDisabled);
    expect(
      _buttonMaterial(tester, 'Expenses').color,
      AppColors.surfaceDisabled,
    );
    expect(_buttonMaterial(tester, 'Journal').color, AppColors.primary);
  });

  for (final status in [TripStatus.upcoming, TripStatus.current]) {
    for (final label in _labels) {
      testWidgets('${status.name}: pressing $label paints a visible highlight '
          'and the tap still fires', (tester) async {
        final taps = await _pump(tester, status);
        final isPrimary = status == TripStatus.current && label == 'Journal';
        final pressTint = isPrimary ? AppColors.background : AppColors.primary;
        final inkFeatures =
            Material.of(tester.element(find.text(label))) as RenderObject;

        expect(inkFeatures, isNot(_paintsHighlightOf(pressTint)));

        final gesture = await tester.startGesture(
          tester.getCenter(find.text(label)),
        );
        // Tap-down waits out the press timeout (the card sits in a
        // scrollable); then the highlight fades in over its own duration.
        // Tap-down waits out the press timeout (the card sits in a
        // scrollable), then the highlight fades in. Both land well inside
        // the card's long-press timeout, which would cancel the tap.
        await tester.pump(kPressTimeout);
        await tester.pump(const Duration(milliseconds: 250));

        expect(inkFeatures, _paintsHighlightOf(pressTint));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(taps, [label]);
      });
    }
  }
}
