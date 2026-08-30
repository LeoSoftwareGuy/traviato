import 'package:flutter/foundation.dart';

import '../../domain/entities/notification_prefs_entity.dart';
import '../../domain/repositories/notification_prefs_store.dart';
import '../datasources/notification_prefs_shared_prefs_data_source.dart';

/// No `Either`/`Failure` here by design — see [NotificationPrefsStore]'s
/// doc comment. A read/write hiccup degrades to safe defaults rather than
/// surfacing anywhere; this is local bookkeeping, not user data.
class NotificationPrefsStoreImpl implements NotificationPrefsStore {
  NotificationPrefsStoreImpl({
    required NotificationPrefsSharedPrefsDataSource local,
  }) : _local = local;

  final NotificationPrefsSharedPrefsDataSource _local;

  @override
  Future<NotificationPrefsEntity> load() async {
    try {
      return await _local.load();
    } catch (e) {
      debugPrint('Failed to load notification prefs, using defaults: $e');
      return const NotificationPrefsEntity();
    }
  }

  @override
  Future<void> save(NotificationPrefsEntity prefs) async {
    try {
      await _local.save(prefs);
    } catch (e) {
      debugPrint('Failed to save notification prefs: $e');
    }
  }
}
