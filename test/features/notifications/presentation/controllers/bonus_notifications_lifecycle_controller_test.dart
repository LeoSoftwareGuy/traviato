import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/notifications/presentation/controllers/bonus_notifications_lifecycle_controller.dart';
import 'package:traviato/features/notifications/presentation/providers/notification_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/controllers/app_language_controller.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_bonus_notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a language switch re-schedules arrival reminders (#252)', () async {
    SharedPreferences.setMockInitialValues({});
    final start = DateTime.now().add(const Duration(days: 5));
    final notifications = FakeBonusNotificationRepository();
    final container = ProviderContainer(
      overrides: [
        bonusNotificationRepositoryProvider.overrideWithValue(notifications),
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository()
            ..tripsResult = Right([
              buildTripCard(id: 'soon', startDate: start),
              buildTripCard(
                id: 'past',
                startDate: DateTime(2020, 1, 1),
                status: TripStatus.finished,
              ),
            ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.listen(bonusNotificationsLifecycleControllerProvider, (_, _) {});
    await pumpEventQueue();
    expect(notifications.scheduledArrival, isEmpty);

    await container
        .read(appLanguageControllerProvider.notifier)
        .adopt(AppLanguage.ru);
    await pumpEventQueue();

    expect(notifications.scheduledArrival.map((a) => a.$2), ['soon']);
    expect(notifications.cancelledArrivalTripIds, ['past']);
  });

  test('re-selecting the same language changes nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final notifications = FakeBonusNotificationRepository();
    final container = ProviderContainer(
      overrides: [
        bonusNotificationRepositoryProvider.overrideWithValue(notifications),
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository()
            ..tripsResult = Right([
              buildTripCard(
                startDate: DateTime.now().add(const Duration(days: 5)),
              ),
            ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.listen(bonusNotificationsLifecycleControllerProvider, (_, _) {});
    await container
        .read(appLanguageControllerProvider.notifier)
        .adopt(AppLanguage.en);
    await pumpEventQueue();

    // System → en may or may not change the locale on this machine; a
    // second en never does.
    final afterFirst = notifications.scheduledArrival.length;
    await container
        .read(appLanguageControllerProvider.notifier)
        .adopt(AppLanguage.en);
    await pumpEventQueue();
    expect(notifications.scheduledArrival.length, afterFirst);
  });
}
