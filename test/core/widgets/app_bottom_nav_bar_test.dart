import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/core/widgets/app_bottom_nav_bar.dart';
import 'package:traviato/core/widgets/balloon_create_button.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onHome,
  VoidCallback? onExpenses,
  VoidCallback? onFab,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AppBottomNavBar(
          onFabTap: onFab ?? () {},
          fabSemanticLabel: 'Create a memory',
          items: [
            AppBottomNavBarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
              onTap: onHome ?? () {},
            ),
            AppBottomNavBarItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              selected: false,
              onTap: onExpenses ?? () {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders its items and each one calls its action', (
    tester,
  ) async {
    var homeTapped = false;
    var expensesTapped = false;
    var fabTapped = false;
    await _pump(
      tester,
      onHome: () => homeTapped = true,
      onExpenses: () => expensesTapped = true,
      onFab: () => fabTapped = true,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);

    await tester.tap(find.text('Home'));
    expect(homeTapped, isTrue);

    await tester.tap(find.text('Expenses'));
    expect(expensesTapped, isTrue);

    await tester.tap(find.byKey(const Key('nav-create-balloon')));
    expect(fabTapped, isTrue);
  });

  testWidgets('tab icons are 28 and tabs are at least 48 tall (#424)', (
    tester,
  ) async {
    await _pump(tester);

    expect(tester.widget<Icon>(find.byIcon(Icons.home_rounded)).size, 28);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.receipt_long_outlined)).size,
      28,
    );
    for (final tab in tester.widgetList(find.byType(AppBottomBarTab))) {
      final size = tester.getSize(find.byWidget(tab));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('the centre is the balloon "+", not the old square (#424)', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(BalloonCreateButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    final balloon = tester.getSize(find.byKey(const Key('nav-create-balloon')));
    // Taller than wide, like a balloon, and roughly the old 52pt weight.
    expect(balloon.height, greaterThan(balloon.width));
    expect(balloon.width, inInclusiveRange(48, 60));
  });

  testWidgets('the balloon rises above the bar', (tester) async {
    await _pump(tester);

    final balloon = tester.getRect(find.byKey(const Key('nav-create-balloon')));
    final bar = tester.getRect(find.byType(AppBottomBarSurface));
    expect(balloon.top, lessThan(bar.top));
    expect(balloon.center.dx, closeTo(bar.center.dx, .5));
  });

  testWidgets('the balloon reads "Create a memory" to a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('Create a memory'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('pressing the balloon shrinks it and taps with a haptic', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);
    double scale() => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byType(BalloonCreateButton),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('nav-create-balloon'))),
    );
    await tester.pump();
    expect(scale(), lessThan(1));

    await press.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });
}
