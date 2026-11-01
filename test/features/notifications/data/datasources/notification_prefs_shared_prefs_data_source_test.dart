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
    expect(prefs.remindersEnabled, isTrue);
  });

  test('save then load round-trips every field', () async {
    final ds = NotificationPrefsSharedPrefsDataSource();
    const saved = NotificationPrefsEntity(
      remindersEnabled: false,
      hasShownPermissionRationale: true,
    );

    await ds.save(saved);
    final loaded = await ds.load();

    expect(loaded, saved);
  });

  test('save clears the old sticky mute from #65 (#307)', () async {
    SharedPreferences.setMockInitialValues({
      'notif_is_muted': true,
      'notif_ignore_streak': 3,
    });
    final ds = NotificationPrefsSharedPrefsDataSource();

    await ds.save(await ds.load());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('notif_is_muted'), isFalse);
    expect(prefs.containsKey('notif_ignore_streak'), isFalse);
  });
}
