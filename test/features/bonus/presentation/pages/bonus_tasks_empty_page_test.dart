import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/bonus/presentation/pages/bonus_tasks_empty_page.dart';

void main() {
  testWidgets('renders the no-active-memory copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const BonusTasksEmptyPage(),
      ),
    );

    expect(find.text('No active memory yet'), findsOneWidget);
    expect(find.text('Back home'), findsOneWidget);
  });
}
