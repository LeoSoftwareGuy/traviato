import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'bonus_notification_local_data_source.dart';

const _androidChannelId = 'bonus_tasks';
const _androidChannelName = 'Bonus dares';
const _androidChannelDescription = 'Daily nudges for your trip\'s bonus tasks.';

/// Fixed ids — there is only ever one active trip's morning/evening pair at
/// a time (see #65's plan comment). Arrival ids are derived per-trip so
/// scheduling a new one on edit naturally replaces the previous pending one.
const _morningId = 1001;
const _eveningId = 1002;

/// The `timezone` package's bundled data only carries canonical IANA zone
/// names, not the legacy aliases some devices still report (e.g. Android's
/// `getLocalTimezone()` returning the pre-2022 "Europe/Kiev" for what
/// tzdata renamed to "Europe/Kyiv"). A handful of the aliases most likely
/// to actually show up in the wild, tried before giving up to UTC.
const _legacyZoneAliases = {
  'Europe/Kiev': 'Europe/Kyiv',
  'Asia/Calcutta': 'Asia/Kolkata',
  'Asia/Saigon': 'Asia/Ho_Chi_Minh',
  'Asia/Rangoon': 'Asia/Yangon',
};

/// Resolves [zoneName] against the loaded tzdata, retrying with a known
/// legacy alias (see [_legacyZoneAliases]) before letting the lookup throw
/// and the caller fall back to UTC. A standalone top-level function (rather
/// than a private class method) so it's directly unit-testable, mirroring
/// `BonusTrayDraw`'s pure-function shape (#64).
tz.Location resolveTimezoneLocation(String zoneName) {
  try {
    return tz.getLocation(zoneName);
  } catch (_) {
    final alias = _legacyZoneAliases[zoneName];
    if (alias == null) rethrow;
    return tz.getLocation(alias);
  }
}

class FlutterLocalNotificationsDataSource
    implements BonusNotificationLocalDataSource {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    tz.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(resolveTimezoneLocation(localZone.identifier));
    } catch (e) {
      debugPrint('Falling back to UTC for bonus notifications: $e');
    }

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      onTap(launchDetails?.notificationResponse?.payload);
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<void> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  }) => _schedule(
    id: _morningId,
    fireAt: fireAt,
    payload: tripId,
    title: 'Two little dares today ✦',
    body: 'Open the tray and see what today\'s got.',
  );

  @override
  Future<void> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  }) => _schedule(
    id: _eveningId,
    fireAt: fireAt,
    payload: tripId,
    title: 'Still time for a dare',
    body: 'Today\'s bonus tasks are waiting.',
  );

  @override
  Future<void> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  }) => _schedule(
    id: _arrivalId(tripId),
    fireAt: fireAt,
    payload: tripId,
    title: 'Your trip starts today ✦',
    body: 'Log the first moment and see what\'s waiting.',
  );

  @override
  Future<void> cancelMorning() => _plugin.cancel(id: _morningId);

  @override
  Future<void> cancelEvening() => _plugin.cancel(id: _eveningId);

  @override
  Future<void> cancelArrival(String tripId) =>
      _plugin.cancel(id: _arrivalId(tripId));

  Future<void> _schedule({
    required int id,
    required DateTime fireAt,
    required String payload,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      title: title,
      body: body,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// djb2 over the trip id, folded into a small positive range that can't
  /// collide with the fixed morning/evening ids.
  int _arrivalId(String tripId) {
    var hash = 5381;
    for (final unit in tripId.codeUnits) {
      hash = (hash * 33 + unit) & 0x7fffffff;
    }
    return 2000 + (hash % 100000);
  }
}
