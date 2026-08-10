import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/main.dart';

void main() {
  testWidgets('TraviatoApp renders the bootstrap placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TraviatoApp()));

    expect(find.byType(BootstrapPage), findsOneWidget);
    expect(find.text('Traviato'), findsOneWidget);
  });
}
