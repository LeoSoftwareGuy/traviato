import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:traviato/features/expense/data/models/expense_model.dart';
import 'package:traviato/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:traviato/features/expense/domain/entities/expense_category.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

class _FakeExpenseRemoteDataSource implements ExpenseRemoteDataSource {
  _FakeExpenseRemoteDataSource({this.exception, this.itemCounts});

  Exception? exception;
  Map<String, int>? itemCounts;
  String? lastExpensesForTripId;
  Map<String, dynamic>? lastAddExpenseArgs;

  @override
  Future<Map<String, int>> getExpenseItemCounts() async {
    if (exception != null) throw exception!;
    return itemCounts ?? const {};
  }

  @override
  Future<List<ExpenseModel>> getExpensesForTrip(String tripId) async {
    if (exception != null) throw exception!;
    lastExpensesForTripId = tripId;
    return [
      ExpenseModel(
        id: 'e1',
        tripId: tripId,
        title: 'Train ticket',
        amount: 20,
        category: ExpenseCategory.transport,
        spentOn: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<ExpenseModel> addExpense({
    required String id,
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  }) async {
    if (exception != null) throw exception!;
    lastAddExpenseArgs = {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'category': category,
      'spentOn': spentOn,
    };
    return ExpenseModel(
      id: id,
      tripId: tripId,
      title: title,
      amount: amount,
      category: category,
      spentOn: spentOn,
      createdAt: spentOn,
    );
  }
}

void main() {
  group('ExpenseRepositoryImpl.getSummaries', () {
    test(
      'merges trip_card_view rows with expense_summary_view item counts',
      () async {
        final tripRepo = FakeTripRepository()
          ..tripsResult = Right([
            buildTripCard(
              id: 't1',
              name: 'Iceland ring road',
              destination: 'Vik, Iceland',
              durationDays: 11,
              expenseTotal: 2280,
            ),
            buildTripCard(
              id: 't2',
              name: 'Empty trip',
              durationDays: 5,
              expenseTotal: 0,
            ),
          ]);
        final remote = _FakeExpenseRemoteDataSource(itemCounts: {'t1': 15});
        final repo = ExpenseRepositoryImpl(
          remote: remote,
          tripRepository: tripRepo,
        );

        final result = await repo.getSummaries();

        result.fold((failure) => fail('expected Right, got Left($failure)'), (
          summaries,
        ) {
          expect(summaries, hasLength(2));
          final iceland = summaries.firstWhere((s) => s.tripId == 't1');
          expect(iceland.tripName, 'Iceland ring road');
          expect(iceland.place, 'Vik, Iceland');
          expect(iceland.totalAmount, 2280);
          expect(iceland.itemCount, 15);
          final empty = summaries.firstWhere((s) => s.tripId == 't2');
          expect(empty.totalAmount, 0);
          // No matching expense_summary_view row was returned for t2 — the
          // merge must default its item count to 0, not throw/omit the row.
          expect(empty.itemCount, 0);
        });
      },
    );

    test('propagates a Failure from the trip repository', () async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = const Left(NetworkFailure());
      final repo = ExpenseRepositoryImpl(
        remote: _FakeExpenseRemoteDataSource(),
        tripRepository: tripRepo,
      );

      final result = await repo.getSummaries();

      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });

    test('maps an exception from the item-count fetch to a Failure', () async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([buildTripCard(id: 't1')]);
      final repo = ExpenseRepositoryImpl(
        remote: _FakeExpenseRemoteDataSource(
          exception: const NetworkException(),
        ),
        tripRepository: tripRepo,
      );

      final result = await repo.getSummaries();

      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('ExpenseRepositoryImpl.getExpensesForTrip', () {
    test('returns Right(expenses) on success', () async {
      final repo = ExpenseRepositoryImpl(
        remote: _FakeExpenseRemoteDataSource(),
        tripRepository: FakeTripRepository(),
      );
      final result = await repo.getExpensesForTrip('t1');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (expenses) => expect(expenses, hasLength(1)),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = ExpenseRepositoryImpl(
        remote: _FakeExpenseRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
        tripRepository: FakeTripRepository(),
      );
      final result = await repo.getExpensesForTrip('t1');
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('ExpenseRepositoryImpl.addExpense', () {
    test('generates a client-side id and passes args through', () async {
      final remote = _FakeExpenseRemoteDataSource();
      final repo = ExpenseRepositoryImpl(
        remote: remote,
        tripRepository: FakeTripRepository(),
      );

      final result = await repo.addExpense(
        tripId: 't1',
        title: 'Fuel fill-up',
        amount: 55,
        category: ExpenseCategory.transport,
        spentOn: DateTime(2026, 1, 3),
      );

      expect(result.isRight(), isTrue);
      expect(remote.lastAddExpenseArgs!['id'], isNotEmpty);
      expect(remote.lastAddExpenseArgs!['tripId'], 't1');
      expect(remote.lastAddExpenseArgs!['title'], 'Fuel fill-up');
      expect(remote.lastAddExpenseArgs!['amount'], 55);
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = ExpenseRepositoryImpl(
        remote: _FakeExpenseRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
        tripRepository: FakeTripRepository(),
      );
      final result = await repo.addExpense(
        tripId: 't1',
        title: 'Fuel fill-up',
        amount: 55,
        category: ExpenseCategory.transport,
        spentOn: DateTime(2026, 1, 3),
      );
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });
}
