import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/widgets/dashed_rrect_border.dart';
import 'package:traviato/features/quest/presentation/widgets/add_quest_row.dart';

void main() {
  testWidgets('the dashed border uses the gold affordance color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddQuestRow(dayNumber: 3, onTap: () {}),
        ),
      ),
    );

    final dashedBorder = tester.widget<DashedRRectBorder>(
      find.byType(DashedRRectBorder),
    );
    expect(dashedBorder.color, AppColors.tint(AppColors.primary, .7));
  });
}
