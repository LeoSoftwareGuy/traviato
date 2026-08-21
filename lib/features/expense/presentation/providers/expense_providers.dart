import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../data/datasources/expense_remote_data_source.dart';
import '../../data/datasources/supabase_expense_remote_data_source.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';

part 'expense_providers.g.dart';

@riverpod
ExpenseRemoteDataSource expenseRemoteDataSource(Ref ref) =>
    SupabaseExpenseRemoteDataSource(client: ref.watch(supabaseClientProvider));

@riverpod
ExpenseRepository expenseRepository(Ref ref) => ExpenseRepositoryImpl(
  remote: ref.watch(expenseRemoteDataSourceProvider),
  tripRepository: ref.watch(tripRepositoryProvider),
);
