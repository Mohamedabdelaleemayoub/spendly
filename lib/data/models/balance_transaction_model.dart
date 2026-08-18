import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/profile.dart';

class BalanceTransactionModel extends BalanceTransaction {
  const BalanceTransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.transactionDate,
    super.note,
    super.createdBy,
    super.creatorProfile,
    super.createdAt,
  });

  factory BalanceTransactionModel.fromJson(Map<String, dynamic> json) {
    Profile? creator;
    if (json['creator'] is Map<String, dynamic>) {
      creator = Profile(
        id: json['creator']['id'] as String? ?? '',
        name: json['creator']['name'] as String? ?? '',
        email: json['creator']['email'] as String?,
        avatarUrl: json['creator']['avatar_url'] as String?,
      );
    }

    return BalanceTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.parse(json['amount'].toString()),
      type: BalanceTransactionType.fromString(json['type'] as String? ?? 'credit'),
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.now(),
      note: json['note'] as String?,
      createdBy: json['created_by'] as String?,
      creatorProfile: creator,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type.toDbString(),
      'transaction_date':
          '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  factory BalanceTransactionModel.fromEntity(BalanceTransaction entity) {
    return BalanceTransactionModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      type: entity.type,
      transactionDate: entity.transactionDate,
      note: entity.note,
      createdBy: entity.createdBy,
      creatorProfile: entity.creatorProfile,
      createdAt: entity.createdAt,
    );
  }
}
