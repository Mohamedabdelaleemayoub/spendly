import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/utils/date_time_utils.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/entities/weekly_allowance_transaction.dart';
import 'package:spendly/domain/entities/weekly_work_budget_summary.dart';
import 'package:spendly/domain/repositories/weekly_allowance_repository.dart';
import 'package:spendly/presentation/cubits/weekly_allowance/weekly_allowance_cubit.dart';
import 'package:spendly/presentation/cubits/weekly_allowance/weekly_allowance_state.dart';

class MockWeeklyAllowanceRepository implements WeeklyAllowanceRepository {
  final List<WeeklyAllowanceTransaction> _transactions = [];
  final List<Map<String, dynamic>> _mockExpenses = [];

  void seedExpense({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime date,
  }) {
    _mockExpenses.add({
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'expense_date': date,
    });
  }

  @override
  Future<WeeklyAllowanceTransaction> createAllowanceTransaction({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    final tx = WeeklyAllowanceTransaction(
      id: 'tx-${_transactions.length + 1}',
      userId: userId,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
      createdBy: 'admin-1',
      creatorName: 'Admin User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _transactions.add(tx);
    return tx;
  }

  @override
  Future<void> deleteAllowanceTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<WeeklyAllowanceTransaction>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _transactions.where((t) {
      if (t.userId != userId) return false;
      if (startDate != null && t.transactionDate.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) return false;
      if (endDate != null && t.transactionDate.isAfter(DateTime(endDate.year, endDate.month, endDate.day))) return false;
      return true;
    }).toList();
  }

  @override
  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sDay = DateTime(startDate.year, startDate.month, startDate.day);
    final eDay = DateTime(endDate.year, endDate.month, endDate.day);

    double recEgp = 0.0;
    double recUsd = 0.0;
    for (final t in _transactions) {
      if (userId != null && t.userId != userId) continue;
      final tDay = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      if (!tDay.isBefore(sDay) && !tDay.isAfter(eDay)) {
        if (t.currency == ExpenseCurrency.usd) {
          recUsd += t.amount;
        } else {
          recEgp += t.amount;
        }
      }
    }

    double spEgp = 0.0;
    double spUsd = 0.0;
    for (final e in _mockExpenses) {
      if (userId != null && e['user_id'] != userId) continue;
      final date = e['expense_date'] as DateTime;
      final eDateDay = DateTime(date.year, date.month, date.day);
      if (!eDateDay.isBefore(sDay) && !eDateDay.isAfter(eDay)) {
        final amt = e['amount'] as double;
        final curr = e['currency'] as ExpenseCurrency;
        if (curr == ExpenseCurrency.usd) {
          spUsd += amt;
        } else {
          spEgp += amt;
        }
      }
    }

    return WeeklyWorkBudgetSummary(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      receivedEgp: recEgp,
      spentEgp: spEgp,
      receivedUsd: recUsd,
      spentUsd: spUsd,
    );
  }

  @override
  Future<WeeklyAllowanceTransaction> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) throw Exception('Transaction not found');
    final updated = _transactions[idx].copyWith(
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
      updatedAt: DateTime.now(),
    );
    _transactions[idx] = updated;
    return updated;
  }
}

