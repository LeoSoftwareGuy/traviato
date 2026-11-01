import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/notifications/presentation/providers/notification_providers.dart';
import 'package:traviato/features/notifications/presentation/widgets/memory_reminders_settings_row.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_bonus_notification_repository.dart';

void main() {
  late FakeBonusNotificationRepository notifications;

  Widget app() => ProviderScope(
    overrides: [
      bonusNotificationRepositoryProvider.overrideWithValue(notifications),
      tripRepositoryProvider.overrideWithValue(
        FakeTripRepository()
          ..tripsResult = Right([
            buildTripCard(
              id: 'soon',
              startDate: DateTime.now().add(const Duration(days: 5)),
            ),
          ]),
      ),
    ],
    child: localizedApp(
      locale: const Locale('en'),
      home: const Scaffold(body: MemoryRemindersSettingsRow()),
    ),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifications = FakeBonusNotificationRepository();
  });

  bool switchValue(WidgetTester tester) => tester
      .widget<Switch>(find.byKey(const Key('settings-reminders-switch')))
      .value;

  testWidgets('is on by default', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Memory reminders'), findsOneWidget);
    expect(switchValue(tester), isTrue);
  });

  testWidgets('switching off saves it and cancels arrival reminders', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-reminders-switch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notif_reminders_enabled'), isFalse);
    expect(notifications.cancelledArrivalTripIds, contains('soon'));
    expect(notifications.scheduledArrival, isEmpty);
  });

  testWidgets('switching back on asks for permission and re-schedules', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'notif_reminders_enabled': false});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(switchValue(tester), isFalse);

    await tester.tap(find.byKey(const Key('settings-reminders-switch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester), isTrue);
    expect(notifications.permissionGranted, isTrue);
    expect(notifications.scheduledArrival.map((a) => a.$2), contains('soon'));
  });
}
