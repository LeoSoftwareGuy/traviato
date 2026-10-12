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

    expect(find.text('Storyni'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Every memory,'), findsOneWidget);
    expect(find.text('beautifully captured.'), findsOneWidget);
    expect(
      find.textContaining('From big celebrations to spontaneous'),
      findsOneWidget,
    );
    expect(find.text('Weddings'), findsOneWidget);
    expect(
      find.text('Make plans. Make memories. Make them last.'),
      findsOneWidget,
    );
    expect(find.text('THE BEFORE'), findsOneWidget);
    expect(
      find.text("Plan the fun. We'll handle the details."),
      findsOneWidget,
    );
    expect(find.text('THE DURING'), findsOneWidget);
    expect(find.text('Live it up. Jot it down.'), findsOneWidget);
    expect(find.text('THE AFTER'), findsOneWidget);
    expect(find.text('Good times deserve a replay.'), findsOneWidget);
    expect(find.text('Family trip to Tokyo'), findsOneWidget);
    expect(find.text('Start capturing your moments'), findsOneWidget);
  });

  testWidgets('drops the old numbered steps and the testimonial', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const GuestLandingPage()),
    );
    await tester.pump();

    expect(find.text('How it works'), findsNothing);
    expect(find.text('Capture the moment'), findsNothing);
    expect(find.textContaining('Mira K.'), findsNothing);
  });

  for (final size in const [Size(320, 568), Size(375, 667), Size(430, 932)]) {
    testWidgets('lays out without overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const GuestLandingPage()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
