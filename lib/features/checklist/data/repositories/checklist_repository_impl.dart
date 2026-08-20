import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_item_entity.dart';
import '../../domain/entities/checklist_suggestion_entity.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_remote_data_source.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  ChecklistRepositoryImpl({required ChecklistRemoteDataSource remote})
    : _remote = remote;

  final ChecklistRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ChecklistItemEntity>>> getItems(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getItems(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChecklistSuggestionEntity>>>
  getSuggestions() async {
    try {
      return Right(await _remote.getSuggestions());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> addCustomItem({
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  }) async {
    try {
      return Right(
        await _remote.addItem(
          id: const Uuid().v4(),
          tripId: tripId,
          category: category,
          title: title,
          position: position,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecked({
    required String id,
    required bool checked,
  }) async {
    try {
      return Right(await _remote.toggleChecked(id: id, checked: checked));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChecklistItemEntity>>> populateFromSuggestions(
    String tripId,
  ) async {
    try {
      final suggestions = await _remote.getSuggestions();
      final positionByCategory = <ChecklistCategory, int>{};
      final drafts = [
        for (final suggestion in suggestions)
          ChecklistItemDraft(
            id: const Uuid().v4(),
            tripId: tripId,
            title: suggestion.title,
            category: suggestion.category,
            isEssential: suggestion.isEssential,
            position: positionByCategory.update(
              suggestion.category,
              (value) => value + 1,
              ifAbsent: () => 0,
            ),
          ),
      ];
      return Right(await _remote.insertItems(drafts));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
