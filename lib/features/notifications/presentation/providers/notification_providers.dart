import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../journal/presentation/providers/day_note_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../data/datasources/bonus_notification_local_data_source.dart';
import '../../data/datasources/flutter_local_notifications_data_source.dart';
import '../../data/datasources/notification_prefs_shared_prefs_data_source.dart';
import '../../data/repositories/bonus_notification_repository_impl.dart';
import '../../data/repositories/notification_prefs_store_impl.dart';
import '../../domain/repositories/bonus_notification_repository.dart';
import '../../domain/repositories/notification_prefs_store.dart';
import '../../domain/usecases/evaluate_bonus_notifications_usecase.dart';

part 'notification_providers.g.dart';

@riverpod
BonusNotificationLocalDataSource bonusNotificationLocalDataSource(Ref ref) =>
    FlutterLocalNotificationsDataSource();

@riverpod
BonusNotificationRepository bonusNotificationRepository(Ref ref) =>
    BonusNotificationRepositoryImpl(
      local: ref.watch(bonusNotificationLocalDataSourceProvider),
    );

@riverpod
NotificationPrefsSharedPrefsDataSource notificationPrefsLocalDataSource(
  Ref ref,
) => NotificationPrefsSharedPrefsDataSource();

@riverpod
NotificationPrefsStore notificationPrefsStore(Ref ref) =>
    NotificationPrefsStoreImpl(
      local: ref.watch(notificationPrefsLocalDataSourceProvider),
    );

@riverpod
EvaluateBonusNotificationsUseCase evaluateBonusNotificationsUseCase(
  Ref ref,
) => EvaluateBonusNotificationsUseCase(
  tripRepository: ref.watch(tripRepositoryProvider),
  questRepository: ref.watch(questRepositoryProvider),
  dayNoteRepository: ref.watch(dayNoteRepositoryProvider),
  photoRepository: ref.watch(photoRepositoryProvider),
  ensureDailyTrayUseCase: ref.watch(ensureDailyTrayUseCaseProvider),
  notificationRepository: ref.watch(bonusNotificationRepositoryProvider),
  prefsStore: ref.watch(notificationPrefsStoreProvider),
);
