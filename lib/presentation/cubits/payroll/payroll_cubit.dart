import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/payroll_calculator.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/repositories/salary_payment_repository.dart';
import 'payroll_state.dart';

class PayrollCubit extends Cubit<PayrollState> {
  PayrollCubit({
    required this.salaryPaymentRepository,
  }) : super(const PayrollInitial());

  final SalaryPaymentRepository salaryPaymentRepository;

  @override
  void emit(PayrollState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadEmployeePayroll(String userId, {DateTime? referenceDate}) async {
    emit(const PayrollLoading());
    try {
      final summary = await salaryPaymentRepository.getEmployeePayrollSummary(
        userId,
        referenceDate: referenceDate,
      );
      final payments = await salaryPaymentRepository.getSalaryPayments(userId);

      emit(PayrollLoaded(
        userId: userId,
        summary: summary,
        payments: payments,
      ));
    } on Failure catch (e) {
      emit(PayrollError(e.message));
    } catch (e) {
      emit(PayrollError('فشل تحميل جدول صرف الراتب: $e'));
    }
  }

  Future<void> loadAllPayrollSummaries({DateTime? referenceDate}) async {
    emit(const PayrollLoading());
    try {
      final summaries = await salaryPaymentRepository.getAllPayrollSummaries(
        referenceDate: referenceDate,
      );
      final allPayments = await salaryPaymentRepository.getAllSalaryPayments();
      final obligations = PayrollCalculator.calculateUpcomingObligations(summaries: summaries);

      emit(PayrollLoaded(
        summaries: summaries,
        payments: allPayments,
        upcomingObligations: obligations,
      ));
    } on Failure catch (e) {
      emit(PayrollError(e.message));
    } catch (e) {
      emit(PayrollError('فشل تحميل جدول رواتب الموظفين: $e'));
    }
  }

  Future<void> addSalaryPayment({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is PayrollLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryPaymentRepository.createSalaryPayment(
        userId: userId,
        amount: amount,
        currency: currency,
        paymentDate: paymentDate,
        salaryPeriodStart: salaryPeriodStart,
        salaryPeriodEnd: salaryPeriodEnd,
        note: note,
      );

      // Reload updated summary and payments
      final updatedSummary = await salaryPaymentRepository.getEmployeePayrollSummary(userId);
      final updatedPayments = await salaryPaymentRepository.getSalaryPayments(userId);

      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(
          summary: updatedSummary,
          payments: updatedPayments,
          isActionLoading: false,
        ));
      } else {
        await loadEmployeePayroll(userId);
      }
    } on Failure catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError(e.message));
    } catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError('فشل تسجيل دفعة الراتب: $e'));
    }
  }

  Future<void> updateSalaryPayment({
    required String id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is PayrollLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryPaymentRepository.updateSalaryPayment(
        id: id,
        amount: amount,
        currency: currency,
        paymentDate: paymentDate,
        salaryPeriodStart: salaryPeriodStart,
        salaryPeriodEnd: salaryPeriodEnd,
        note: note,
      );

      final updatedSummary = await salaryPaymentRepository.getEmployeePayrollSummary(userId);
      final updatedPayments = await salaryPaymentRepository.getSalaryPayments(userId);

      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(
          summary: updatedSummary,
          payments: updatedPayments,
          isActionLoading: false,
        ));
      } else {
        await loadEmployeePayroll(userId);
      }
    } on Failure catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError(e.message));
    } catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError('فشل تعديل دفعة الراتب: $e'));
    }
  }

  Future<void> deleteSalaryPayment(String id, String userId) async {
    final currentState = state;
    if (currentState is PayrollLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryPaymentRepository.deleteSalaryPayment(id);

      final updatedSummary = await salaryPaymentRepository.getEmployeePayrollSummary(userId);
      final updatedPayments = await salaryPaymentRepository.getSalaryPayments(userId);

      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(
          summary: updatedSummary,
          payments: updatedPayments,
          isActionLoading: false,
        ));
      } else {
        await loadEmployeePayroll(userId);
      }
    } on Failure catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError(e.message));
    } catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError('فشل حذف دفعة الراتب: $e'));
    }
  }

  Future<void> updateSalaryCycleConfig({
    required String userId,
    required String cycleType,
    required int cycleDays,
    required int cycleStartDay,
  }) async {
    final currentState = state;
    if (currentState is PayrollLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryPaymentRepository.updateSalaryCycleConfig(
        userId: userId,
        cycleType: cycleType,
        cycleDays: cycleDays,
        cycleStartDay: cycleStartDay,
      );

      final updatedSummary = await salaryPaymentRepository.getEmployeePayrollSummary(userId);

      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(
          summary: updatedSummary,
          isActionLoading: false,
        ));
      } else {
        await loadEmployeePayroll(userId);
      }
    } on Failure catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError(e.message));
    } catch (e) {
      if (currentState is PayrollLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(PayrollError('فشل تعديل دورة الصرف: $e'));
    }
  }
}
