import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/widgets/bottom_sheet_chrome.dart';

void main() {
  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BottomSheetChrome(child: Text('sheet content'))),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('sheet content'), findsOneWidget);
  });

  testWidgets('showAppBottomSheet wraps the builder content in the chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showAppBottomSheet(
                context: context,
                builder: (_) => const Text('sheet content'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sheet content'), findsOneWidget);
    expect(find.byType(BottomSheetChrome), findsOneWidget);
  });
}
