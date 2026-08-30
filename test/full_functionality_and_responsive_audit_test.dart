import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/domain/entities/employee_balance_summary.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/governorate.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/entities/trip_location_type.dart';
import 'package:spendly/domain/repositories/auth_repository.dart';
import 'package:spendly/domain/repositories/balance_repository.dart';
import 'package:spendly/domain/repositories/category_repository.dart';
import 'package:spendly/domain/repositories/expense_repository.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/l10n/app_localizations.dart';
import 'package:spendly/presentation/cubits/balance/employee_balance_cubit.dart';
import 'package:spendly/presentation/cubits/category/category_cubit.dart';
import 'package:spendly/presentation/cubits/employees/employees_cubit.dart';
import 'package:spendly/presentation/cubits/employees/employees_state.dart';
import 'package:spendly/presentation/cubits/expense/expense_cubit.dart';
import 'package:spendly/presentation/cubits/expense/expense_state.dart';
import 'package:spendly/presentation/pages/expenses/add_expense_page.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBalanceRepository extends Mock implements BalanceRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(ExpenseCurrency.egp);
    registerFallbackValue(TripLocationType.cairo);
    registerFallbackValue(Governorate.cairo);
  });

  group('1. Employee Expense Editing Verification', () {
    late MockExpenseRepository mockExpenseRepository;
    late MockCategoryRepository mockCategoryRepository;
    late MockBalanceRepository mockBalanceRepository;
    late MockAuthRepository mockAuthRepository;
    late ExpenseCubit expenseCubit;
    late CategoryCubit categoryCubit;
    late EmployeeBalanceCubit balanceCubit;

    final testCategory = const Category(
      id: 'cat-food',
      name: 'طعام ومشروبات',
      icon: 'restaurant',
      color: '#FF7675',
    );

    final existingExpense = Expense(
      id: 'exp-edit-123',
      userId: 'user-001',
      title: 'Original Lunch Expense',
      amount: 250.0,
      currency: ExpenseCurrency.egp,
      tripLocationType: TripLocationType.cairo,
      governorate: Governorate.cairo,
      paymentMethod: 'cash',
      expenseDate: DateTime(2026, 8, 20),
      notes: 'Initial meeting lunch',
      category: testCategory,
    );

    setUp(() {
      mockExpenseRepository = MockExpenseRepository();
      mockCategoryRepository = MockCategoryRepository();
      mockBalanceRepository = MockBalanceRepository();
      mockAuthRepository = MockAuthRepository();

      when(() => mockCategoryRepository.getCategories())
          .thenAnswer((_) async => [testCategory]);
      when(() => mockAuthRepository.currentUser).thenReturn(
        const User(
          id: 'user-001',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        ),
      );
      when(() => mockBalanceRepository.getEmployeeBalanceSummary(any()))
          .thenAnswer(
            (_) async => const EmployeeBalanceSummary(
              userId: 'user-001',
              name: 'Test User',
              email: 'test@edu.eg',
              totalReceivedEgp: 1000,
              totalSpentEgp: 250,
              availableBalanceEgp: 750,
              totalReceivedUsd: 0,
              totalSpentUsd: 0,
              availableBalanceUsd: 0,
            ),
          );

      expenseCubit = ExpenseCubit(expenseRepository: mockExpenseRepository);
      categoryCubit = CategoryCubit(categoryRepository: mockCategoryRepository);
      balanceCubit = EmployeeBalanceCubit(
        balanceRepository: mockBalanceRepository,
        authRepository: mockAuthRepository,
      );
    });

    test('updateExpense preserves existing expense ID and does NOT duplicate records', () async {
      when(
        () => mockExpenseRepository.updateExpense(
          id: 'exp-edit-123',
          title: any(named: 'title'),
          amount: 320.0,
          currency: ExpenseCurrency.egp,
          tripLocationType: TripLocationType.cairo,
          governorate: Governorate.cairo,
          paymentMethod: any(named: 'paymentMethod'),
          expenseDate: any(named: 'expenseDate'),
          categoryId: any(named: 'categoryId'),
          notes: any(named: 'notes'),
          receiptFile: any(named: 'receiptFile'),
          existingReceiptUrl: any(named: 'existingReceiptUrl'),
        ),
      ).thenAnswer(
        (_) async => existingExpense.copyWith(
          amount: 320.0,
          notes: 'Updated meeting lunch',
        ),
      );

      final result = await expenseCubit.updateExpense(
        id: 'exp-edit-123',
        title: 'Original Lunch Expense',
        amount: 320.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: DateTime(2026, 8, 20),
        notes: 'Updated meeting lunch',
      );

      expect(result, isTrue);
      final loaded = expenseCubit.state as ExpenseLoaded;
      expect(loaded.expenses.length, 1);
      expect(loaded.expenses.first.id, 'exp-edit-123');
      expect(loaded.expenses.first.amount, 320.0);
      expect(loaded.expenses.first.notes, 'Updated meeting lunch');

      // Verify updateExpense was called, NOT createExpense
      verify(
        () => mockExpenseRepository.updateExpense(
          id: 'exp-edit-123',
          title: any(named: 'title'),
          amount: 320.0,
          currency: any(named: 'currency'),
          tripLocationType: any(named: 'tripLocationType'),
          governorate: any(named: 'governorate'),
          paymentMethod: any(named: 'paymentMethod'),
          expenseDate: any(named: 'expenseDate'),
          categoryId: any(named: 'categoryId'),
          notes: any(named: 'notes'),
          receiptFile: any(named: 'receiptFile'),
          existingReceiptUrl: any(named: 'existingReceiptUrl'),
        ),
      ).called(1);
      verifyNever(
        () => mockExpenseRepository.createExpense(
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
        ),
      );
    });

    testWidgets(
      'AddExpensePage opens in Edit mode and populates existing values',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await categoryCubit.loadCategories();
        await balanceCubit.loadBalance();

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            theme: AppTheme.light,
            home: AddExpensePage(
              initialExpense: existingExpense,
              expenseCubit: expenseCubit,
              categoryCubit: categoryCubit,
              balanceCubit: balanceCubit,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Form should be populated with existing values
        expect(find.text('250.00'), findsOneWidget);
        expect(find.text('Initial meeting lunch'), findsOneWidget);
        expect(find.text('تعديل المصروف'), findsWidgets);
      },
    );
  });

  group('2. Admin – Add, Delete & Search Employees Verification', () {
    late MockProfileRepository mockProfileRepository;
    late EmployeesCubit employeesCubit;

    final mockEmp1 = EmployeeSummary(
      profile: Profile(
        id: 'emp-001',
        email: 'ahmed.aly@edu.eg',
        name: 'Ahmed Aly',
        role: 'employee',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      ),
      totalExpenses: 1500.0,
      expensesCount: 4,
    );

    final mockEmp2 = EmployeeSummary(
      profile: Profile(
        id: 'emp-002',
        email: 'sara.hassan@edu.eg',
        name: 'Sara Hassan',
        role: 'admin',
        status: 'active',
        createdAt: DateTime(2026, 2, 1),
      ),
      totalExpenses: 4200.0,
      expensesCount: 10,
    );

    setUp(() {
      mockProfileRepository = MockProfileRepository();
      employeesCubit = EmployeesCubit(profileRepository: mockProfileRepository);
    });

    test(
      'searchEmployees filters by name, email, and ID with case insensitivity',
      () async {
        when(() => mockProfileRepository.getEmployeesWithStats())
            .thenAnswer((_) async => [mockEmp1, mockEmp2]);

        await employeesCubit.loadEmployees();
        expect(
          (employeesCubit.state as EmployeesLoaded).filteredEmployees.length,
          2,
        );

        // Search by partial name lowercase
        employeesCubit.searchEmployees('ahmed');
        expect(
          (employeesCubit.state as EmployeesLoaded).filteredEmployees.length,
          1,
        );
        expect(
          (employeesCubit.state as EmployeesLoaded)
              .filteredEmployees
              .first
              .profile
              .name,
          'Ahmed Aly',
        );

        // Search by partial email
        employeesCubit.searchEmployees('sara.hassan');
        expect(
          (employeesCubit.state as EmployeesLoaded).filteredEmployees.length,
          1,
        );
        expect(
          (employeesCubit.state as EmployeesLoaded)
              .filteredEmployees
              .first
              .profile
              .name,
          'Sara Hassan',
        );

        // Search by ID
        employeesCubit.searchEmployees('emp-001');
        expect(
          (employeesCubit.state as EmployeesLoaded).filteredEmployees.length,
          1,
        );
        expect(
          (employeesCubit.state as EmployeesLoaded)
              .filteredEmployees
              .first
              .profile
              .name,
          'Ahmed Aly',
        );

        // Clear search restores full list
        employeesCubit.searchEmployees('');
        expect(
          (employeesCubit.state as EmployeesLoaded).filteredEmployees.length,
          2,
        );
      },
    );

    test(
      'createEmployee executes repository call and reloads employee list',
      () async {
        when(
          () => mockProfileRepository.createEmployee(
            email: 'new.user@edu.eg',
            password: 'Password123!',
            fullName: 'New Employee',
            role: 'employee',
          ),
        ).thenAnswer(
          (_) async => Profile(
            id: 'emp-003',
            email: 'new.user@edu.eg',
            name: 'New Employee',
            role: 'employee',
            status: 'active',
            createdAt: DateTime.now(),
          ),
        );

        when(() => mockProfileRepository.getEmployeesWithStats())
            .thenAnswer((_) async => [mockEmp1, mockEmp2]);

        await employeesCubit.createEmployee(
          email: 'new.user@edu.eg',
          password: 'Password123!',
          fullName: 'New Employee',
          role: 'employee',
        );

        verify(
          () => mockProfileRepository.createEmployee(
            email: 'new.user@edu.eg',
            password: 'Password123!',
            fullName: 'New Employee',
            role: 'employee',
          ),
        ).called(1);
        verify(() => mockProfileRepository.getEmployeesWithStats()).called(1);
      },
    );

    test(
      'deleteEmployee executes delete repository call and refreshes state',
      () async {
        when(() => mockProfileRepository.deleteEmployee('emp-001'))
            .thenAnswer((_) async {});
        when(() => mockProfileRepository.getEmployeesWithStats())
            .thenAnswer((_) async => [mockEmp2]);

        await employeesCubit.deleteEmployee('emp-001');

        verify(() => mockProfileRepository.deleteEmployee('emp-001')).called(1);
        expect((employeesCubit.state as EmployeesLoaded).employees.length, 1);
        expect(
          (employeesCubit.state as EmployeesLoaded).employees.first.profile.id,
          'emp-002',
        );
      },
    );
  });
}
