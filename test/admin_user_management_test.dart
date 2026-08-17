import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/repositories/expense_repository.dart';
import 'package:spendly/presentation/cubits/employee_details/employee_details_cubit.dart';
import 'package:spendly/presentation/cubits/employee_details/employee_details_state.dart';
import 'package:spendly/presentation/cubits/employees/employees_cubit.dart';
import 'package:spendly/presentation/cubits/employees/employees_state.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'dart:io';

class MockProfileRepository implements ProfileRepository {
  List<EmployeeSummary> mockSummaries = [];

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async {
    return mockSummaries;
  }

  @override
  Future<List<Profile>> getEmployees() async {
    return mockSummaries.map((s) => s.profile).toList();
  }

  @override
  Future<Profile?> getProfile(String userId) async {
    return mockSummaries
        .where((s) => s.profile.id == userId)
        .map((s) => s.profile)
        .firstOrNull;
  }

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
  Future<String> uploadAvatar(String userId, File imageFile) async => 'avatar_url';

  @override
  Future<void> deleteAvatar(String userId) async {}

  @override
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async {
    final newProfile = Profile(
      id: 'new_id',
      name: fullName,
      email: email,
      role: role,
      status: 'active',
    );
    mockSummaries.add(EmployeeSummary(profile: newProfile));
    return newProfile;
  }

  @override
  Future<void> deleteEmployee(String userId) async {
    mockSummaries.removeWhere((s) => s.profile.id == userId);
  }

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {
    final idx = mockSummaries.indexWhere((s) => s.profile.id == userId);
    if (idx != -1) {
      final old = mockSummaries[idx];
      mockSummaries[idx] = EmployeeSummary(
        profile: old.profile.copyWith(role: role),
        totalExpenses: old.totalExpenses,
        expensesCount: old.expensesCount,
      );
    }
  }

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) async {
    final idx = mockSummaries.indexWhere((s) => s.profile.id == userId);
    if (idx != -1) {
      final old = mockSummaries[idx];
      mockSummaries[idx] = EmployeeSummary(
        profile: old.profile.copyWith(status: status),
        totalExpenses: old.totalExpenses,
        expensesCount: old.expensesCount,
      );
    }
  }
}

class MockExpenseRepository implements ExpenseRepository {
  List<Expense> mockExpenses = [];

