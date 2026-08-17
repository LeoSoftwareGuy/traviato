import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/pages/guest_landing_page.dart';

void main() {
  testWidgets('renders the marketing content and both entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const GuestLandingPage()),
    );

    expect(find.text('Every memory beautifully captured'), findsOneWidget);
    expect(find.text('Start now'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('Capture the moment'), findsOneWidget);
    expect(find.text('Family trip to Tokyo'), findsOneWidget);
    expect(find.text('Maya K.'), findsOneWidget);
    expect(find.text('Start capturing your memories'), findsOneWidget);
  });
}
