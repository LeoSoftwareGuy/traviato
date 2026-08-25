import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../trip/domain/repositories/trip_repository.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_data_source.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({
    required ExpenseRemoteDataSource remote,
    required TripRepository tripRepository,
  }) : _remote = remote,
       _tripRepository = tripRepository;

  final ExpenseRemoteDataSource _remote;
  final TripRepository _tripRepository;

  @override
  Future<Either<Failure, List<ExpenseSummaryEntity>>> getSummaries() async {
    final tripCardsResult = await _tripRepository.getTripCards();
    return tripCardsResult.fold((failure) async => Left(failure), (
      tripCards,
    ) async {
      try {
        final itemCounts = await _remote.getExpenseItemCounts();
        return Right([
          for (final trip in tripCards)
            ExpenseSummaryEntity(
              tripId: trip.id,
              tripName: trip.name,
              place: trip.destination,
              startDate: trip.startDate,
              durationDays: trip.durationDays,
              totalAmount: trip.expenseTotal,
              itemCount: itemCounts[trip.id] ?? 0,
            ),
        ]);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on NetworkException {
        return const Left(NetworkFailure());
      } on AppException catch (e) {
        return Left(UnknownFailure(message: e.message));
      }
    });
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesForTrip(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getExpensesForTrip(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> addExpense({
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  }) async {
    try {
      return Right(
        await _remote.addExpense(
          id: const Uuid().v4(),
          tripId: tripId,
          title: title,
          amount: amount,
          category: category,
          spentOn: spentOn,
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
}
