import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/kept_memory/presentation/widgets/kept_memory_more_sheet.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<KeptMemoryMoreAction?> pick(WidgetTester tester, String key) async {
    KeptMemoryMoreAction? picked;
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  picked = await KeptMemoryMoreSheet.show(context),
              child: const Text('more'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('⋯ offers Share memory first, then delete (#311)', (
    tester,
  ) async {
    expect(
      await pick(tester, 'kept-memory-share'),
      KeptMemoryMoreAction.share,
    );
    expect(
      await pick(tester, 'kept-memory-delete'),
      KeptMemoryMoreAction.delete,
    );
  });

  testWidgets('labels', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: const Scaffold(body: KeptMemoryMoreSheet()),
      ),
    );
    final share = tester.getTopLeft(find.text('Share memory'));
    final delete = tester.getTopLeft(find.text('Delete this memory'));
    expect(share.dy, lessThan(delete.dy));
  });
}
