import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_radius.dart';
import 'package:traviato/features/quest/presentation/widgets/quest_tile.dart';

import '../../fakes/fake_quest_repository.dart';

BoxDecoration _cardDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).borderRadius ==
              AppRadius.cardRadius,
    ),
  );
  return container.decoration! as BoxDecoration;
}

Future<void> _pump(
  WidgetTester tester, {
  required bool completed,
  VoidCallback? onEdit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuestTile(
          quest: buildQuestEntity(
            completedAt: completed ? DateTime(2026, 1, 2) : null,
          ),
          isLast: true,
          isToggling: false,
          onToggle: () {},
          onEdit: onEdit ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('an idle quest card uses the elevated surface background '
      'and the default border', (tester) async {
    await _pump(tester, completed: false);

    final decoration = _cardDecoration(tester);
    expect(decoration.color, AppColors.surfaceElevated);
    expect(decoration.border!.top.color, AppColors.surfaceBorder);
  });

  testWidgets('hovering an idle quest card fades in the corner highlight', (
    tester,
  ) async {
    await _pump(tester, completed: false);

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.text('Pack the car')));
    await tester.pump();

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
  });

  testWidgets('tapping the card body triggers onEdit', (tester) async {
    var editCount = 0;
    await _pump(tester, completed: false, onEdit: () => editCount++);

    await tester.tap(find.text('Pack the car'));
    await tester.pump();

    expect(editCount, 1);
  });
}
