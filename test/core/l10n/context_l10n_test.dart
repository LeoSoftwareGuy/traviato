import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/l10n/context_l10n.dart';
import 'package:traviato/core/widgets/app_date_picker_sheet.dart';
import 'package:traviato/core/widgets/async_error_retry_scaffold.dart';

Widget _app(Locale? locale, Widget home) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('falls back to English without a delegate', (tester) async {
    late String retry;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            retry = context.l10n.common_retry;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(retry, 'Retry');
  });

  for (final (locale, retry) in [
    (const Locale('en'), 'Retry'),
    (const Locale('ru'), 'Повторить'),
    // No Estonian UI (#245): an Estonian locale falls back to English.
    (const Locale('et'), 'Retry'),
  ]) {
    testWidgets('retry scaffold reads "$retry" in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale,
          AsyncErrorRetryScaffold(message: 'x', onRetry: () {}),
        ),
      );
      expect(find.text(retry), findsOneWidget);
    });
  }

  testWidgets('date picker uses Russian labels and month names', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Locale('ru'),
        Scaffold(
          body: AppDatePickerSheet(
            initialDate: DateTime(2026, 8, 24),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
        ),
      ),
    );
    expect(find.text('ВЫБЕРИТЕ ДАТУ'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('пн, 24 авг. 2026'), findsOneWidget);
  });
}
