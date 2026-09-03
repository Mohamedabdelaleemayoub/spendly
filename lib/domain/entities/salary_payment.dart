import 'package:equatable/equatable.dart';
import 'expense_currency.dart';

class SalaryPayment extends Equatable {
  const SalaryPayment({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.paymentDate,
    required this.salaryPeriodStart,
    required this.salaryPeriodEnd,
    this.note,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final double amount;
  final ExpenseCurrency currency;
  final DateTime paymentDate;
  final DateTime salaryPeriodStart;
  final DateTime salaryPeriodEnd;
  final String? note;
  final String createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalaryPayment copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCurrency? currency,
    DateTime? paymentDate,
    DateTime? salaryPeriodStart,
    DateTime? salaryPeriodEnd,
    String? note,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalaryPayment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentDate: paymentDate ?? this.paymentDate,
      salaryPeriodStart: salaryPeriodStart ?? this.salaryPeriodStart,
      salaryPeriodEnd: salaryPeriodEnd ?? this.salaryPeriodEnd,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        currency,
        paymentDate,
        salaryPeriodStart,
        salaryPeriodEnd,
        note,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
      ];
}
