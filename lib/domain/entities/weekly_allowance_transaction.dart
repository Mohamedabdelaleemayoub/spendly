import 'package:equatable/equatable.dart';
import 'expense_currency.dart';

class WeeklyAllowanceTransaction extends Equatable {
  const WeeklyAllowanceTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.transactionDate,
    this.note,
    required this.createdBy,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final double amount;
  final ExpenseCurrency currency;
  final DateTime transactionDate;
  final String? note;
  final String createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WeeklyAllowanceTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCurrency? currency,
    DateTime? transactionDate,
    String? note,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyAllowanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
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
        transactionDate,
        note,
        createdBy,
        creatorName,
        createdAt,
        updatedAt,
      ];
}
