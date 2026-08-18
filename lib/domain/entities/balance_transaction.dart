import 'package:equatable/equatable.dart';
import 'expense_currency.dart';
import 'profile.dart';

enum BalanceTransactionType {
  credit,
  adjustmentAdd,
  adjustmentSub;

  static BalanceTransactionType fromString(String value) {
    switch (value) {
      case 'credit':
        return BalanceTransactionType.credit;
      case 'adjustment_add':
        return BalanceTransactionType.adjustmentAdd;
      case 'adjustment_sub':
        return BalanceTransactionType.adjustmentSub;
      default:
        return BalanceTransactionType.credit;
    }
  }

  String toDbString() {
    switch (this) {
      case BalanceTransactionType.credit:
        return 'credit';
      case BalanceTransactionType.adjustmentAdd:
        return 'adjustment_add';
      case BalanceTransactionType.adjustmentSub:
        return 'adjustment_sub';
    }
  }
}

class BalanceTransaction extends Equatable {
  const BalanceTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.type,
    required this.transactionDate,
    this.note,
    this.createdBy,
    this.creatorProfile,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final ExpenseCurrency currency;
  final BalanceTransactionType type;
  final DateTime transactionDate;
  final String? note;
  final String? createdBy;
  final Profile? creatorProfile;
  final DateTime? createdAt;

  bool get isCredit => type == BalanceTransactionType.credit || type == BalanceTransactionType.adjustmentAdd;

  BalanceTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    ExpenseCurrency? currency,
    BalanceTransactionType? type,
    DateTime? transactionDate,
    String? note,
    String? createdBy,
    Profile? creatorProfile,
    DateTime? createdAt,
  }) {
    return BalanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      creatorProfile: creatorProfile ?? this.creatorProfile,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        currency,
        type,
        transactionDate,
        note,
        createdBy,
        creatorProfile,
        createdAt,
      ];
}
