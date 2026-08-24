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
    await tester.pump();

    expect(find.text('Trevy'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Every memory,'), findsOneWidget);
    expect(find.text('beautifully captured'), findsOneWidget);
    expect(find.text('Weddings'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Capture the moment'), findsOneWidget);
    expect(find.text('Family trip to Tokyo'), findsOneWidget);
    expect(find.text('Mira K. · 14 memories'), findsOneWidget);
    expect(find.text('Start capturing your moments'), findsOneWidget);
  });
}
