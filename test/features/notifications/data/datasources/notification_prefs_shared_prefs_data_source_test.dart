import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/notifications/data/datasources/notification_prefs_shared_prefs_data_source.dart';
import 'package:traviato/features/notifications/domain/entities/notification_prefs_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns defaults when nothing was ever saved', () async {
    final ds = NotificationPrefsSharedPrefsDataSource();
    final prefs = await ds.load();
    expect(prefs, const NotificationPrefsEntity());
  });

  test('save then load round-trips every field', () async {
    final ds = NotificationPrefsSharedPrefsDataSource();
    final saved = NotificationPrefsEntity(
      ignoreStreak: 2,
      isMuted: true,
      lastAppOpenDate: DateTime(2026, 8, 10),
      lastNotificationScheduledDate: DateTime(2026, 8, 9),
      hasShownPermissionRationale: true,
    );

    await ds.save(saved);
    final loaded = await ds.load();

    expect(loaded, saved);
  });

  test('save with null dates clears previously stored ones', () async {
    final ds = NotificationPrefsSharedPrefsDataSource();
    await ds.save(
      NotificationPrefsEntity(lastAppOpenDate: DateTime(2026, 8, 10)),
    );
    await ds.save(const NotificationPrefsEntity());

    final loaded = await ds.load();
    expect(loaded.lastAppOpenDate, isNull);
  });
}
