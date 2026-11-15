import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/settings/presentation/controllers/reduce_flashing_controller.dart';
import 'package:traviato/features/settings/presentation/providers/settings_providers.dart';
import 'package:traviato/features/settings/presentation/widgets/reduce_flashing_settings_row.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  bool? effective;

  Widget app({bool stored = false, bool phoneReducesMotion = false}) =>
      ProviderScope(
        overrides: [initialReduceFlashingProvider.overrideWithValue(stored)],
        child: localizedApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: phoneReducesMotion),
              child: Scaffold(
                body: Column(
                  children: [
                    const ReduceFlashingSettingsRow(),
                    Consumer(
                      builder: (context, ref, _) {
                        effective = watchReduceFlashing(context, ref);
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    effective = null;
  });

  Switch theSwitch(WidgetTester tester) => tester.widget<Switch>(
    find.byKey(const Key('settings-reduce-flashing-switch')),
  );

  testWidgets('is off by default and films flash fully', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Reduce flashing'), findsOneWidget);
    expect(find.text('Softer flashes in party films'), findsOneWidget);
    expect(theSwitch(tester).value, isFalse);
    expect(effective, isFalse);
  });

  testWidgets('turning it on saves it and softens films', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('settings-reduce-flashing-switch')));
    await tester.pumpAndSettle();

    expect(theSwitch(tester).value, isTrue);
    expect(effective, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reduce_flashing'), isTrue);
  });

  testWidgets('starts from the stored choice', (tester) async {
    await tester.pumpWidget(app(stored: true));

    expect(theSwitch(tester).value, isTrue);
    expect(effective, isTrue);
  });

  testWidgets('follows the phone reducing motion, locked on', (tester) async {
    await tester.pumpWidget(app(phoneReducesMotion: true));

    expect(theSwitch(tester).value, isTrue);
    expect(theSwitch(tester).onChanged, isNull);
    expect(find.text('On while your phone reduces motion'), findsOneWidget);
    expect(effective, isTrue);
  });
}
