import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_radius.dart';
import 'package:traviato/core/theme/app_theme.dart';

class _ThemeSample extends StatelessWidget {
  const _ThemeSample();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        children: [
          Text('New memory', style: textTheme.headlineSmall),
          Card(
            child: Text('What deserves a memory?', style: textTheme.bodyLarge),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Create memory')),
          const Chip(label: Text('Romantic'), padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() {
    // Avoid GoogleFonts attempting a runtime network fetch during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AppTheme.dark applies design tokens with no inline colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const _ThemeSample()),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme!;

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.primary);

    final headline = theme.textTheme.headlineSmall!;
    expect(headline.fontFamily, contains('Fraunces'));
    expect(headline.color, AppColors.textPrimary);

    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, AppRadius.cardRadius);

    expect(find.text('New memory'), findsOneWidget);
    expect(find.text('What deserves a memory?'), findsOneWidget);
    expect(find.text('Create memory'), findsOneWidget);
    expect(find.text('Romantic'), findsOneWidget);
  });
}