  @override
  Future<List<Expense>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    String? searchQuery,
  }) async {
    return mockExpenses.where((e) {
      if (userId != null && e.userId != userId) return false;
      if (categoryId != null && e.categoryId != categoryId) return false;
      if (paymentMethod != null && e.paymentMethod != paymentMethod) return false;
      if (startDate != null && e.expenseDate.isBefore(startDate)) return false;
      if (endDate != null && e.expenseDate.isAfter(endDate)) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (!e.title.toLowerCase().contains(searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    return mockExpenses.firstWhere((e) => e.id == id);
  }

  @override
  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteExpense(String id) async {
    mockExpenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId}) async {
    return mockExpenses;
  }
}

void main() {
  group('Admin User Management & Entity Tests', () {
    test('Profile entity correctly detects active/inactive status and roles', () {
      const activeEmployee = Profile(
        id: '1',
        name: 'Employee One',
        role: 'employee',
        status: 'active',
      );
      expect(activeEmployee.isEmployee, true);
      expect(activeEmployee.isAdmin, false);
      expect(activeEmployee.isActive, true);
      expect(activeEmployee.isInactive, false);

      const inactiveAdmin = Profile(
        id: '2',
        name: 'Admin Two',
        role: 'admin',
        status: 'inactive',
      );
      expect(inactiveAdmin.isAdmin, true);
      expect(inactiveAdmin.isEmployee, false);
      expect(inactiveAdmin.isActive, false);
      expect(inactiveAdmin.isInactive, true);
    });

    test('EmployeesCubit loads, searches, and filters employees accurately', () async {
      final mockRepo = MockProfileRepository();
      mockRepo.mockSummaries = [
        const EmployeeSummary(
          profile: Profile(
            id: '1',
            name: 'Ali Ahmed',
            email: 'ali@example.com',
            role: 'employee',
            status: 'active',
          ),
          totalExpenses: 1500.0,
          expensesCount: 3,
        ),
        const EmployeeSummary(
          profile: Profile(
            id: '2',
            name: 'Sara Omar',
            email: 'sara@example.com',
            role: 'admin',
            status: 'active',
          ),
          totalExpenses: 3000.0,
          expensesCount: 5,
        ),
        const EmployeeSummary(
          profile: Profile(
            id: '3',
            name: 'Khaled Hassan',
            email: 'khaled@example.com',
            role: 'employee',
            status: 'inactive',
          ),
          totalExpenses: 500.0,
          expensesCount: 1,
        ),
      ];

      final cubit = EmployeesCubit(profileRepository: mockRepo);

      // 1. Initial load
      await cubit.loadEmployees();
      expect(cubit.state, isA<EmployeesLoaded>());
      final loadedState = cubit.state as EmployeesLoaded;
      expect(loadedState.employees.length, 3);
      expect(loadedState.totalCompanySpent, 5000.0);
      expect(loadedState.totalCompanyTransactions, 9);

      // 2. Search
      cubit.searchEmployees('Sara');
      var currentState = cubit.state as EmployeesLoaded;
      expect(currentState.filteredEmployees.length, 1);
      expect(currentState.filteredEmployees.first.profile.name, 'Sara Omar');

      // Clear search
      cubit.searchEmployees('');
      currentState = cubit.state as EmployeesLoaded;
      expect(currentState.filteredEmployees.length, 3);

      // 3. Filter by role
      cubit.filterByRole('admin');
      currentState = cubit.state as EmployeesLoaded;
      expect(currentState.filteredEmployees.length, 1);
      expect(currentState.filteredEmployees.first.profile.role, 'admin');

      cubit.filterByRole(null);

      // 4. Filter by status
      cubit.filterByStatus('inactive');
      currentState = cubit.state as EmployeesLoaded;
      expect(currentState.filteredEmployees.length, 1);
      expect(currentState.filteredEmployees.first.profile.name, 'Khaled Hassan');

      // 5. Create employee
      await cubit.createEmployee(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        role: 'employee',
      );
      expect(mockRepo.mockSummaries.length, 4);

      // 6. Toggle status
      await cubit.toggleEmployeeStatus('3', 'active');
      expect(mockRepo.mockSummaries.firstWhere((s) => s.profile.id == '3').profile.status, 'active');

      // 7. Delete employee
      await cubit.deleteEmployee('3');
      expect(mockRepo.mockSummaries.any((s) => s.profile.id == '3'), false);
    });

    test('EmployeeDetailsCubit accurately computes employee statistics and handles filtering', () async {
      final mockProfileRepo = MockProfileRepository();
      final mockExpenseRepo = MockExpenseRepository();

      const employeeProfile = Profile(
        id: 'emp_123',
        name: 'Ahmed Mohamed',
        email: 'ahmed@company.com',
        role: 'employee',
        status: 'active',
      );

      mockProfileRepo.mockSummaries = [
        const EmployeeSummary(profile: employeeProfile),
      ];

      final now = DateTime.now();
      mockExpenseRepo.mockExpenses = [
        Expense(
          id: 'exp_1',
          userId: 'emp_123',
          categoryId: 'cat_food',
          category: const Category(id: 'cat_food', name: 'Food', icon: 'restaurant', color: '#E17055'),
          title: 'Team Lunch',
          amount: 250.0,
          paymentMethod: 'cash',
          expenseDate: now,
          createdAt: now,
        ),
        Expense(
          id: 'exp_2',
          userId: 'emp_123',
          categoryId: 'cat_travel',
          category: const Category(id: 'cat_travel', name: 'Travel', icon: 'flight', color: '#6C5CE7'),
          title: 'Taxi Ride',
          amount: 150.0,
          paymentMethod: 'credit_card',
          expenseDate: now,
          createdAt: now,
        ),
        Expense(
          id: 'exp_3',
          userId: 'emp_123',
          categoryId: 'cat_food',
          category: const Category(id: 'cat_food', name: 'Food', icon: 'restaurant', color: '#E17055'),
          title: 'Office Coffee',
          amount: 50.0,
          paymentMethod: 'cash',
          expenseDate: DateTime(now.year, now.month > 1 ? now.month - 1 : 12, 15),
          createdAt: now,
        ),
      ];

      final cubit = EmployeeDetailsCubit(
        expenseRepository: mockExpenseRepo,
        profileRepository: mockProfileRepo,
      );

      // Load details
      await cubit.loadEmployeeDetails('emp_123');
      expect(cubit.state, isA<EmployeeDetailsLoaded>());
      final loadedState = cubit.state as EmployeeDetailsLoaded;

      expect(loadedState.profile.name, 'Ahmed Mohamed');
      expect(loadedState.totalExpenses, 450.0);
      expect(loadedState.expensesCount, 3);
      expect(loadedState.thisMonthExpenses, 400.0);
      expect(loadedState.todayExpenses, 400.0);
      expect(loadedState.expenses.length, 3);

      // Search
      cubit.searchExpenses('Taxi');
      var filteredState = cubit.state as EmployeeDetailsLoaded;
      expect(filteredState.expenses.length, 1);
      expect(filteredState.expenses.first.title, 'Taxi Ride');

      // Filter by category
      cubit.resetFilters();
      cubit.filterByCategory('cat_food');
      filteredState = cubit.state as EmployeeDetailsLoaded;
      expect(filteredState.expenses.length, 2);

      // Filter by payment method
      cubit.resetFilters();
      cubit.filterByPaymentMethod('credit_card');
      filteredState = cubit.state as EmployeeDetailsLoaded;
      expect(filteredState.expenses.length, 1);
      expect(filteredState.expenses.first.paymentMethod, 'credit_card');

      // Reset
      cubit.resetFilters();
      filteredState = cubit.state as EmployeeDetailsLoaded;
      expect(filteredState.expenses.length, 3);
      expect(filteredState.hasActiveFilters, false);
    });
  });
}
