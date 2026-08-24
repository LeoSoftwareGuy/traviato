import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/core/widgets/app_bottom_nav_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders its items and the FAB navigates', (tester) async {
    var homeTapped = false;
    var expensesTapped = false;
    var fabTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            onFabTap: () => fabTapped = true,
            items: [
              AppBottomNavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: true,
                onTap: () => homeTapped = true,
              ),
              AppBottomNavBarItem(
                icon: Icons.receipt_long_outlined,
                label: 'Expenses',
                selected: false,
                onTap: () => expensesTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);

    await tester.tap(find.text('Home'));
    expect(homeTapped, isTrue);

    await tester.tap(find.text('Expenses'));
    expect(expensesTapped, isTrue);

    await tester.tap(find.byIcon(Icons.add));
    expect(fabTapped, isTrue);
  });
}
