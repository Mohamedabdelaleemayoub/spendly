import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/employee_balance_summary.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/financial_history_item.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/domain/repositories/balance_repository.dart';
import 'package:spendly/presentation/cubits/employees/employees_cubit.dart';
import 'package:spendly/presentation/cubits/employees/employees_state.dart';
import 'package:spendly/presentation/cubits/balance/admin_balance_cubit.dart';
import 'package:spendly/presentation/cubits/balance/admin_balance_state.dart';
import 'package:spendly/domain/entities/balance_transaction.dart';

class MockProfileRepository implements ProfileRepository {
  final List<EmployeeSummary> employees = [
    const EmployeeSummary(
      profile: Profile(
        id: 'emp-1',
        name: 'أحمد محمود',
        email: 'ahmed@company.com',
        role: 'employee',
        status: 'active',
        salaryAmount: 8000.0,
        salaryCurrency: ExpenseCurrency.egp,
      ),
      totalExpenses: 2500.0,
      expensesCount: 5,
      totalAdvances: 1000.0,
      weeklyReceivedEgp: 1500.0,
      weeklySpentEgp: 800.0,
    ),
    const EmployeeSummary(
      profile: Profile(
        id: 'emp-2',
        name: 'سارة علي',
        email: 'sara@company.com',
        role: 'employee',
        status: 'active',
        salaryAmount: 10000.0,
        salaryCurrency: ExpenseCurrency.egp,
      ),
      totalExpenses: 4200.0,
      expensesCount: 8,
      totalAdvances: 0.0,
      weeklyReceivedEgp: 2000.0,
      weeklySpentEgp: 1200.0,
    ),
  ];

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async => employees;

  @override
  Future<List<Profile>> getEmployees() async => employees.map((e) => e.profile).toList();

  @override
  Future<Profile?> getProfile(String userId) async =>
      employees.firstWhere((e) => e.profile.id == userId).profile;

  @override
  Future<Profile> updateProfile(Profile profile) async => profile;

  @override
  Future<Profile> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  }) async {
    return Profile(id: userId, name: name, email: email);
  }

  @override
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async {
    return Profile(id: 'new-emp', name: fullName, email: email, role: role);
  }

  @override
  Future<void> deleteEmployee(String userId) async {}

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {}

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) async {}

  @override
  Future<void> approveUser(String userId) async {}

  @override
  Future<void> rejectUser(String userId) async {}

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async => 'url';

  @override
  Future<void> deleteAvatar(String userId) async {}
}

class MockBalanceRepository implements BalanceRepository {
  final List<EmployeeBalanceSummary> summaries = [
    const EmployeeBalanceSummary(
      userId: 'emp-1',
      name: 'أحمد محمود',
      email: 'ahmed@company.com',
      role: 'employee',
      status: 'active',
      totalReceivedEgp: 5000.0,
      totalSpentEgp: 2500.0,
      availableBalanceEgp: 2500.0,
      totalReceivedUsd: 200.0,
      totalSpentUsd: 50.0,
      availableBalanceUsd: 150.0,
    ),
    const EmployeeBalanceSummary(
      userId: 'emp-2',
      name: 'سارة علي',
      email: 'sara@company.com',
      role: 'employee',
      status: 'active',
      totalReceivedEgp: 8000.0,
      totalSpentEgp: 4200.0,
      availableBalanceEgp: 3800.0,
      totalReceivedUsd: 0.0,
      totalSpentUsd: 0.0,
      availableBalanceUsd: 0.0,
    ),
  ];

  @override
  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances() async => summaries;

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async =>
      summaries.firstWhere((s) => s.userId == userId);

  @override
  Future<List<BalanceTransaction>> getBalanceTransactions(String userId) async => [];

