import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/presentation/controllers/bonus_tray_state.dart';
import 'package:traviato/features/bonus/presentation/widgets/bonus_task_popup_sheet.dart';

BonusTrayTask _task() => BonusTrayTask(
  assignment: BonusTaskAssignmentEntity(
    id: 'a1',
    tripId: 't1',
    templateId: 1,
    dayDate: DateTime(2026, 8, 18),
    createdAt: DateTime(2026, 1, 1),
  ),
  template: const BonusTaskTemplateEntity(
    id: 1,
    code: 'r1',
    title: 'The worst photo of the day',
    detail: "Not your best angle. That's the point.",
    points: 2,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
);

void main() {
  testWidgets('resolves true when "Open camera" is tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await BonusTaskPopupSheet.show(context, task: _task());
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('The worst photo of the day'), findsOneWidget);
    expect(find.text('✦2'), findsOneWidget);

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('resolves false when "Maybe later" is tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await BonusTaskPopupSheet.show(context, task: _task());
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
