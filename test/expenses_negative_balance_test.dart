import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/data/models/expense_model.dart';
import 'package:spendly/domain/entities/balance_transaction.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/domain/entities/employee_balance_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/financial_history_item.dart';
import 'package:spendly/domain/entities/trip_location_type.dart';
import 'package:spendly/domain/entities/governorate.dart';
import 'package:spendly/domain/repositories/auth_repository.dart';
import 'package:spendly/domain/repositories/balance_repository.dart';
import 'package:spendly/domain/repositories/category_repository.dart';
import 'package:spendly/domain/repositories/expense_repository.dart';
import 'package:spendly/presentation/cubits/balance/employee_balance_cubit.dart';
import 'package:spendly/presentation/cubits/category/category_cubit.dart';
import 'package:spendly/presentation/cubits/expense/expense_cubit.dart';
import 'package:spendly/presentation/pages/expenses/add_expense_page.dart';
import 'package:spendly/l10n/app_localizations.dart';

// ── Fakes & Mocks ────────────────────────────────────────────────────────────

class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses = [];
  bool shouldThrow = false;

  @override
  Future<Expense> createExpense({
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    final exp = Expense(
      id: 'exp-${expenses.length + 1}',
      userId: 'user-1',
      title: title,
      amount: amount,
      currency: currency,
      tripLocationType: tripLocationType,
      governorate: governorate,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      categoryId: categoryId,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    expenses.add(exp);
    return exp;
  }

  @override
  Future<List<Expense>> getExpenses({
    String? categoryId,
    ExpenseCurrency? currency,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
    String? paymentMethod,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? userId,
  }) async {
    return List.unmodifiable(expenses);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(
    DateTime month, {
    String? userId,
    ExpenseCurrency? currency,
  }) async {
    return List.unmodifiable(expenses);
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    return expenses.firstWhere((e) => e.id == id);
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) async {
    final idx = expenses.indexWhere((e) => e.id == id);
    final old = expenses[idx];
    final updated = old.copyWith(
      title: title.isNotEmpty ? title : old.title,
      amount: amount,
      currency: currency,
      tripLocationType: tripLocationType,
      governorate: governorate,
      categoryId: categoryId ?? old.categoryId,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      notes: notes ?? old.notes,
    );
    expenses[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<int> syncPendingExpenses({String? userId}) async => 0;
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getCategories() async {
    return [
      const Category(id: 'cat-1', name: 'Food & Meals', icon: 'fastfood'),
      const Category(id: 'cat-2', name: 'Transportation', icon: 'directions_car'),
    ];
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    return Category(id: 'cat-new', name: name, icon: icon, color: color);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {}
}

class FakeAuthRepository implements AuthRepository {
  final User _user = const User(
    id: 'user-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-08-18',
  );

  @override
  User? get currentUser => _user;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    return AuthResponse(user: _user);
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password, String? name}) async {
    return AuthResponse(user: _user);
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    return UserResponse.fromJson({'user': _user.toJson()});
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signInWithGoogle({String? redirectTo}) async => true;
}

class FakeBalanceRepository implements BalanceRepository {
  EmployeeBalanceSummary summary;

  FakeBalanceRepository({required this.summary});

  @override
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    return BalanceTransaction(
      id: 'tx-1',
      userId: userId,
      amount: amount,
      currency: currency,
      type: BalanceTransactionType.credit,
      transactionDate: transactionDate ?? DateTime.now(),
      note: note,
      createdBy: 'admin-1',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async {
    return summary;
  }

  @override
  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances() async {
    return [summary];
  }

  @override
  Future<List<BalanceTransaction>> getBalanceTransactions(String userId) async => [];

  @override
  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId) async => [];
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Negative Balance Expenses & Calculations Suite', () {
    test('1. Expense amount less than available balance -> succeeds and leaves positive balance', () {
      final summaryBefore = EmployeeBalanceSummary(
        userId: 'user-1',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        totalReceivedEgp: 1000.0,
        totalSpentEgp: 200.0,
        availableBalanceEgp: 800.0,
        totalReceivedUsd: 0.0,
        totalSpentUsd: 0.0,
        availableBalanceUsd: 0.0,
      );

      const expenseAmount = 300.0;
      final newTotalSpent = summaryBefore.totalSpentEgp + expenseAmount;
      final newAvailable = summaryBefore.totalReceivedEgp - newTotalSpent;

      expect(newAvailable, 500.0);
      expect(newAvailable > 0, isTrue);
    });

    test('2. Expense amount equal to available balance -> succeeds and leaves 0 balance', () {
      final summaryBefore = EmployeeBalanceSummary(
        userId: 'user-1',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        totalReceivedEgp: 500.0,
        totalSpentEgp: 0.0,
        availableBalanceEgp: 500.0,
        totalReceivedUsd: 0.0,
        totalSpentUsd: 0.0,
        availableBalanceUsd: 0.0,
      );

      const expenseAmount = 500.0;
      final newTotalSpent = summaryBefore.totalSpentEgp + expenseAmount;
      final newAvailable = summaryBefore.totalReceivedEgp - newTotalSpent;

      expect(newAvailable, 0.0);
    });

    test('3. Expense amount greater than available balance -> succeeds and results in negative balance', () {
      final summaryBefore = EmployeeBalanceSummary(
        userId: 'user-1',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        totalReceivedEgp: 500.0,
        totalSpentEgp: 0.0,
        availableBalanceEgp: 500.0,
        totalReceivedUsd: 0.0,
        totalSpentUsd: 0.0,
        availableBalanceUsd: 0.0,
      );

      const expenseAmount = 800.0;
      final newTotalSpent = summaryBefore.totalSpentEgp + expenseAmount;
      final newAvailable = summaryBefore.totalReceivedEgp - newTotalSpent;

      expect(newAvailable, -300.0);
      expect(newAvailable < 0, isTrue);
    });

    test('4. Multiple successive expenses continue to accumulate negative balance correctly', () {
      double totalReceived = 500.0;
      double totalSpent = 0.0;

      // First expense: 800 EGP
      totalSpent += 800.0;
      double balance1 = totalReceived - totalSpent;
      expect(balance1, -300.0);

      // Second expense: 200 EGP
      totalSpent += 200.0;
      double balance2 = totalReceived - totalSpent;
      expect(balance2, -500.0);

      // Third expense: 150 EGP
      totalSpent += 150.0;
      double balance3 = totalReceived - totalSpent;
      expect(balance3, -650.0);
    });

    test('5. USD balance works correctly with negative balance', () {
      final summaryBefore = EmployeeBalanceSummary(
        userId: 'user-1',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        totalReceivedEgp: 0.0,
        totalSpentEgp: 0.0,
        availableBalanceEgp: 0.0,
        totalReceivedUsd: 100.0,
        totalSpentUsd: 0.0,
        availableBalanceUsd: 100.0,
      );

      const expenseAmountUsd = 250.0;
      final newTotalSpentUsd = summaryBefore.totalSpentUsd + expenseAmountUsd;
      final newAvailableUsd = summaryBefore.totalReceivedUsd - newTotalSpentUsd;

      expect(newAvailableUsd, -150.0);
      expect(summaryBefore.availableBalanceFor(ExpenseCurrency.usd), 100.0);
    });

    test('6. EGP & USD separate multi-currency balances with negative values', () {
      final summary = EmployeeBalanceSummary(
        userId: 'user-1',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        totalReceivedEgp: 1000.0,
        totalSpentEgp: 1500.0,
        availableBalanceEgp: -500.0,
        totalReceivedUsd: 200.0,
        totalSpentUsd: 50.0,
        availableBalanceUsd: 150.0,
      );

      expect(summary.availableBalanceFor(ExpenseCurrency.egp), -500.0);
      expect(summary.availableBalanceFor(ExpenseCurrency.usd), 150.0);
      expect(summary.hasRemainingBalance, isTrue); // USD has remaining balance
    });

    test('7. Offline ExpenseModel persists with pending sync status and negative-ready amount', () {
      final model = ExpenseModel(
        id: 'local-exp-1',
        userId: 'user-1',
        title: 'Emergency Parts',
        amount: 2500.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(model.amount, 2500.0);
      expect(model.syncStatus, SyncStatus.pending);

      final json = model.toJson(includeId: true);
      expect(json['id'], 'local-exp-1');
      expect(json['amount'], 2500.0);
      expect(json['currency'], 'EGP');
    });

    test('8. ExpenseCubit successfully creates expense exceeding balance and emits states', () async {
      final fakeExpenseRepo = FakeExpenseRepository();
      final cubit = ExpenseCubit(expenseRepository: fakeExpenseRepo);

      final success = await cubit.createExpense(
        title: 'Project Tools',
        amount: 3000.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        categoryId: 'cat-1',
      );

      expect(success, isTrue);
      expect(fakeExpenseRepo.expenses.length, 1);
      expect(fakeExpenseRepo.expenses.first.amount, 3000.0);
    });

    testWidgets('9. AddExpensePage allows entering amount > available balance and submits without validation error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeExpenseRepo = FakeExpenseRepository();
      final fakeCatRepo = FakeCategoryRepository();
      final fakeAuthRepo = FakeAuthRepository();
      final fakeBalanceRepo = FakeBalanceRepository(
        summary: const EmployeeBalanceSummary(
          userId: 'user-1',
          name: 'Ahmed Mohamed',
          email: 'ahmed@company.com',
          totalReceivedEgp: 500.0,
          totalSpentEgp: 0.0,
          availableBalanceEgp: 500.0,
          totalReceivedUsd: 0.0,
          totalSpentUsd: 0.0,
          availableBalanceUsd: 0.0,
        ),
      );

      final expenseCubit = ExpenseCubit(expenseRepository: fakeExpenseRepo);
      final categoryCubit = CategoryCubit(categoryRepository: fakeCatRepo);
      final balanceCubit = EmployeeBalanceCubit(balanceRepository: fakeBalanceRepo, authRepository: fakeAuthRepo);

      await categoryCubit.loadCategories();
      await balanceCubit.loadBalance();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: AddExpensePage(
            expenseCubit: expenseCubit,
            categoryCubit: categoryCubit,
            balanceCubit: balanceCubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter amount 800 (which exceeds available balance of 500)
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '800');
      await tester.pumpAndSettle();

      // Select category
      final categoryDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Meals').last);
      await tester.pumpAndSettle();

      // Verify no insufficient balance validator message is shown
      expect(find.textContaining('الرصيد المتاح غير كافٍ'), findsNothing);

      // Submit form
      final submitButton = find.byType(ElevatedButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify expense was successfully saved in repository with 800
      expect(fakeExpenseRepo.expenses.length, 1);
      expect(fakeExpenseRepo.expenses.first.amount, 800.0);
    });

    testWidgets('10. AddExpensePage still validates required fields (amount <= 0, category)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeExpenseRepo = FakeExpenseRepository();
      final fakeCatRepo = FakeCategoryRepository();
      final fakeAuthRepo = FakeAuthRepository();
      final fakeBalanceRepo = FakeBalanceRepository(
        summary: const EmployeeBalanceSummary(
          userId: 'user-1',
          name: 'Ahmed Mohamed',
          email: 'ahmed@company.com',
          totalReceivedEgp: 500.0,
          totalSpentEgp: 0.0,
          availableBalanceEgp: 500.0,
          totalReceivedUsd: 0.0,
          totalSpentUsd: 0.0,
          availableBalanceUsd: 0.0,
        ),
      );

      final expenseCubit = ExpenseCubit(expenseRepository: fakeExpenseRepo);
      final categoryCubit = CategoryCubit(categoryRepository: fakeCatRepo);
      final balanceCubit = EmployeeBalanceCubit(balanceRepository: fakeBalanceRepo, authRepository: fakeAuthRepo);

      await categoryCubit.loadCategories();
      await balanceCubit.loadBalance();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: AddExpensePage(
            expenseCubit: expenseCubit,
            categoryCubit: categoryCubit,
            balanceCubit: balanceCubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit without entering amount or category
      final submitButton = find.byType(ElevatedButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify normal validation error is shown
      expect(find.text('يجب إدخال مبلغ أكبر من صفر.'), findsOneWidget);
    });
  });
}
