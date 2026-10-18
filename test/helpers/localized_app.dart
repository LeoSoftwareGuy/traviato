import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/l10n/context_l10n.dart';
import 'package:traviato/core/theme/app_theme.dart';

/// A themed [MaterialApp] pinned to [locale], with the app's l10n delegates,
/// for widget tests in en/ru/et (#220).
Widget localizedApp({required Locale locale, required Widget home}) =>
    MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// Sets a [width]×[height] logical-pixel screen for the rest of the test.
void setScreenSize(
  WidgetTester tester, {
  double width = 360,
  double height = 640,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
