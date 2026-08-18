import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/domain/entities/balance_transaction.dart';
import 'package:spendly/domain/entities/employee_balance_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
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
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    final tx = BalanceTransaction(
      id: 'tx-${transactions.length + 1}',
      userId: userId,
      amount: amount,
      currency: currency,
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
    double totalReceivedEgp = 0.0;
    double totalReceivedUsd = 0.0;

    for (final tx in transactions.where((t) => t.userId == userId)) {
      final isAdd = tx.type == BalanceTransactionType.credit || tx.type == BalanceTransactionType.adjustmentAdd;
      final isSub = tx.type == BalanceTransactionType.adjustmentSub;

      if (tx.currency == ExpenseCurrency.usd) {
        if (isAdd) totalReceivedUsd += tx.amount;
        if (isSub) totalReceivedUsd -= tx.amount;
      } else {
        if (isAdd) totalReceivedEgp += tx.amount;
        if (isSub) totalReceivedEgp -= tx.amount;
      }
    }

    double totalSpentEgp = 0.0;
    double totalSpentUsd = 0.0;

    for (final exp in expenses.where((e) => e.userId == userId)) {
      if (exp.currency == ExpenseCurrency.usd) {
        totalSpentUsd += exp.amount;
      } else {
        totalSpentEgp += exp.amount;
      }
    }

    return EmployeeBalanceSummary(
      userId: userId,
      name: 'Ahmed Mohamed',
      email: 'ahmed@company.com',
      totalReceivedEgp: totalReceivedEgp,
      totalSpentEgp: totalSpentEgp,
      availableBalanceEgp: totalReceivedEgp - totalSpentEgp,
      totalReceivedUsd: totalReceivedUsd,
      totalSpentUsd: totalSpentUsd,
      availableBalanceUsd: totalReceivedUsd - totalSpentUsd,
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
  group('Multi-Currency Employee Allowance & Balance System Tests', () {
    late FakeBalanceRepository fakeBalanceRepo;
    late FakeAuthRepository fakeAuthRepo;

    setUp(() {
      fakeBalanceRepo = FakeBalanceRepository();
      fakeAuthRepo = FakeAuthRepository();
    });

    test('1. Independent Multi-Currency Balances: Adding EGP and USD balances never mix', () async {
      // 1. Initial balances should be 0 for both currencies
      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceEgp, 0.0);
      expect(summary.availableBalanceUsd, 0.0);

      // 2. Admin gives 1000 EGP and 500 USD
      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 1000.0,
        currency: ExpenseCurrency.egp,
        note: 'Office allowance',
      );

      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 500.0,
        currency: ExpenseCurrency.usd,
        note: 'Student travel allowance',
      );

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.totalReceivedEgp, 1000.0);
      expect(summary.availableBalanceEgp, 1000.0);
      expect(summary.totalReceivedUsd, 500.0);
      expect(summary.availableBalanceUsd, 500.0);
    });

    test('2. Expenses deduct only from corresponding currency balance', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1000.0, currency: ExpenseCurrency.egp);
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 500.0, currency: ExpenseCurrency.usd);

      // Employee spends 200 EGP
      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 200.0,
        currency: ExpenseCurrency.egp,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
        title: 'Transportation',
      ));

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceEgp, 800.0); // 1000 - 200
      expect(summary.availableBalanceUsd, 500.0); // USD unaffected!

      // Employee spends 100 USD
      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-2',
        userId: 'emp-1',
        amount: 100.0,
        currency: ExpenseCurrency.usd,
        categoryId: 'cat-2',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
        title: 'Student Visa Fee',
      ));

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceEgp, 800.0); // EGP unaffected!
      expect(summary.availableBalanceUsd, 400.0); // 500 - 100
    });

    test('3. Expense currency helper functions format and parse correctly', () {
      expect(ExpenseCurrency.fromString('EGP'), ExpenseCurrency.egp);
      expect(ExpenseCurrency.fromString('USD'), ExpenseCurrency.usd);
      expect(ExpenseCurrency.fromString('invalid'), ExpenseCurrency.egp);

      expect(ExpenseCurrency.egp.toDbString(), 'EGP');
      expect(ExpenseCurrency.usd.toDbString(), 'USD');

      expect(ExpenseCurrency.egp.symbolForLocale('ar'), 'ج.م');
      expect(ExpenseCurrency.usd.symbolForLocale('ar'), '\$');
      expect(ExpenseCurrency.egp.symbolForLocale('en'), 'EGP');
      expect(ExpenseCurrency.usd.symbolForLocale('en'), 'USD');
    });

    test('4. Expense editing recalculates difference strictly within that currency', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 500.0, currency: ExpenseCurrency.usd);

      final exp = Expense(
        id: 'exp-usd-1',
        userId: 'emp-1',
        amount: 100.0,
        currency: ExpenseCurrency.usd,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      );
      fakeBalanceRepo.expenses.add(exp);

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceUsd, 400.0);

      // Edit USD expense: 100 -> 250
      fakeBalanceRepo.expenses.removeWhere((e) => e.id == 'exp-usd-1');
      fakeBalanceRepo.expenses.add(exp.copyWith(amount: 250.0));

      summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceUsd, 250.0); // 500 - 250 = 250
    });

    test('5. Expense deletion restores available balance in the correct currency', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1000.0, currency: ExpenseCurrency.egp);
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 500.0, currency: ExpenseCurrency.usd);

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-egp',
        userId: 'emp-1',
        amount: 300.0,
        currency: ExpenseCurrency.egp,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      ));

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-usd',
        userId: 'emp-1',
        amount: 150.0,
        currency: ExpenseCurrency.usd,
        categoryId: 'cat-2',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      ));

      // Delete USD expense
      fakeBalanceRepo.expenses.removeWhere((e) => e.id == 'exp-usd');

      var summary = await fakeBalanceRepo.getEmployeeBalanceSummary('emp-1');
      expect(summary.availableBalanceEgp, 700.0); // EGP remains 700
      expect(summary.availableBalanceUsd, 500.0); // USD restored to 500
    });

    test('6. FinancialHistoryItem preserves currency code and properties', () async {
      final now = DateTime.now();
      await fakeBalanceRepo.addBalance(
        userId: 'emp-1',
        amount: 300.0,
        currency: ExpenseCurrency.usd,
        transactionDate: now,
      );

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 150.0,
        currency: ExpenseCurrency.usd,
        categoryId: 'cat-1',
        expenseDate: now,
        paymentMethod: 'cash',
        title: 'Student Exam Fee',
      ));

      final history = await fakeBalanceRepo.getFinancialHistory('emp-1');
      expect(history.length, 2);
      expect(history[0].currency, ExpenseCurrency.usd);
      expect(history[1].currency, ExpenseCurrency.usd);
    });

    test('7. EmployeeBalanceCubit loads multi-currency balance successfully', () async {
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 1500.0, currency: ExpenseCurrency.egp);
      await fakeBalanceRepo.addBalance(userId: 'emp-1', amount: 800.0, currency: ExpenseCurrency.usd);

      fakeBalanceRepo.expenses.add(Expense(
        id: 'exp-1',
        userId: 'emp-1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        categoryId: 'cat-1',
        expenseDate: DateTime.now(),
        paymentMethod: 'cash',
      ));

      final cubit = EmployeeBalanceCubit(
        balanceRepository: fakeBalanceRepo,
        authRepository: fakeAuthRepo,
      );

      await cubit.loadBalance();

      expect(cubit.state, isA<EmployeeBalanceLoaded>());
      final loaded = cubit.state as EmployeeBalanceLoaded;
      expect(loaded.summary.availableBalanceEgp, 1000.0);
      expect(loaded.summary.availableBalanceUsd, 800.0);
      expect(loaded.summary.availableBalanceFor(ExpenseCurrency.egp), 1000.0);
      expect(loaded.summary.availableBalanceFor(ExpenseCurrency.usd), 800.0);
    });

    test('8. AdminBalanceCubit adds currency-specific balance', () async {
      final cubit = AdminBalanceCubit(balanceRepository: fakeBalanceRepo);

      await cubit.loadAllBalances();
      expect(cubit.state, isA<AdminBalanceLoaded>());

      // Add USD balance
      await cubit.addBalance(
        userId: 'emp-1',
        amount: 750.0,
        currency: ExpenseCurrency.usd,
        note: 'Student travel funds',
      );

      final loaded = cubit.state as AdminBalanceLoaded;
      expect(loaded.selectedEmployeeSummary?.totalReceivedUsd, 750.0);
      expect(loaded.selectedEmployeeSummary?.availableBalanceUsd, 750.0);
      expect(loaded.selectedEmployeeSummary?.availableBalanceEgp, 0.0);
    });
  });
}
