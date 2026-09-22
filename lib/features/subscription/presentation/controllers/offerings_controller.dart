import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/subscription_offering_entity.dart';
import '../providers/subscription_providers.dart';

part 'offerings_controller.g.dart';

@riverpod
class OfferingsController extends _$OfferingsController {
  @override
  Future<List<SubscriptionOfferingEntity>> build() async {
    final repo = ref.watch(subscriptionRepositoryProvider);
    final result = await repo.getOfferings();
    return result.fold(
      (f) => throw PresentationFailureException(f),
      (offerings) => offerings,
    );
  }
}
