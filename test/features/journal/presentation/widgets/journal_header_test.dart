import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/journal_header.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onShare}) =>
      tester.pumpWidget(
        localizedApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: JournalHeader(
              stars: 3,
              onBack: () {},
              onStarsTap: () {},
              onShare: onShare,
            ),
          ),
        ),
      );

  testWidgets('the share button opens sharing (#311)', (tester) async {
    var shared = false;
    await pump(tester, onShare: () => shared = true);

    await tester.tap(find.byKey(const ValueKey('journal-share')));
    expect(shared, isTrue);
  });

  testWidgets('no share button without onShare', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('journal-share')), findsNothing);
  });
}
