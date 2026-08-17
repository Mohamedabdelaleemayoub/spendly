import 'package:equatable/equatable.dart';
import '../dashboard/dashboard_state.dart';

class PaymentMethodSpending extends Equatable {
  const PaymentMethodSpending({
    required this.methodKey,
    required this.label,
    required this.amount,
    required this.percentage,
  });

  final String methodKey;
  final String label;
  final double amount;
  final double percentage;

  @override
  List<Object?> get props => [methodKey, label, amount, percentage];
}

class DailySpending extends Equatable {
  const DailySpending({
    required this.day,
    required this.amount,
  });

  final int day;
  final double amount;

  @override
  List<Object?> get props => [day, amount];
}

sealed class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  const ReportLoaded({
    required this.selectedMonth,
    required this.totalAmount,
    required this.totalCount,
    required this.categorySpending,
    required this.paymentMethodSpending,
    required this.dailySpending,
    this.employeeSpending = const [],
    this.isAdmin = false,
  });

  final DateTime selectedMonth;
  final double totalAmount;
  final int totalCount;
  final List<CategorySpending> categorySpending;
  final List<PaymentMethodSpending> paymentMethodSpending;
  final List<DailySpending> dailySpending;
  final List<EmployeeSpending> employeeSpending;
  final bool isAdmin;

  @override
  List<Object?> get props => [
        selectedMonth,
        totalAmount,
        totalCount,
        categorySpending,
        paymentMethodSpending,
        dailySpending,
        employeeSpending,
        isAdmin,
      ];
}

class ReportError extends ReportState {
  const ReportError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
