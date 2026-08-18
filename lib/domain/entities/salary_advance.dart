import 'package:equatable/equatable.dart';
import 'expense_currency.dart';

class SalaryAdvance extends Equatable {
  const SalaryAdvance({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.advanceDate,
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
  final DateTime advanceDate;
  final String? note;
  final String createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalaryAdvance copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCurrency? currency,
    DateTime? advanceDate,
    String? note,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalaryAdvance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      advanceDate: advanceDate ?? this.advanceDate,
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
        advanceDate,
        note,
        createdBy,
        creatorName,
        createdAt,
        updatedAt,
      ];
}
