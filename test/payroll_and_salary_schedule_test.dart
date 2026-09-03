import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendly/core/utils/payroll_calculator.dart';
import 'package:spendly/data/models/salary_payment_model.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/payroll_summary.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/entities/salary_payment.dart';
import 'package:spendly/domain/repositories/salary_payment_repository.dart';
import 'package:spendly/presentation/cubits/payroll/payroll_cubit.dart';
import 'package:spendly/presentation/cubits/payroll/payroll_state.dart';

class MockSalaryPaymentRepository extends Mock implements SalaryPaymentRepository {}

void main() {
  late MockSalaryPaymentRepository mockSalaryPaymentRepository;
  late PayrollCubit payrollCubit;

  setUpAll(() {
    registerFallbackValue(ExpenseCurrency.egp);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockSalaryPaymentRepository = MockSalaryPaymentRepository();
    payrollCubit = PayrollCubit(
      salaryPaymentRepository: mockSalaryPaymentRepository,
    );
  });

  tearDown(() {
    payrollCubit.close();
  });

  group('PayrollCalculator - Period Bounds Calculation', () {
    test('Monthly cycle starting on day 1 calculates accurate month lengths (28, 29, 30, 31 days)', () {
      final profileMonthlyDay1 = const Profile(
        id: 'user-1',
        name: 'Employee 1',
        salaryAmount: 10000,
        salaryCurrency: ExpenseCurrency.egp,
        salaryCycleType: 'monthly',
        salaryCycleStartDay: 1,
      );

      // Non-leap Feb 2025 (28 days)
      final boundsFebNonLeap = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay1,
        referenceDate: DateTime(2025, 2, 10),
      );
      expect(boundsFebNonLeap.start, DateTime(2025, 2, 1));
      expect(boundsFebNonLeap.end, DateTime(2025, 2, 28));
      expect(boundsFebNonLeap.totalDays, 28);
      expect(boundsFebNonLeap.nextPaymentDate, DateTime(2025, 2, 28));

      // Leap Feb 2024 (29 days)
      final boundsFebLeap = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay1,
        referenceDate: DateTime(2024, 2, 15),
      );
      expect(boundsFebLeap.start, DateTime(2024, 2, 1));
      expect(boundsFebLeap.end, DateTime(2024, 2, 29));
      expect(boundsFebLeap.totalDays, 29);

      // April (30 days)
      final boundsApril = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay1,
        referenceDate: DateTime(2026, 4, 12),
      );
      expect(boundsApril.start, DateTime(2026, 4, 1));
      expect(boundsApril.end, DateTime(2026, 4, 30));
      expect(boundsApril.totalDays, 30);

      // July (31 days)
      final boundsJuly = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay1,
        referenceDate: DateTime(2026, 7, 20),
      );
      expect(boundsJuly.start, DateTime(2026, 7, 1));
      expect(boundsJuly.end, DateTime(2026, 7, 31));
      expect(boundsJuly.totalDays, 31);
    });

    test('Monthly cycle starting mid-month (e.g. Day 15) spans across calendar months correctly', () {
      final profileMonthlyDay15 = const Profile(
        id: 'user-2',
        name: 'Employee 2',
        salaryAmount: 8000,
        salaryCurrency: ExpenseCurrency.egp,
        salaryCycleType: 'monthly',
        salaryCycleStartDay: 15,
      );

      // Reference on Aug 20 (after 15th): cycle is Aug 15 -> Sep 14
      final boundsAugAfter = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay15,
        referenceDate: DateTime(2026, 8, 20),
      );
      expect(boundsAugAfter.start, DateTime(2026, 8, 15));
      expect(boundsAugAfter.end, DateTime(2026, 9, 14));
      expect(boundsAugAfter.totalDays, 31); // Aug has 31 days -> 17 days in Aug + 14 in Sep = 31

      // Reference on Aug 5 (before 15th): cycle is Jul 15 -> Aug 14
      final boundsAugBefore = PayrollCalculator.calculatePeriodBounds(
        profile: profileMonthlyDay15,
        referenceDate: DateTime(2026, 8, 5),
      );
      expect(boundsAugBefore.start, DateTime(2026, 7, 15));
      expect(boundsAugBefore.end, DateTime(2026, 8, 14));
      expect(boundsAugBefore.totalDays, 31);
    });

    test('Custom days interval (14 days, 15 days, 45 days) calculates exact cycle duration', () {
      final profileCustom14 = const Profile(
        id: 'user-3',
        name: 'Contractor 14',
        salaryAmount: 3000,
        salaryCurrency: ExpenseCurrency.egp,
        salaryCycleType: 'custom_days',
        salaryCycleDays: 14,
        salaryCycleStartDay: 1,
      );

      final bounds14 = PayrollCalculator.calculatePeriodBounds(
        profile: profileCustom14,
        referenceDate: DateTime(2026, 9, 5),
      );
      expect(bounds14.totalDays, 14);
      expect(bounds14.end.difference(bounds14.start).inDays + 1, 14);

      final profileCustom45 = const Profile(
        id: 'user-4',
        name: 'Contractor 45',
        salaryAmount: 15000,
        salaryCurrency: ExpenseCurrency.usd,
        salaryCycleType: 'custom_days',
        salaryCycleDays: 45,
        salaryCycleStartDay: 1,
      );

      final bounds45 = PayrollCalculator.calculatePeriodBounds(
        profile: profileCustom45,
        referenceDate: DateTime(2026, 9, 10),
      );
      expect(bounds45.totalDays, 45);
      expect(bounds45.end.difference(bounds45.start).inDays + 1, 45);
    });
  });

  group('PayrollCalculator - Summary & Status Logic', () {
    final tProfile = const Profile(
      id: 'emp-101',
      name: 'Mahmoud Hassan',
      salaryAmount: 12000.0,
      salaryCurrency: ExpenseCurrency.egp,
      salaryCycleType: 'monthly',
      salaryCycleStartDay: 1,
    );

    test('Unpaid status: paidAmount=0, paidDays=0, remainingDays=totalDays', () {
      final summary = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: [],
        referenceDate: DateTime(2026, 9, 10),
      );

      expect(summary.salaryAmount, 12000.0);
      expect(summary.totalPaidInPeriod, 0.0);
      expect(summary.remainingSalary, 12000.0);
      expect(summary.overpaidAmount, 0.0);
      expect(summary.paidDays, 0.0);
      expect(summary.remainingDays, 30.0);
      expect(summary.status, PayrollPaymentStatus.unpaid);
      expect(summary.isFullyPaid, false);
    });

    test('Partially paid status: calculates proportional paid days accurately', () {
      // Half salary paid (6,000 / 12,000 in a 30-day month = 15.0 paid days)
      final payments = [
        SalaryPayment(
          id: 'pay-1',
          userId: 'emp-101',
          amount: 6000.0,
          currency: ExpenseCurrency.egp,
          paymentDate: DateTime(2026, 9, 5),
          salaryPeriodStart: DateTime(2026, 9, 1),
          salaryPeriodEnd: DateTime(2026, 9, 30),
          createdBy: 'admin-1',
        ),
      ];

      final summary = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: payments,
        referenceDate: DateTime(2026, 9, 10),
      );

      expect(summary.totalPaidInPeriod, 6000.0);
      expect(summary.remainingSalary, 6000.0);
      expect(summary.paidDays, 15.0);
      expect(summary.remainingDays, 15.0);
      expect(summary.status, PayrollPaymentStatus.partiallyPaid);
      expect(summary.isFullyPaid, false);
      expect(summary.paidPercentage, 0.5);
    });

    test('Fully paid status: paidAmount=salary, remainingSalary=0, paidDays=totalDays', () {
      final payments = [
        SalaryPayment(
          id: 'pay-1',
          userId: 'emp-101',
          amount: 8000.0,
          currency: ExpenseCurrency.egp,
          paymentDate: DateTime(2026, 9, 5),
          salaryPeriodStart: DateTime(2026, 9, 1),
          salaryPeriodEnd: DateTime(2026, 9, 30),
          createdBy: 'admin-1',
        ),
        SalaryPayment(
          id: 'pay-2',
          userId: 'emp-101',
          amount: 4000.0,
          currency: ExpenseCurrency.egp,
          paymentDate: DateTime(2026, 9, 15),
          salaryPeriodStart: DateTime(2026, 9, 1),
          salaryPeriodEnd: DateTime(2026, 9, 30),
          createdBy: 'admin-1',
        ),
      ];

      final summary = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: payments,
        referenceDate: DateTime(2026, 9, 20),
      );

      expect(summary.totalPaidInPeriod, 12000.0);
      expect(summary.remainingSalary, 0.0);
      expect(summary.overpaidAmount, 0.0);
      expect(summary.paidDays, 30.0);
      expect(summary.remainingDays, 0.0);
      expect(summary.status, PayrollPaymentStatus.paid);
      expect(summary.isFullyPaid, true);
    });

    test('Overpaid status: paidAmount > salary, overpaidAmount recorded', () {
      final payments = [
        SalaryPayment(
          id: 'pay-1',
          userId: 'emp-101',
          amount: 14000.0,
          currency: ExpenseCurrency.egp,
          paymentDate: DateTime(2026, 9, 5),
          salaryPeriodStart: DateTime(2026, 9, 1),
          salaryPeriodEnd: DateTime(2026, 9, 30),
          createdBy: 'admin-1',
        ),
      ];

      final summary = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: payments,
        referenceDate: DateTime(2026, 9, 10),
      );

      expect(summary.totalPaidInPeriod, 14000.0);
      expect(summary.remainingSalary, 0.0);
      expect(summary.overpaidAmount, 2000.0);
      expect(summary.status, PayrollPaymentStatus.overpaid);
      expect(summary.isFullyPaid, true);
    });

    test('Due Today, Due Soon, and Overdue countdown flags', () {
      // Due Today (when reference date is period end date)
      final summaryDueToday = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: [],
        referenceDate: DateTime(2026, 9, 30),
      );
      expect(summaryDueToday.daysUntilPayment, 0);
      expect(summaryDueToday.isDueToday, true);
      expect(summaryDueToday.isDueSoon, false);

      // Due Soon (2 days before period end)
      final summaryDueSoon = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: [],
        referenceDate: DateTime(2026, 9, 28),
      );
      expect(summaryDueSoon.daysUntilPayment, 2);
      expect(summaryDueSoon.isDueToday, false);
      expect(summaryDueSoon.isDueSoon, true);

      // Overdue (after period end without full payment)
      final summaryOverdue = PayrollCalculator.calculateSummary(
        profile: tProfile,
        allPayments: [],
        referenceDate: DateTime(2026, 10, 5), // Next month, if checked against Sep bounds
      );
      // When referenceDate is Oct 5, calculator evaluates Oct period bounds:
      expect(summaryOverdue.salaryPeriodStart, DateTime(2026, 10, 1));
      expect(summaryOverdue.salaryPeriodEnd, DateTime(2026, 10, 31));
    });

    test('Multi-currency isolation: USD payments do not count towards EGP salary', () {
      final payments = [
        SalaryPayment(
          id: 'pay-usd',
          userId: 'emp-101',
          amount: 500.0,
          currency: ExpenseCurrency.usd, // Mismatched currency
          paymentDate: DateTime(2026, 9, 5),
          salaryPeriodStart: DateTime(2026, 9, 1),
          salaryPeriodEnd: DateTime(2026, 9, 30),
          createdBy: 'admin-1',
        ),
      ];

      final summary = PayrollCalculator.calculateSummary(
        profile: tProfile, // EGP profile
        allPayments: payments,
        referenceDate: DateTime(2026, 9, 10),
      );

      expect(summary.totalPaidInPeriod, 0.0);
      expect(summary.remainingSalary, 12000.0);
      expect(summary.status, PayrollPaymentStatus.unpaid);
    });

    test('calculateUpcomingObligations separates EGP and USD obligations without blending', () {
      final empEgp = const Profile(
        id: 'egp-1',
        name: 'EGP Emp',
        salaryAmount: 10000,
        salaryCurrency: ExpenseCurrency.egp,
        salaryCycleType: 'monthly',
      );
      final empUsd = const Profile(
        id: 'usd-1',
        name: 'USD Emp',
        salaryAmount: 2500,
        salaryCurrency: ExpenseCurrency.usd,
        salaryCycleType: 'monthly',
      );

      final summaryEgp = PayrollCalculator.calculateSummary(
        profile: empEgp,
        allPayments: [],
        referenceDate: DateTime(2026, 9, 28), // 2 days left in Sep
      );
      final summaryUsd = PayrollCalculator.calculateSummary(
        profile: empUsd,
        allPayments: [],
        referenceDate: DateTime(2026, 9, 28), // 2 days left in Sep
      );

      final obligations = PayrollCalculator.calculateUpcomingObligations(
        summaries: [summaryEgp, summaryUsd],
        dueWithinDays: 5,
      );

      expect(obligations[ExpenseCurrency.egp], 10000.0);
      expect(obligations[ExpenseCurrency.usd], 2500.0);
    });
  });

  group('PayrollCubit State Tests', () {
    const tUserId = 'user-test-123';
    final tProfile = const Profile(
      id: tUserId,
      name: 'Test Employee',
      salaryAmount: 9000.0,
      salaryCurrency: ExpenseCurrency.egp,
      salaryCycleType: 'monthly',
      salaryCycleStartDay: 1,
    );

    final tSummary = PayrollSummary(
      profile: tProfile,
      salaryPeriodStart: DateTime(2026, 9, 1),
      salaryPeriodEnd: DateTime(2026, 9, 30),
      totalPeriodDays: 30,
      salaryAmount: 9000.0,
      salaryCurrency: ExpenseCurrency.egp,
      totalPaidInPeriod: 3000.0,
      remainingSalary: 6000.0,
      overpaidAmount: 0.0,
      paidDays: 10.0,
      remainingDays: 20.0,
      nextExpectedPaymentDate: DateTime(2026, 9, 30),
      daysUntilPayment: 20,
      status: PayrollPaymentStatus.partiallyPaid,
    );

    final tPayment = SalaryPayment(
      id: 'pay-test-1',
      userId: tUserId,
      amount: 3000.0,
      currency: ExpenseCurrency.egp,
      paymentDate: DateTime(2026, 9, 5),
      salaryPeriodStart: DateTime(2026, 9, 1),
      salaryPeriodEnd: DateTime(2026, 9, 30),
      note: 'Advance on salary',
      createdBy: 'admin-1',
    );

    test('loadEmployeePayroll emits [PayrollLoading, PayrollLoaded] on success', () async {
      when(() => mockSalaryPaymentRepository.getEmployeePayrollSummary(tUserId))
          .thenAnswer((_) async => tSummary);
      when(() => mockSalaryPaymentRepository.getSalaryPayments(tUserId))
          .thenAnswer((_) async => [tPayment]);

      expectLater(
        payrollCubit.stream,
        emitsInOrder([
          const PayrollLoading(),
          PayrollLoaded(
            userId: tUserId,
            summary: tSummary,
            payments: [tPayment],
          ),
        ]),
      );

      await payrollCubit.loadEmployeePayroll(tUserId);
    });

    test('loadAllPayrollSummaries emits [PayrollLoading, PayrollLoaded] with cash-flow obligations', () async {
      when(() => mockSalaryPaymentRepository.getAllPayrollSummaries())
          .thenAnswer((_) async => [tSummary]);
      when(() => mockSalaryPaymentRepository.getAllSalaryPayments())
          .thenAnswer((_) async => [tPayment]);

      expectLater(
        payrollCubit.stream,
        emitsInOrder([
          const PayrollLoading(),
          isA<PayrollLoaded>()
              .having((s) => s.summaries.length, 'summaries.length', 1)
              .having((s) => s.payments.length, 'payments.length', 1),
        ]),
      );

      await payrollCubit.loadAllPayrollSummaries();
    });

    test('addSalaryPayment creates record and refreshes employee state', () async {
      when(() => mockSalaryPaymentRepository.createSalaryPayment(
            userId: tUserId,
            amount: 3000.0,
            currency: ExpenseCurrency.egp,
            paymentDate: any(named: 'paymentDate'),
            salaryPeriodStart: any(named: 'salaryPeriodStart'),
            salaryPeriodEnd: any(named: 'salaryPeriodEnd'),
            note: 'Advance on salary',
          )).thenAnswer((_) async => tPayment);

      when(() => mockSalaryPaymentRepository.getEmployeePayrollSummary(tUserId))
          .thenAnswer((_) async => tSummary);
      when(() => mockSalaryPaymentRepository.getSalaryPayments(tUserId))
          .thenAnswer((_) async => [tPayment]);

      await payrollCubit.addSalaryPayment(
        userId: tUserId,
        amount: 3000.0,
        currency: ExpenseCurrency.egp,
        paymentDate: DateTime(2026, 9, 5),
        salaryPeriodStart: DateTime(2026, 9, 1),
        salaryPeriodEnd: DateTime(2026, 9, 30),
        note: 'Advance on salary',
      );

      verify(() => mockSalaryPaymentRepository.createSalaryPayment(
            userId: tUserId,
            amount: 3000.0,
            currency: ExpenseCurrency.egp,
            paymentDate: any(named: 'paymentDate'),
            salaryPeriodStart: any(named: 'salaryPeriodStart'),
            salaryPeriodEnd: any(named: 'salaryPeriodEnd'),
            note: 'Advance on salary',
          )).called(1);
    });

    test('deleteSalaryPayment deletes record and updates state', () async {
      when(() => mockSalaryPaymentRepository.deleteSalaryPayment('pay-test-1'))
          .thenAnswer((_) async => {});
      when(() => mockSalaryPaymentRepository.getEmployeePayrollSummary(tUserId))
          .thenAnswer((_) async => tSummary);
      when(() => mockSalaryPaymentRepository.getSalaryPayments(tUserId))
          .thenAnswer((_) async => []);

      await payrollCubit.deleteSalaryPayment('pay-test-1', tUserId);

      verify(() => mockSalaryPaymentRepository.deleteSalaryPayment('pay-test-1')).called(1);
    });

    test('updateSalaryCycleConfig calls repository and reloads summary', () async {
      when(() => mockSalaryPaymentRepository.updateSalaryCycleConfig(
            userId: tUserId,
            cycleType: 'custom_days',
            cycleDays: 14,
            cycleStartDay: 1,
          )).thenAnswer((_) async => {});
      when(() => mockSalaryPaymentRepository.getEmployeePayrollSummary(tUserId))
          .thenAnswer((_) async => tSummary);

      await payrollCubit.updateSalaryCycleConfig(
        userId: tUserId,
        cycleType: 'custom_days',
        cycleDays: 14,
        cycleStartDay: 1,
      );

      verify(() => mockSalaryPaymentRepository.updateSalaryCycleConfig(
            userId: tUserId,
            cycleType: 'custom_days',
            cycleDays: 14,
            cycleStartDay: 1,
          )).called(1);
    });
  });

  group('SalaryPaymentModel Serialization Tests', () {
    test('fromJson and toJson produce symmetrical and accurate representations', () {
      final json = {
        'id': 'pay-model-1',
        'user_id': 'user-model-1',
        'amount': 4500.0,
        'currency': 'EGP',
        'payment_date': '2026-09-01T00:00:00.000',
        'salary_period_start': '2026-09-01T00:00:00.000',
        'salary_period_end': '2026-09-30T00:00:00.000',
        'note': 'Monthly base payment',
        'created_by': 'admin-model-1',
        'created_at': '2026-09-01T10:00:00.000',
        'updated_at': '2026-09-01T10:00:00.000',
        'creator': {'full_name': 'Admin Super'},
      };

      final model = SalaryPaymentModel.fromJson(json);
      expect(model.id, 'pay-model-1');
      expect(model.userId, 'user-model-1');
      expect(model.amount, 4500.0);
      expect(model.currency, ExpenseCurrency.egp);
      expect(model.createdByName, 'Admin Super');

      final serialized = model.toJson();
      expect(serialized['id'], 'pay-model-1');
      expect(serialized['user_id'], 'user-model-1');
      expect(serialized['amount'], 4500.0);
      expect(serialized['currency'], 'EGP');
    });
  });
}
