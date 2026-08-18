import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/domain/entities/balance_transaction.dart';
import 'package:spendly/domain/entities/employee_balance_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/financial_history_item.dart';
import 'package:spendly/domain/repositories/auth_repository.dart';
import 'package:spendly/domain/repositories/balance_repository.dart';
import 'package:spendly/presentation/cubits/balance/admin_balance_cubit.dart';
import 'package:spendly/presentation/cubits/balance/admin_balance_state.dart';
import 'package:spendly/presentation/cubits/balance/employee_balance_cubit.dart';
import 'package:spendly/presentation/cubits/balance/employee_balance_state.dart';

class FakeBalanceRepository implements BalanceRepository {
  final List<BalanceTransaction> transactions = [];
  final List<Expense> expenses = [];
  final List<EmployeeBalanceSummary> summaries = [];

  @override
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    DateTime? transactionDate,
    String? note,
  }) async {
    final tx = BalanceTransaction(
      id: 'tx-${transactions.length + 1}',
      userId: userId,
      amount: amount,
      type: BalanceTransactionType.credit,
      transactionDate: transactionDate ?? DateTime.now(),
      note: note,
      createdBy: 'admin-1',
      createdAt: DateTime.now(),
    );
    transactions.add(tx);
    return tx;
  }

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async {
    double totalReceived = 0.0;
    for (final tx in transactions.where((t) => t.userId == userId)) {
      if (tx.type == BalanceTransactionType.credit || tx.type == BalanceTransactionType.adjustmentAdd) {
        totalReceived += tx.amount;
      } else if (tx.type == BalanceTransactionType.adjustmentSub) {
        totalReceived -= tx.amount;
      }
    }

    double totalSpent = 0.0;
    for (final exp in expenses.where((e) => e.userId == userId)) {
      totalSpent += exp.amount;
    }

    return EmployeeBalanceSummary(
      userId: userId,
      name: 'Ahmed Mohamed',
      email: 'ahmed@company.com',
      totalReceived: totalReceived,
      totalSpent: totalSpent,
      availableBalance: totalReceived - totalSpent,
    );
  }

  @override
  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances() async {
    return [
      await getEmployeeBalanceSummary('emp-1'),
    ];
  }

  @override
  Future<List<BalanceTransaction>> getBalanceTransactions(String userId) async {
    return transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  @override
  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId) async {
    final List<FinancialHistoryItem> items = [];
    for (final tx in transactions.where((t) => t.userId == userId)) {
      items.add(FinancialHistoryItem.fromBalanceTransaction(tx));
    }
    for (final exp in expenses.where((e) => e.userId == userId)) {
      items.add(FinancialHistoryItem.fromExpense(exp));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}

class FakeAuthRepository implements AuthRepository {
  final User _user = const User(
    id: 'emp-1',
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
}

void main() {
  group('Employee Allowance & Balance System Tests', () {
    late FakeBalanceRepository fakeBalanceRepo;
    late FakeAuthRepository fakeAuthRepo;

    setUp(() {
      fakeBalanceRepo = FakeBalanceRepository();
      fakeAuthRepo = FakeAuthRepository();
    });

    test('1. Adding credit transactions accumulates balance without overwriting previous balance', () async {
      // 1. Initial balance should be 0
      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.totalReceived, 0.0);
      expect(summary.availableBalance, 0.0);

      // 2. Admin gives 1000 EGP
      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 1000.0,
        note: 'Weekly allowance',
      );

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.totalReceived, 1000.0);
      expect(summary.availableBalance, 1000.0);

      // 3. Admin gives another 500 EGP
      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 500.0,
        note: 'Additional office allowance',
      );

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      // Balance must accumulate to 1500, not overwrite to 500
      expect(summary.totalReceived, 1500.0);
      expect(summary.availableBalance, 1500.0);
    });

    test('2. Expenses deduct from available balance correctly', () async {
      // Admin gives 1000 EGP
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1000.0);

      // Employee spends 200 EGP
      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 200.0,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
        title: 'Transportation',
      ));

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.totalReceived, 1000.0);
      expect(summary.totalSpent, 200.0);
      expect(summary.availableBalance, 800.0);

      // Employee spends another 150 EGP
      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-2',
        userId: 'emp-1',
        amount: 150.0,
        categoryId: 'cat-2',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
        title: 'Lunch',
      ));

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.totalReceived, 1000.0);
      expect(summary.totalSpent, 350.0);
      expect(summary.availableBalance, 650.0);
    });

    test('3. Expense edit calculates difference and adjusts balance correctly', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1000.0);

      final exp = Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 200.0,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
        title: 'Initial Expense',
      );
      fakeBalanceRepo.expenses.add(exp);

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalance, 800.0);

      // Edit expense: 200 -> 300
      fakeBalanceRepo.expenses.removeWhere((e) => e.id == 'exp-1');
      fakeBalanceRepo.expenses.add(exp.copyWith(amount: 300.0));

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalance, 700.0); // 1000 - 300 = 700

      // Edit expense: 300 -> 150 (returns 150 to available balance)
      fakeBalanceRepo.expenses.removeWhere((e) => e.id == 'exp-1');
      fakeBalanceRepo.expenses.add(exp.copyWith(amount: 150.0));

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalance, 850.0); // 1000 - 150 = 850
    });

    test('4. Expense deletion restores available balance', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1000.0);

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 200.0,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      ));

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalance, 800.0);

      // Delete expense
      fakeBalanceRepo.expenses.removeWhere((e) => e.id == 'exp-1');

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalance, 1000.0);
    });

    test('5. FinancialHistoryItem correctly unifies and sorts credits and expenses', () async {
      final now = DateTime.now();
      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 1000.0,
        transactionDate: now.subtract(const Duration(days: 2)),
        note: 'Weekly allowance',
      );

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 200.0,
        categoryId: 'cat-1',
        expenseDate: now.subtract(const Duration(days: 1)),
        paymentMethod: 'cash',
        title: 'Fuel',
      ));

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-2',
        userId: 'emp-1',
        amount: 150.0,
        categoryId: 'cat-2',
        expenseDate: now,
        paymentMethod: 'cash',
        title: 'Lunch',
      ));

      final history = await fakeBalanceRepo.getFinancialHistory('emp-1');
      expect(history.length, 3);

      // Newest first
      expect(history[0].amount, 150.0);
      expect(history[0].itemType, FinancialItemType.expense);
      expect(history[0].isPositive, false);

      expect(history[1].amount, 200.0);
      expect(history[1].itemType, FinancialItemType.expense);

      expect(history[2].amount, 1000.0);
      expect(history[2].itemType, FinancialItemType.credit);
      expect(history[2].isPositive, true);
    });

    test('6. EmployeeBalanceCubit loads balance and history successfully', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1200.0);
      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 400.0,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      ));

      final cubit = EmployeeBalanceCubit(
        balanceRepository: fakeBalanceRepo,
        authRepository: fakeAuthRepo,
      );

      expect(cubit.state, isA<EmployeeBalanceInitial>());

      await cubit.loadBalance();

      expect(cubit.state, isA<EmployeeBalanceLoaded>());
      final loaded = cubit.state as EmployeeBalanceLoaded;
      expect(loaded.summary.totalReceived, 1200.0);
      expect(loaded.summary.totalSpent, 400.0);
      expect(loaded.summary.availableBalance, 800.0);
      expect(loaded.historyItems.length, 2);
    });

    test('7. AdminBalanceCubit loads all employee balances and adds balance', () async {
      final cubit = AdminBalanceCubit(balanceRepository: fakeBalanceRepo);

      expect(cubit.state, isA<AdminBalanceInitial>());

      await cubit.loadAllBalances();

      expect(cubit.state, isA<AdminBalanceLoaded>());
      var loaded = cubit.state as AdminBalanceLoaded;
      expect(loaded.employeeBalances.length, 1);

      // Admin gives 500 EGP
      await cubit.addBalance(
        userId: 'emp-1',
        amount: 500.0,
        note: 'Bonus allowance',
      );

      loaded = cubit.state as AdminBalanceLoaded;
      expect(loaded.selectedEmployeeSummary?.totalReceived, 500.0);
      expect(loaded.selectedEmployeeSummary?.availableBalance, 500.0);
    });
  });
}
