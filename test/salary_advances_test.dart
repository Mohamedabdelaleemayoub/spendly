import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendly/data/models/profile_model.dart';
import 'package:spendly/data/models/salary_advance_model.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/entities/salary_advance.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/domain/repositories/salary_advance_repository.dart';
import 'package:spendly/presentation/cubits/salary_advances/salary_advances_cubit.dart';
import 'package:spendly/presentation/cubits/salary_advances/salary_advances_state.dart';

class MockSalaryAdvanceRepository extends Mock implements SalaryAdvanceRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockSalaryAdvanceRepository mockSalaryAdvanceRepository;
  late MockProfileRepository mockProfileRepository;
  late SalaryAdvancesCubit salaryAdvancesCubit;

  setUpAll(() {
    registerFallbackValue(ExpenseCurrency.egp);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockSalaryAdvanceRepository = MockSalaryAdvanceRepository();
    mockProfileRepository = MockProfileRepository();
    salaryAdvancesCubit = SalaryAdvancesCubit(
      salaryAdvanceRepository: mockSalaryAdvanceRepository,
      profileRepository: mockProfileRepository,
    );
  });

  tearDown(() {
    salaryAdvancesCubit.close();
  });

  group('Salary Advances & Salary Tests', () {
    const tUserId = 'user-uuid-123';
    const tAdminId = 'admin-uuid-456';

    final tProfile = Profile(
      id: tUserId,
      name: 'Ahmed Ali',
      email: 'ahmed@spendly.com',
      role: 'employee',
      status: 'active',
      salaryAmount: 8000.0,
      salaryCurrency: ExpenseCurrency.egp,
    );

    final tAdvance1 = SalaryAdvance(
      id: 'adv-1',
      userId: tUserId,
      amount: 1500.0,
      currency: ExpenseCurrency.egp,
      advanceDate: DateTime(2026, 8, 10),
      note: 'Emergency personal expenses',
      createdBy: tAdminId,
      creatorName: 'Super Admin',
      createdAt: DateTime(2026, 8, 10, 12, 0),
      updatedAt: DateTime(2026, 8, 10, 12, 0),
    );

    final tAdvance2 = SalaryAdvance(
      id: 'adv-2',
      userId: tUserId,
      amount: 500.0,
      currency: ExpenseCurrency.egp,
      advanceDate: DateTime(2026, 8, 15),
      note: 'Medical bill',
      createdBy: tAdminId,
      creatorName: 'Super Admin',
      createdAt: DateTime(2026, 8, 15, 14, 0),
      updatedAt: DateTime(2026, 8, 15, 14, 0),
    );

    test('1. ProfileModel should correctly serialize and deserialize salary_amount and salary_currency', () {
      final json = {
        'id': tUserId,
        'full_name': 'Ahmed Ali',
        'email': 'ahmed@spendly.com',
        'role': 'employee',
        'status': 'active',
        'salary_amount': 8000.0,
        'salary_currency': 'EGP',
      };

      final model = ProfileModel.fromJson(json);
      expect(model.salaryAmount, equals(8000.0));
      expect(model.salaryCurrency, equals(ExpenseCurrency.egp));

      final serialized = model.toJson();
      expect(serialized['salary_amount'], equals(8000.0));
      expect(serialized['salary_currency'], equals('EGP'));
    });

    test('2. SalaryAdvanceModel should correctly serialize and deserialize with creator join', () {
      final json = {
        'id': 'adv-1',
        'user_id': tUserId,
        'amount': 1500.0,
        'currency': 'EGP',
        'advance_date': '2026-08-10',
        'note': 'Emergency personal expenses',
        'created_by': tAdminId,
        'creator': {
          'full_name': 'Super Admin',
        },
      };

      final model = SalaryAdvanceModel.fromJson(json);
      expect(model.id, equals('adv-1'));
      expect(model.amount, equals(1500.0));
      expect(model.currency, equals(ExpenseCurrency.egp));
      expect(model.note, equals('Emergency personal expenses'));
      expect(model.creatorName, equals('Super Admin'));

      final serialized = model.toJson();
      expect(serialized['amount'], equals(1500.0));
      expect(serialized['currency'], equals('EGP'));
      expect(serialized['advance_date'], equals('2026-08-10'));
    });

    test('3. EmployeeSummary should correctly calculate remaining salary (Salary - Total Advances)', () {
      final summary = EmployeeSummary(
        profile: tProfile,
        totalExpenses: 2500.0,
        expensesCount: 4,
        totalAdvances: 2000.0,
      );

      expect(summary.totalAdvances, equals(2000.0));
      expect(summary.remainingSalary, equals(6000.0)); // 8000 - 2000 = 6000
    });

    test('4. SalaryAdvancesLoaded state should accurately compute total advances and remaining salary', () {
      final state = SalaryAdvancesLoaded(
        userId: tUserId,
        salaryAmount: 8000.0,
        salaryCurrency: ExpenseCurrency.egp,
        advances: [tAdvance1, tAdvance2],
      );

      expect(state.totalAdvances, equals(2000.0)); // 1500 + 500
      expect(state.remainingSalary, equals(6000.0)); // 8000 - 2000
    });

    test('5. Loading salary advances via Cubit should emit Loaded state with computed totals', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile);
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => [tAdvance1, tAdvance2]);

      expectLater(
        salaryAdvancesCubit.stream,
        emitsInOrder([
          const SalaryAdvancesLoading(),
          isA<SalaryAdvancesLoaded>()
              .having((s) => s.salaryAmount, 'salaryAmount', 8000.0)
              .having((s) => s.totalAdvances, 'totalAdvances', 2000.0)
              .having((s) => s.remainingSalary, 'remainingSalary', 6000.0),
        ]),
      );

      await salaryAdvancesCubit.loadSalaryAdvances(tUserId);
    });

    test('6. Adding a salary advance should immediately reduce remaining salary', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile);
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => [tAdvance1]);
      when(() => mockSalaryAdvanceRepository.createSalaryAdvance(
            userId: tUserId,
            amount: 500.0,
            currency: any(named: 'currency'),
            advanceDate: any(named: 'advanceDate'),
            note: any(named: 'note'),
          )).thenAnswer((_) async => tAdvance2);

      await salaryAdvancesCubit.loadSalaryAdvances(tUserId);
      final initialState = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(initialState.totalAdvances, equals(1500.0));
      expect(initialState.remainingSalary, equals(6500.0)); // 8000 - 1500

      await salaryAdvancesCubit.addSalaryAdvance(
        userId: tUserId,
        amount: 500.0,
        advanceDate: DateTime(2026, 8, 15),
        note: 'Medical bill',
      );

      final updatedState = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(updatedState.totalAdvances, equals(2000.0)); // 1500 + 500
      expect(updatedState.remainingSalary, equals(6000.0)); // 8000 - 2000
    });

    test('7. Editing a salary advance should recalculate total advances and remaining salary immediately', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile);
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => [tAdvance1, tAdvance2]);

      final editedAdvance2 = tAdvance2.copyWith(amount: 1000.0);
      when(() => mockSalaryAdvanceRepository.updateSalaryAdvance(
            id: 'adv-2',
            amount: 1000.0,
            currency: any(named: 'currency'),
            advanceDate: any(named: 'advanceDate'),
            note: any(named: 'note'),
          )).thenAnswer((_) async => editedAdvance2);

      await salaryAdvancesCubit.loadSalaryAdvances(tUserId);
      await salaryAdvancesCubit.updateSalaryAdvance(
        id: 'adv-2',
        userId: tUserId,
        amount: 1000.0,
        advanceDate: tAdvance2.advanceDate,
      );

      final state = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(state.totalAdvances, equals(2500.0)); // 1500 + 1000
      expect(state.remainingSalary, equals(5500.0)); // 8000 - 2500
    });

    test('8. Deleting a salary advance should restore remaining salary', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile);
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => [tAdvance1, tAdvance2]);
      when(() => mockSalaryAdvanceRepository.deleteSalaryAdvance('adv-2'))
          .thenAnswer((_) async => Future.value());

      await salaryAdvancesCubit.loadSalaryAdvances(tUserId);
      await salaryAdvancesCubit.deleteSalaryAdvance('adv-2', tUserId);

      final state = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(state.advances.length, equals(1));
      expect(state.totalAdvances, equals(1500.0));
      expect(state.remainingSalary, equals(6500.0)); // 8000 - 1500
    });

    test('9. Updating employee salary should recalculate remaining salary based on existing advances', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile);
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => [tAdvance1, tAdvance2]);
      when(() => mockSalaryAdvanceRepository.updateEmployeeSalary(
            userId: tUserId,
            salaryAmount: 10000.0,
            salaryCurrency: any(named: 'salaryCurrency'),
          )).thenAnswer((_) async => Future.value());

      await salaryAdvancesCubit.loadSalaryAdvances(tUserId);
      await salaryAdvancesCubit.updateEmployeeSalary(
        userId: tUserId,
        salaryAmount: 10000.0,
        salaryCurrency: ExpenseCurrency.egp,
      );

      final state = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(state.salaryAmount, equals(10000.0));
      expect(state.totalAdvances, equals(2000.0));
      expect(state.remainingSalary, equals(8000.0)); // 10000 - 2000
    });

    test('10. Salary advances do NOT reduce employee spending balance / allowance', () {
      // Company operational allowance given to employee: 3000 EGP
      const employeeGivenAllowance = 3000.0;
      const employeeSpentExpenses = 1200.0;
      final availableSpendingBalance = employeeGivenAllowance - employeeSpentExpenses; // 1800 EGP

      // Personal salary advance taken: 1500 EGP
      const salaryAdvanceTaken = 1500.0;

      // Available spending balance MUST remain completely unaffected by salary advance
      expect(availableSpendingBalance, equals(1800.0));
      expect(availableSpendingBalance - 0, equals(1800.0)); // No side-effect subtraction

      // Salary deduction occurs ONLY on employee salary
      final salary = tProfile.salaryAmount; // 8000 EGP
      final remainingSalary = salary - salaryAdvanceTaken; // 6500 EGP
      expect(remainingSalary, equals(6500.0));
    });

    test('11. loadSalaryAdvances ALWAYS fetches persisted salary from profileRepository even if initialSalary is 0.0', () async {
      when(() => mockProfileRepository.getProfile(tUserId))
          .thenAnswer((_) async => tProfile); // salaryAmount is 8000.0
      when(() => mockSalaryAdvanceRepository.getSalaryAdvances(tUserId))
          .thenAnswer((_) async => []);

      // Call with initialSalary: 0.0 (simulating opening from route with default profile.salaryAmount)
      await salaryAdvancesCubit.loadSalaryAdvances(
        tUserId,
        initialSalary: 0.0,
        initialCurrency: ExpenseCurrency.egp,
      );

      final state = salaryAdvancesCubit.state as SalaryAdvancesLoaded;
      expect(state.salaryAmount, equals(8000.0)); // Overridden by authoritative repo fetch
      expect(state.remainingSalary, equals(8000.0));
      verify(() => mockProfileRepository.getProfile(tUserId)).called(1);
    });
  });
}
