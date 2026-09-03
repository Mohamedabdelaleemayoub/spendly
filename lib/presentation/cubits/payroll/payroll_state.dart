import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/payroll_summary.dart';
import '../../../domain/entities/salary_payment.dart';

abstract class PayrollState extends Equatable {
  const PayrollState();

  @override
  List<Object?> get props => [];
}

class PayrollInitial extends PayrollState {
  const PayrollInitial();
}

class PayrollLoading extends PayrollState {
  const PayrollLoading();
}

class PayrollLoaded extends PayrollState {
  const PayrollLoaded({
    this.userId,
    this.summary,
    this.summaries = const [],
    this.payments = const [],
    this.isActionLoading = false,
    this.upcomingObligations = const {
      ExpenseCurrency.egp: 0.0,
      ExpenseCurrency.usd: 0.0,
    },
  });

  final String? userId;
  final PayrollSummary? summary;
  final List<PayrollSummary> summaries;
  final List<SalaryPayment> payments;
  final bool isActionLoading;
  final Map<ExpenseCurrency, double> upcomingObligations;

  double get upcomingEgp => upcomingObligations[ExpenseCurrency.egp] ?? 0.0;
  double get upcomingUsd => upcomingObligations[ExpenseCurrency.usd] ?? 0.0;

  List<PayrollSummary> get dueTodayEmployees =>
      summaries.where((s) => s.isDueToday).toList();

  List<PayrollSummary> get dueSoonEmployees =>
      summaries.where((s) => s.isDueSoon).toList();

  PayrollLoaded copyWith({
    String? userId,
    PayrollSummary? summary,
    List<PayrollSummary>? summaries,
    List<SalaryPayment>? payments,
    bool? isActionLoading,
    Map<ExpenseCurrency, double>? upcomingObligations,
  }) {
    return PayrollLoaded(
      userId: userId ?? this.userId,
      summary: summary ?? this.summary,
      summaries: summaries ?? this.summaries,
      payments: payments ?? this.payments,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      upcomingObligations: upcomingObligations ?? this.upcomingObligations,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        summary,
        summaries,
        payments,
        isActionLoading,
        upcomingObligations,
      ];
}

class PayrollError extends PayrollState {
  const PayrollError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
