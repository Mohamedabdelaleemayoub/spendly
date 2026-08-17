import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/category_remote_datasource.dart';
import '../data/datasources/expense_remote_datasource.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../presentation/cubits/auth/auth_cubit.dart';
import '../presentation/cubits/category/category_cubit.dart';
import '../presentation/cubits/dashboard/dashboard_cubit.dart';
import '../presentation/cubits/employee_details/employee_details_cubit.dart';
import '../presentation/cubits/employees/employees_cubit.dart';
import '../presentation/cubits/expense/expense_cubit.dart';
import '../presentation/cubits/profile/profile_cubit.dart';
import '../presentation/cubits/report/report_cubit.dart';
import '../presentation/cubits/settings/settings_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Called once during app startup after Supabase has been initialised.
/// Dependencies are registered bottom-up: clients → data sources →
/// repositories → cubits.
Future<void> initDependencies() async {
  // ── External ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseService.client);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Data Sources ─────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(client: sl()),
  );

  // ── Repositories ─────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDataSource: sl()),
  );

  // ── Cubits / State Management ─────────────────────────────────────────
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(prefs: sl()),
  );
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      authRepository: sl(),
      profileRepository: sl(),
    ),
  );
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      profileRepository: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory<CategoryCubit>(
    () => CategoryCubit(categoryRepository: sl()),
  );
  sl.registerFactory<ExpenseCubit>(
    () => ExpenseCubit(expenseRepository: sl()),
  );
  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(
      expenseRepository: sl(),
      categoryRepository: sl(),
      profileRepository: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory<ReportCubit>(
    () => ReportCubit(
      expenseRepository: sl(),
      profileRepository: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory<EmployeesCubit>(
    () => EmployeesCubit(profileRepository: sl()),
  );
  sl.registerFactory<EmployeeDetailsCubit>(
    () => EmployeeDetailsCubit(
      expenseRepository: sl(),
      profileRepository: sl(),
    ),
  );
}