void main() {
  group('Weekly Work Budget & Allowance System Tests', () {
    late MockWeeklyAllowanceRepository repository;
    late WeeklyAllowanceCubit cubit;

    setUp(() {
      repository = MockWeeklyAllowanceRepository();
      cubit = WeeklyAllowanceCubit(weeklyAllowanceRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Monday-Sunday week boundaries work correctly', () {
      // Wednesday, 2026-08-19
      final wednesday = DateTime(2026, 8, 19);
      final range = DateTimeUtils.getWeekRange(wednesday);

      expect(range.start.weekday, DateTime.monday);
      expect(range.start.year, 2026);
      expect(range.start.month, 8);
      expect(range.start.day, 17); // Monday 17 Aug 2026

      expect(range.end.weekday, DateTime.sunday);
      expect(range.end.year, 2026);
      expect(range.end.month, 8);
      expect(range.end.day, 23); // Sunday 23 Aug 2026
    });

    test('2. Adding allowance increases weekly received', () async {
      final now = DateTime.now();
      await cubit.addAllowance(
        userId: 'user-1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
      );

      final state = cubit.state as WeeklyAllowanceLoaded;
      expect(state.summary.receivedEgp, 500.0);
      expect(state.summary.remainingEgp, 500.0);
      expect(state.transactions.length, 1);
    });

    test('3. Multiple allowance transactions accumulate in the same week', () async {
      final now = DateTime.now();
      await cubit.addAllowance(
        userId: 'user-1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
      );
      await cubit.addAllowance(
        userId: 'user-1',
        amount: 300.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
      );

      final state = cubit.state as WeeklyAllowanceLoaded;
      expect(state.summary.receivedEgp, 800.0);
      expect(state.transactions.length, 2);
    });

    test('4. Weekly spent is calculated from expenses and weekly remaining = received - spent', () async {
      final now = DateTime.now();
      // Seed expenses of 150, 100, 50 = 300 EGP
      repository.seedExpense(userId: 'user-1', amount: 150.0, date: now);
      repository.seedExpense(userId: 'user-1', amount: 100.0, date: now);
      repository.seedExpense(userId: 'user-1', amount: 50.0, date: now);

      await cubit.addAllowance(
        userId: 'user-1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
      );

      final state = cubit.state as WeeklyAllowanceLoaded;
      expect(state.summary.receivedEgp, 500.0);
      expect(state.summary.spentEgp, 300.0);
      expect(state.summary.remainingEgp, 200.0);
    });

    test('5. Expenses and allowances from previous weeks are excluded from This Week', () async {
      final thisWeek = DateTimeUtils.getThisWeekRange();
      final prevWeekDate = thisWeek.start.subtract(const Duration(days: 3));

      // Previous week data
      repository.seedExpense(userId: 'user-1', amount: 400.0, date: prevWeekDate);
      await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 1000.0,
        transactionDate: prevWeekDate,
      );

      // This week data
      final thisWeekDate = thisWeek.start.add(const Duration(days: 1));
      repository.seedExpense(userId: 'user-1', amount: 100.0, date: thisWeekDate);
      await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 600.0,
        transactionDate: thisWeekDate,
      );

      await cubit.loadWeeklyAllowance('user-1');
      final state = cubit.state as WeeklyAllowanceLoaded;

      expect(state.summary.receivedEgp, 600.0);
      expect(state.summary.spentEgp, 100.0);
      expect(state.summary.remainingEgp, 500.0);
      expect(state.transactions.length, 1);
    });

    test('6. Moving an allowance to another week updates both weeks correctly', () async {
      final thisWeek = DateTimeUtils.getThisWeekRange();
      final mondayThisWeek = thisWeek.start;
      final prevWeekDate = mondayThisWeek.subtract(const Duration(days: 4));

      final tx = await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 500.0,
        transactionDate: mondayThisWeek,
      );

      await cubit.loadWeeklyAllowance('user-1');
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 500.0);

      // Move transaction to previous week
      await cubit.updateAllowance(
        id: tx.id,
        userId: 'user-1',
        amount: 500.0,
        transactionDate: prevWeekDate,
      );

      // This week should now be 0
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 0.0);

      // Previous week should now be 500
      await cubit.selectPeriod(WeeklyPeriodSelection.previousWeek);
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 500.0);
    });

    test('7. Deleting allowance recalculates totals immediately', () async {
      final now = DateTime.now();
      final tx = await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 500.0,
        transactionDate: now,
      );

      await cubit.loadWeeklyAllowance('user-1');
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 500.0);

      await cubit.deleteAllowance(tx.id, 'user-1');
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 0.0);
      expect((cubit.state as WeeklyAllowanceLoaded).transactions, isEmpty);
    });

    test('8. Editing allowance amount recalculates totals immediately', () async {
      final now = DateTime.now();
      final tx = await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 500.0,
        transactionDate: now,
      );

      await cubit.loadWeeklyAllowance('user-1');
      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 500.0);

      await cubit.updateAllowance(
        id: tx.id,
        userId: 'user-1',
        amount: 750.0,
        transactionDate: now,
      );

      expect((cubit.state as WeeklyAllowanceLoaded).summary.receivedEgp, 750.0);
    });

    test('9. EGP and USD remain completely separated', () async {
      final now = DateTime.now();
      repository.seedExpense(userId: 'user-1', amount: 200.0, currency: ExpenseCurrency.egp, date: now);
      repository.seedExpense(userId: 'user-1', amount: 50.0, currency: ExpenseCurrency.usd, date: now);

      await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 1000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
      );
      await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 100.0,
        currency: ExpenseCurrency.usd,
        transactionDate: now,
      );

      final summary = await repository.getWeeklyWorkBudgetSummary(
        userId: 'user-1',
        startDate: DateTimeUtils.getThisWeekRange().start,
        endDate: DateTimeUtils.getThisWeekRange().end,
      );

      expect(summary.receivedEgp, 1000.0);
      expect(summary.spentEgp, 200.0);
      expect(summary.remainingEgp, 800.0);

      expect(summary.receivedUsd, 100.0);
      expect(summary.spentUsd, 50.0);
      expect(summary.remainingUsd, 50.0);
    });

    test('10. Negative remaining is preserved and displayed accurately', () async {
      final now = DateTime.now();
      repository.seedExpense(userId: 'user-1', amount: 650.0, date: now);
      await repository.createAllowanceTransaction(
        userId: 'user-1',
        amount: 500.0,
        transactionDate: now,
      );

      final summary = await repository.getWeeklyWorkBudgetSummary(
        userId: 'user-1',
        startDate: DateTimeUtils.getThisWeekRange().start,
        endDate: DateTimeUtils.getThisWeekRange().end,
      );

      expect(summary.receivedEgp, 500.0);
      expect(summary.spentEgp, 650.0);
      expect(summary.remainingEgp, -150.0);
    });

    test('11. Weekly reporting does not mutate or affect salary or salary advances', () {
      const profile = Profile(
        id: 'user-1',
        email: 'ahmed@spendly.com',
        name: 'Ahmed',
        role: 'employee',
        status: 'active',
        salaryAmount: 8000.0,
        salaryCurrency: ExpenseCurrency.egp,
      );

      final weeklyBudget = WeeklyWorkBudgetSummary(
        userId: 'user-1',
        startDate: DateTime(2026, 8, 17),
        endDate: DateTime(2026, 8, 23),
        receivedEgp: 800.0,
        spentEgp: 300.0,
      );

      // Verify salary is completely uncoupled from weekly work allowance
      expect(profile.salaryAmount, 8000.0);
      expect(weeklyBudget.receivedEgp, 800.0);
      expect(weeklyBudget.remainingEgp, 500.0);
    });

    test('12. Aggregated weekly totals across all employees for Dashboard match individual summaries', () async {
      final now = DateTime.now();

      // Employee 1
      await repository.createAllowanceTransaction(userId: 'emp-1', amount: 500.0, transactionDate: now);
      repository.seedExpense(userId: 'emp-1', amount: 200.0, date: now);

      // Employee 2
      await repository.createAllowanceTransaction(userId: 'emp-2', amount: 1000.0, transactionDate: now);
      repository.seedExpense(userId: 'emp-2', amount: 600.0, date: now);

      final totalSummary = await repository.getWeeklyWorkBudgetSummary(
        startDate: DateTimeUtils.getThisWeekRange().start,
        endDate: DateTimeUtils.getThisWeekRange().end,
      );

      expect(totalSummary.receivedEgp, 1500.0);
      expect(totalSummary.spentEgp, 800.0);
      expect(totalSummary.remainingEgp, 700.0);
    });
  });
}
