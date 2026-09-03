import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/sync_manager.dart';
import '../core/services/sync_service.dart';
import '../data/datasources/audit_remote_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/balance_remote_datasource.dart';
import '../data/datasources/category_remote_datasource.dart';
import '../data/datasources/expense_remote_datasource.dart';
import '../data/datasources/local_database.dart';
import '../data/datasources/local_expense_datasource.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/datasources/salary_advance_remote_datasource.dart';
import '../data/datasources/salary_payment_remote_datasource.dart';
import '../data/datasources/settings_remote_datasource.dart';
import '../data/datasources/weekly_allowance_remote_datasource.dart';
import '../data/repositories/audit_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/balance_repository_impl.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../data/repositories/salary_advance_repository_impl.dart';
import '../data/repositories/salary_payment_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/weekly_allowance_repository_impl.dart';
import '../domain/repositories/audit_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/balance_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/salary_advance_repository.dart';
import '../domain/repositories/salary_payment_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/weekly_allowance_repository.dart';
import '../presentation/cubits/audit/audit_cubit.dart';
import '../presentation/cubits/auth/auth_cubit.dart';
import '../presentation/cubits/balance/admin_balance_cubit.dart';
import '../presentation/cubits/balance/employee_balance_cubit.dart';
import '../presentation/cubits/category/category_cubit.dart';
import '../presentation/cubits/dashboard/dashboard_cubit.dart';
import '../presentation/cubits/employee_details/employee_details_cubit.dart';
import '../presentation/cubits/employees/employees_cubit.dart';
import '../presentation/cubits/expense/expense_cubit.dart';
import '../presentation/cubits/notifications/admin_notification_cubit.dart';
import '../presentation/cubits/payroll/payroll_cubit.dart';
import '../presentation/cubits/profile/profile_cubit.dart';
import '../presentation/cubits/report/report_cubit.dart';
import '../presentation/cubits/salary_advances/salary_advances_cubit.dart';
import '../presentation/cubits/settings/admin_settings_cubit.dart';
import '../presentation/cubits/settings/settings_cubit.dart';
import '../presentation/cubits/weekly_allowance/weekly_allowance_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Called once during app startup after Supabase and LocalDatabase have been initialised.
/// Dependencies are registered bottom-up: clients → data sources →
/// repositories → cubits.
Future<void> initDependencies() async {
  // ── External ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => SupabaseService.client);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Local Database & Connectivity ─────────────────────────────────────
  final localDatabase = LocalDatabase();
  await localDatabase.init();
  sl.registerLazySingleton<LocalDatabase>(() => localDatabase);

  final connectivityService = ConnectivityServiceImpl();
  sl.registerLazySingleton<ConnectivityService>(() => connectivityService);

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
  sl.registerLazySingleton<LocalExpenseDataSource>(
    () => LocalExpenseDataSourceImpl(
      prefs: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<BalanceRemoteDataSource>(
    () => BalanceRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<SalaryAdvanceRemoteDataSource>(
    () => SalaryAdvanceRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<SalaryPaymentRemoteDataSource>(
    () => SalaryPaymentRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<WeeklyAllowanceRemoteDataSource>(
    () => WeeklyAllowanceRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuditRemoteDataSource>(
    () => AuditRemoteDataSourceImpl(client: sl()),
  );

  // ── Services ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<SyncManager>(
    () => SyncManagerImpl(
      localDatabase: sl(),
      supabaseClient: sl(),
      connectivityService: sl(),
    ),
  );

  sl.registerLazySingleton<SyncService>(
    () => SyncServiceImpl(
      localDataSource: sl(),
      supabaseClient: sl(),
      syncManager: sl(),
    ),
  );

  // ── Repositories ─────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncService: sl(),
      supabaseClient: sl(),
      localDatabase: sl(),
      syncManager: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<BalanceRepository>(
    () => BalanceRepositoryImpl(
      remoteDataSource: sl(),
      localExpenseDataSource: sl(),
      expenseRepository: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<SalaryAdvanceRepository>(
    () => SalaryAdvanceRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<SalaryPaymentRepository>(
    () => SalaryPaymentRepositoryImpl(
      remoteDataSource: sl(),
      profileRepository: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<WeeklyAllowanceRepository>(
    () => WeeklyAllowanceRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
    ),
  );
  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(
      remoteDataSource: sl(),
      localDatabase: sl(),
      supabaseClient: sl(),
    ),
  );

  // ── Cubits / State Management ─────────────────────────────────────────
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(prefs: sl()),
  );
  sl.registerLazySingleton<AdminSettingsCubit>(
    () => AdminSettingsCubit(settingsRepository: sl()),
  );
  sl.registerLazySingleton<AdminNotificationCubit>(
    () => AdminNotificationCubit(notificationRepository: sl()),
  );
  sl.registerFactory<EmployeeBalanceCubit>(
    () => EmployeeBalanceCubit(
      balanceRepository: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory<AdminBalanceCubit>(
    () => AdminBalanceCubit(balanceRepository: sl()),
  );
  sl.registerFactory<SalaryAdvancesCubit>(
    () => SalaryAdvancesCubit(
      salaryAdvanceRepository: sl(),
      profileRepository: sl(),
    ),
  );
  sl.registerFactory<PayrollCubit>(
    () => PayrollCubit(
      salaryPaymentRepository: sl(),
    ),
  );
  sl.registerFactory<WeeklyAllowanceCubit>(
    () => WeeklyAllowanceCubit(
      weeklyAllowanceRepository: sl(),
    ),
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
      settingsRepository: sl(),
    ),
  );
  sl.registerFactory<AuditCubit>(
    () => AuditCubit(auditRepository: sl()),
  );
}
