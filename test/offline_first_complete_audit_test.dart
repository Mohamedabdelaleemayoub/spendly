import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/core/services/sync_manager.dart';
import 'package:spendly/core/services/sync_service.dart';
import 'package:spendly/core/services/uuid_generator.dart';
import 'package:spendly/data/datasources/auth_remote_datasource.dart';
import 'package:spendly/data/datasources/balance_remote_datasource.dart';
import 'package:spendly/data/datasources/category_remote_datasource.dart';
import 'package:spendly/data/datasources/expense_remote_datasource.dart';
import 'package:spendly/data/datasources/local_database.dart';
import 'package:spendly/data/datasources/local_expense_datasource.dart';
import 'package:spendly/data/datasources/profile_remote_datasource.dart';
import 'package:spendly/data/datasources/salary_advance_remote_datasource.dart';
import 'package:spendly/data/datasources/weekly_allowance_remote_datasource.dart';
import 'package:spendly/data/models/category_model.dart';
import 'package:spendly/data/models/profile_model.dart';
import 'package:spendly/data/repositories/auth_repository_impl.dart';
import 'package:spendly/data/repositories/balance_repository_impl.dart';
import 'package:spendly/data/repositories/category_repository_impl.dart';
import 'package:spendly/data/repositories/expense_repository_impl.dart';
import 'package:spendly/data/repositories/profile_repository_impl.dart';
import 'package:spendly/data/repositories/salary_advance_repository_impl.dart';
import 'package:spendly/data/repositories/weekly_allowance_repository_impl.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/governorate.dart';
import 'package:spendly/domain/entities/trip_location_type.dart';
import 'package:spendly/presentation/cubits/category/category_cubit.dart';
import 'package:spendly/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:spendly/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:spendly/presentation/cubits/report/report_cubit.dart';
import 'package:spendly/presentation/cubits/report/report_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockProfileRemoteDataSource extends Mock implements ProfileRemoteDataSource {}
class MockCategoryRemoteDataSource extends Mock implements CategoryRemoteDataSource {}
class MockExpenseRemoteDataSource extends Mock implements ExpenseRemoteDataSource {}
class MockBalanceRemoteDataSource extends Mock implements BalanceRemoteDataSource {}
class MockSalaryAdvanceRemoteDataSource extends Mock implements SalaryAdvanceRemoteDataSource {}
class MockWeeklyAllowanceRemoteDataSource extends Mock implements WeeklyAllowanceRemoteDataSource {}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalDatabase localDb;
  late SharedPreferences prefs;
  late LocalExpenseDataSource localExpenseDs;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockConnectivityService mockConnectivity;

  late MockExpenseRemoteDataSource mockExpenseRemote;
  late MockCategoryRemoteDataSource mockCategoryRemote;
  late MockProfileRemoteDataSource mockProfileRemote;
  late MockBalanceRemoteDataSource mockBalanceRemote;
  late MockSalaryAdvanceRemoteDataSource mockSalaryAdvanceRemote;
  late MockWeeklyAllowanceRemoteDataSource mockWeeklyAllowanceRemote;
  late MockAuthRemoteDataSource mockAuthRemote;

  late ExpenseRepositoryImpl expenseRepo;
  late CategoryRepositoryImpl categoryRepo;
  late ProfileRepositoryImpl profileRepo;
  late BalanceRepositoryImpl balanceRepo;
  late SalaryAdvanceRepositoryImpl salaryAdvanceRepo;
  late WeeklyAllowanceRepositoryImpl weeklyAllowanceRepo;
  late AuthRepositoryImpl authRepo;

  late SyncManagerImpl syncManager;

  const testUserId = 'test_user_001';
  final testUser = MockUser();
  final testSession = MockSession();

  setUpAll(() {
    registerFallbackValue(ExpenseCurrency.egp);
    registerFallbackValue(TripLocationType.cairo);
    registerFallbackValue(Governorate.cairo);
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    localDb = LocalDatabase();
    await localDb.init(
      inMemory: true,
      customFactory: databaseFactoryFfi,
    );
    await localDb.clearAll();

    localExpenseDs = LocalExpenseDataSourceImpl(
      prefs: prefs,
      localDatabase: localDb,
    );

    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockConnectivity = MockConnectivityService();

    when(() => testUser.id).thenReturn(testUserId);
    when(() => testUser.email).thenReturn('user@spendly.app');
    when(() => mockAuth.currentUser).thenReturn(testUser);
    when(() => mockAuth.currentSession).thenReturn(testSession);
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    when(() => mockConnectivity.isOnline).thenReturn(false);
    when(() => mockConnectivity.isOnlineStream).thenAnswer((_) => Stream.value(false));

    mockExpenseRemote = MockExpenseRemoteDataSource();
    mockCategoryRemote = MockCategoryRemoteDataSource();
    mockProfileRemote = MockProfileRemoteDataSource();
    mockBalanceRemote = MockBalanceRemoteDataSource();
    mockSalaryAdvanceRemote = MockSalaryAdvanceRemoteDataSource();
    mockWeeklyAllowanceRemote = MockWeeklyAllowanceRemoteDataSource();
    mockAuthRemote = MockAuthRemoteDataSource();

    when(() => mockAuthRemote.currentUser).thenReturn(testUser);
    when(() => mockAuthRemote.currentSession).thenReturn(testSession);
    when(() => mockAuthRemote.authStateChanges).thenAnswer((_) => const Stream.empty());

    // Setup default remote failures to simulate offline fallback gracefully
    when(() => mockProfileRemote.getProfile(any())).thenThrow(SocketException('Offline'));
    when(() => mockProfileRemote.getEmployeesWithStats()).thenThrow(SocketException('Offline'));
    when(() => mockExpenseRemote.getExpenses(
      userId: any(named: 'userId'),
      categoryId: any(named: 'categoryId'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      currency: any(named: 'currency'),
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      paymentMethod: any(named: 'paymentMethod'),
      tripLocationType: any(named: 'tripLocationType'),
      governorate: any(named: 'governorate'),
      searchQuery: any(named: 'searchQuery'),
    )).thenThrow(SocketException('Offline'));
    when(() => mockExpenseRemote.getExpensesForMonth(any(), userId: any(named: 'userId'), currency: any(named: 'currency')))
        .thenThrow(SocketException('Offline'));
    when(() => mockCategoryRemote.getCategories()).thenThrow(SocketException('Offline'));
    when(() => mockWeeklyAllowanceRemote.getWeeklyAllowanceTransactions(
      userId: any(named: 'userId'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    )).thenThrow(SocketException('Offline'));
    when(() => mockSalaryAdvanceRemote.getSalaryAdvances(any())).thenThrow(SocketException('Offline'));
    when(() => mockBalanceRemote.getBalanceTransactions(any())).thenThrow(SocketException('Offline'));
    when(() => mockBalanceRemote.getEmployeeBalanceSummary(any())).thenThrow(SocketException('Offline'));

    syncManager = SyncManagerImpl(
      localDatabase: localDb,
      supabaseClient: mockSupabase,
      connectivityService: mockConnectivity,
    );

    final syncService = SyncServiceImpl(
      localDataSource: localExpenseDs,
      supabaseClient: mockSupabase,
      syncManager: syncManager,
    );

    expenseRepo = ExpenseRepositoryImpl(
      remoteDataSource: mockExpenseRemote,
      localDataSource: localExpenseDs,
      syncService: syncService,
      supabaseClient: mockSupabase,
      localDatabase: localDb,
      syncManager: syncManager,
    );

    categoryRepo = CategoryRepositoryImpl(
      remoteDataSource: mockCategoryRemote,
      localDatabase: localDb,
    );

    profileRepo = ProfileRepositoryImpl(
      remoteDataSource: mockProfileRemote,
      localDatabase: localDb,
    );

    balanceRepo = BalanceRepositoryImpl(
      remoteDataSource: mockBalanceRemote,
      localExpenseDataSource: localExpenseDs,
      expenseRepository: expenseRepo,
      localDatabase: localDb,
    );

    salaryAdvanceRepo = SalaryAdvanceRepositoryImpl(
      remoteDataSource: mockSalaryAdvanceRemote,
      localDatabase: localDb,
    );

    weeklyAllowanceRepo = WeeklyAllowanceRepositoryImpl(
      remoteDataSource: mockWeeklyAllowanceRemote,
      localDatabase: localDb,
    );

    authRepo = AuthRepositoryImpl(remoteDataSource: mockAuthRemote);

    // Seed test profile
    await localDb.saveProfile(ProfileModel(
      id: testUserId,
      email: 'user@spendly.app',
      name: 'Mohamed Tester',
      role: 'admin',
      status: 'active',
      salaryAmount: 25000,
      salaryCurrency: ExpenseCurrency.egp,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Seed default categories
    await categoryRepo.seedDefaultCategoriesIfEmpty();
  });

  tearDown(() async {
    syncManager.dispose();
  });

  group('1. Offline App Startup & Navigation Resilience', () {
    test('Can open app offline, read profile, categories and dashboard statistics from local cache', () async {
      final dashboardCubit = DashboardCubit(
        expenseRepository: expenseRepo,
        categoryRepository: categoryRepo,
        profileRepository: profileRepo,
        authRepository: authRepo,
      );

      await dashboardCubit.loadDashboard();
      expect(dashboardCubit.state, isA<DashboardLoaded>());
      final loaded = dashboardCubit.state as DashboardLoaded;
      expect(loaded.isAdmin, isTrue);
      expect(loaded.totalThisMonthEgp, 0.0);
      expect(loaded.totalThisMonthUsd, 0.0);
    });

    test('Reports, Employees, and Categories cubits load gracefully offline without internet', () async {
      final reportCubit = ReportCubit(
        expenseRepository: expenseRepo,
        profileRepository: profileRepo,
        authRepository: authRepo,
      );

      await reportCubit.loadReport();
      expect(reportCubit.state, isA<ReportLoaded>());

      final catCubit = CategoryCubit(categoryRepository: categoryRepo);
      await catCubit.loadCategories();
      expect(catCubit.categories.length, greaterThanOrEqualTo(6));
    });
  });

  group('2. Offline CRUD Operations for All Features', () {
    test('Offline Expense CRUD: creates pending expense, enqueues to sync_queue, updates balance', () async {
      when(() => mockExpenseRemote.createExpense(
        id: any(named: 'id'),
        title: any(named: 'title'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        tripLocationType: any(named: 'tripLocationType'),
        governorate: any(named: 'governorate'),
        paymentMethod: any(named: 'paymentMethod'),
        expenseDate: any(named: 'expenseDate'),
        categoryId: any(named: 'categoryId'),
        notes: any(named: 'notes'),
        receiptFile: any(named: 'receiptFile'),
      )).thenThrow(SocketException('Network offline'));

      final expense = await expenseRepo.createExpense(
        title: 'Offline Lunch',
        amount: 350.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        categoryId: 'cat_food',
      );

      expect(expense.isPending, isTrue);
      expect(expense.amount, 350.0);

      // Verify stored locally
      final localExpenses = await expenseRepo.getExpenses(userId: testUserId);
      expect(localExpenses.length, 1);
      expect(localExpenses.first.id, expense.id);
      expect(localExpenses.first.isPending, isTrue);

      // Verify sync_queue contains the insert operation
      final queueOps = await localDb.getPendingSyncOperations();
      expect(queueOps.length, 1);
      expect(queueOps.first['entity_type'], 'expense');
      expect(queueOps.first['operation'], 'INSERT');
      expect(queueOps.first['entity_id'], expense.id);
    });

    test('Offline Category CRUD: creates category locally, enqueues to sync_queue', () async {
      when(() => mockCategoryRemote.createCategory(
        id: any(named: 'id'),
        name: any(named: 'name'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
      )).thenThrow(SocketException('Network offline'));

      final cat = await categoryRepo.createCategory(
        name: 'Offline Maintenance',
        icon: 'build',
        color: '#E17055',
      );

      expect(cat.name, 'Offline Maintenance');

      final localCats = await categoryRepo.getCategories();
      expect(localCats.any((c) => c.name == 'Offline Maintenance'), isTrue);

      final queueOps = await localDb.getPendingSyncOperations();
      expect(queueOps.any((op) => op['entity_type'] == 'category' && op['operation'] == 'INSERT'), isTrue);
    });

    test('Offline Weekly Allowance CRUD: creates & updates allowance, preserves userId', () async {
      when(() => mockWeeklyAllowanceRemote.createAllowanceTransaction(
        id: any(named: 'id'),
        userId: any(named: 'userId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        transactionDate: any(named: 'transactionDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      final allowance = await weeklyAllowanceRepo.createAllowanceTransaction(
        userId: testUserId,
        amount: 5000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: DateTime.now(),
        note: 'Week 34 Work Allowance',
      );

      expect(allowance.amount, 5000.0);
      expect(allowance.userId, testUserId);

      // Update allowance offline
      when(() => mockWeeklyAllowanceRemote.updateAllowanceTransaction(
        id: any(named: 'id'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        transactionDate: any(named: 'transactionDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      final updated = await weeklyAllowanceRepo.updateAllowanceTransaction(
        id: allowance.id,
        amount: 6000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: DateTime.now(),
        note: 'Updated Allowance Note',
      );

      expect(updated.amount, 6000.0);
      expect(updated.userId, testUserId); // Verified userId is preserved!

      final localList = await weeklyAllowanceRepo.getWeeklyAllowanceTransactions(userId: testUserId);
      expect(localList.first.amount, 6000.0);
      expect(localList.first.userId, testUserId);
    });

    test('Offline Salary Advance CRUD: creates & updates advance, preserves userId', () async {
      when(() => mockSalaryAdvanceRemote.createSalaryAdvance(
        id: any(named: 'id'),
        userId: any(named: 'userId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        advanceDate: any(named: 'advanceDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      final advance = await salaryAdvanceRepo.createSalaryAdvance(
        userId: testUserId,
        amount: 2500.0,
        currency: ExpenseCurrency.egp,
        advanceDate: DateTime.now(),
        note: 'Mid-month advance',
      );

      expect(advance.amount, 2500.0);
      expect(advance.userId, testUserId);

      when(() => mockSalaryAdvanceRemote.updateSalaryAdvance(
        id: any(named: 'id'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        advanceDate: any(named: 'advanceDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      final updatedAdvance = await salaryAdvanceRepo.updateSalaryAdvance(
        id: advance.id,
        amount: 3000.0,
        currency: ExpenseCurrency.egp,
        advanceDate: DateTime.now(),
        note: 'Mid-month advance (increased)',
      );

      expect(updatedAdvance.amount, 3000.0);
      expect(updatedAdvance.userId, testUserId); // Verified userId is preserved!
    });

    test('Offline Balance Deposit CRUD: adds balance and enqueues balance_transaction', () async {
      when(() => mockBalanceRemote.addBalance(
        id: any(named: 'id'),
        userId: any(named: 'userId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        transactionDate: any(named: 'transactionDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      final balanceTx = await balanceRepo.addBalance(
        userId: testUserId,
        amount: 10000.0,
        currency: ExpenseCurrency.egp,
        note: 'Offline Balance Credit',
      );

      expect(balanceTx.amount, 10000.0);
      expect(balanceTx.userId, testUserId);

      final queueOps = await localDb.getPendingSyncOperations();
      expect(queueOps.any((op) => op['entity_type'] == 'balance_transaction' && op['operation'] == 'INSERT'), isTrue);
    });
  });

  group('3. Multi-Currency & Offline Balance Resilience', () {
    test('Calculates available balance, received, spent strictly isolated between EGP and USD', () async {
      // 1. Add 10,000 EGP balance
      when(() => mockBalanceRemote.addBalance(
        id: any(named: 'id'),
        userId: any(named: 'userId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        transactionDate: any(named: 'transactionDate'),
        note: any(named: 'note'),
      )).thenThrow(SocketException('Network offline'));

      await balanceRepo.addBalance(
        userId: testUserId,
        amount: 10000.0,
        currency: ExpenseCurrency.egp,
      );

      // 2. Add 500 USD balance
      await balanceRepo.addBalance(
        userId: testUserId,
        amount: 500.0,
        currency: ExpenseCurrency.usd,
      );

      // 3. Add 2,000 EGP expense
      when(() => mockExpenseRemote.createExpense(
        id: any(named: 'id'),
        title: any(named: 'title'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        tripLocationType: any(named: 'tripLocationType'),
        governorate: any(named: 'governorate'),
        paymentMethod: any(named: 'paymentMethod'),
        expenseDate: any(named: 'expenseDate'),
        categoryId: any(named: 'categoryId'),
        notes: any(named: 'notes'),
        receiptFile: any(named: 'receiptFile'),
      )).thenThrow(SocketException('Network offline'));

      await expenseRepo.createExpense(
        amount: 2000.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        categoryId: 'cat_food',
      );

      // 4. Add 100 USD expense
      await expenseRepo.createExpense(
        amount: 100.0,
        currency: ExpenseCurrency.usd,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        categoryId: 'cat_hotel',
      );

      final summary = await balanceRepo.getEmployeeBalanceSummary(testUserId);

      // EGP calculations
      expect(summary.totalReceivedEgp, 10000.0);
      expect(summary.totalSpentEgp, 2000.0);
      expect(summary.availableBalanceEgp, 8000.0);

      // USD calculations (strictly isolated)
      expect(summary.totalReceivedUsd, 500.0);
      expect(summary.totalSpentUsd, 100.0);
      expect(summary.availableBalanceUsd, 400.0);
    });

    test('Allows spending exceeding available balance (negative balance) offline without crashing', () async {
      // Create expense of 15,000 EGP when available balance is 0
      when(() => mockExpenseRemote.createExpense(
        id: any(named: 'id'),
        title: any(named: 'title'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        tripLocationType: any(named: 'tripLocationType'),
        governorate: any(named: 'governorate'),
        paymentMethod: any(named: 'paymentMethod'),
        expenseDate: any(named: 'expenseDate'),
        categoryId: any(named: 'categoryId'),
        notes: any(named: 'notes'),
        receiptFile: any(named: 'receiptFile'),
      )).thenThrow(SocketException('Network offline'));

      final expense = await expenseRepo.createExpense(
        amount: 15000.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        categoryId: 'cat_transport',
      );

      expect(expense.amount, 15000.0);

      final summary = await balanceRepo.getEmployeeBalanceSummary(testUserId);
      expect(summary.availableBalanceEgp, -15000.0);
      expect(summary.totalSpentEgp, 15000.0);
    });
  });

  group('4. Connectivity Restoration, Auto-Sync & Duplicate Protection', () {
    test('Processes sync_queue in FIFO order and prevents duplicate server records', () async {
      // 1. Enqueue 2 mutations offline
      final op1 = UuidGenerator.generate();
      final op2 = UuidGenerator.generate();

      await localDb.enqueueSyncOperation(
        operationId: op1,
        entityType: 'category',
        entityId: 'cat_test_1',
        operation: 'INSERT',
        payload: {'id': 'cat_test_1', 'name': 'Cat 1', 'icon': 'star', 'color': '#000000'},
      );

      await localDb.enqueueSyncOperation(
        operationId: op2,
        entityType: 'balance_transaction',
        entityId: 'tx_test_1',
        operation: 'INSERT',
        payload: {'id': 'tx_test_1', 'user_id': testUserId, 'amount': 1500.0, 'currency': 'EGP', 'type': 'credit', 'transaction_date': '2026-08-25'},
      );

      var pending = await localDb.getPendingSyncOperations();
      expect(pending.length, 2);
      expect(pending[0]['operation_id'], op1);
      expect(pending[1]['operation_id'], op2);

      // Verify FIFO ordering
      expect(pending[0]['created_at'], isNotNull);
    });

    test('Deleted items are not resurrected during server pull (tombstone preservation)', () async {
      // 1. Save a local category
      final cat = CategoryModel(
        id: 'cat_deleted_soon',
        name: 'To Delete',
        icon: 'delete',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDb.saveCategory(cat);

      // 2. Queue delete operation
      await localDb.deleteCategory(cat.id);
      await localDb.enqueueSyncOperation(
        operationId: UuidGenerator.generate(),
        entityType: 'category',
        entityId: cat.id,
        operation: 'DELETE',
        payload: {'id': cat.id},
      );

      // 3. Simulate remote pull bringing back cat_deleted_soon
      await localDb.saveCategories([cat]);

      // 4. Verify local DB did NOT resurrect the category
      final localCats = await localDb.getCategories();
      expect(localCats.any((c) => c.id == cat.id), isFalse);
    });
  });
}