  @override
  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId) async => [];

  @override
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    return BalanceTransaction(
      id: 'tx-new',
      userId: userId,
      amount: amount,
      currency: currency,
      type: BalanceTransactionType.credit,
      transactionDate: transactionDate ?? DateTime.now(),
      note: note,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('Employees Page & Multi-Currency Balance Resilience Tests', () {
    late MockProfileRepository mockProfileRepo;
    late MockBalanceRepository mockBalanceRepo;
    late EmployeesCubit employeesCubit;
    late AdminBalanceCubit adminBalanceCubit;

    setUp(() {
      mockProfileRepo = MockProfileRepository();
      mockBalanceRepo = MockBalanceRepository();
      employeesCubit = EmployeesCubit(profileRepository: mockProfileRepo);
      adminBalanceCubit = AdminBalanceCubit(balanceRepository: mockBalanceRepo);
    });

    tearDown(() {
      employeesCubit.close();
      adminBalanceCubit.close();
    });

    test('1. EmployeesCubit loads employees and calculates company statistics correctly', () async {
      expect(employeesCubit.state, isA<EmployeesInitial>());

      await employeesCubit.loadEmployees();

      expect(employeesCubit.state, isA<EmployeesLoaded>());
      final loaded = employeesCubit.state as EmployeesLoaded;

      expect(loaded.employees.length, equals(2));
      expect(loaded.totalCompanySpent, equals(6700.0)); // 2500 + 4200
      expect(loaded.totalCompanyTransactions, equals(13)); // 5 + 8
    });

    test('2. EmployeesCubit correctly filters employees by search, role, and status', () async {
      await employeesCubit.loadEmployees();

      // Search by name
      employeesCubit.searchEmployees('أحمد');
      var loaded = employeesCubit.state as EmployeesLoaded;
      expect(loaded.filteredEmployees.length, equals(1));
      expect(loaded.filteredEmployees.first.profile.name, equals('أحمد محمود'));

      // Clear search
      employeesCubit.searchEmployees('');
      loaded = employeesCubit.state as EmployeesLoaded;
      expect(loaded.filteredEmployees.length, equals(2));

      // Filter by role
      employeesCubit.filterByRole('employee');
      loaded = employeesCubit.state as EmployeesLoaded;
      expect(loaded.filteredEmployees.length, equals(2));

      // Filter by status
      employeesCubit.filterByStatus('active');
      loaded = employeesCubit.state as EmployeesLoaded;
      expect(loaded.filteredEmployees.length, equals(2));
    });

    test('3. AdminBalanceCubit loads all employee balances and preserves EGP and USD separation', () async {
      expect(adminBalanceCubit.state, isA<AdminBalanceInitial>());

      await adminBalanceCubit.loadAllBalances();

      expect(adminBalanceCubit.state, isA<AdminBalanceLoaded>());
      final loaded = adminBalanceCubit.state as AdminBalanceLoaded;

      expect(loaded.employeeBalances.length, equals(2));

      final emp1 = loaded.employeeBalances.firstWhere((e) => e.userId == 'emp-1');
      expect(emp1.availableBalanceEgp, equals(2500.0));
      expect(emp1.availableBalanceUsd, equals(150.0));
      expect(emp1.totalReceivedEgp, equals(5000.0));
      expect(emp1.totalReceivedUsd, equals(200.0));
    });

    test('4. EmployeeSummary calculates weekly remaining and salary remaining accurately', () {
      final emp1 = mockProfileRepo.employees[0];

      // Weekly allowance calculations
      expect(emp1.weeklyReceivedEgp, equals(1500.0));
      expect(emp1.weeklySpentEgp, equals(800.0));
      expect(emp1.weeklyRemainingEgp, equals(700.0));

      // Salary advance calculations
      expect(emp1.profile.salaryAmount, equals(8000.0));
      expect(emp1.totalAdvances, equals(1000.0));
      expect(emp1.remainingSalary, equals(7000.0));
    });

    test('5. AdminBalanceCubit successfully adds currency-specific balance', () async {
      await adminBalanceCubit.loadAllBalances();

      await adminBalanceCubit.addBalance(
        userId: 'emp-1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        note: 'عهدة أسبوعية إضافية',
      );

      expect(adminBalanceCubit.state, isA<AdminBalanceLoaded>());
    });
  });
}
