import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/weekly_allowance_transaction.dart';

class WeeklyAllowanceModel extends WeeklyAllowanceTransaction {
  const WeeklyAllowanceModel({
    required super.id,
    required super.userId,
    required super.amount,
    super.currency = ExpenseCurrency.egp,
    required super.transactionDate,
    super.note,
    required super.createdBy,
    super.creatorName,
    super.createdAt,
    super.updatedAt,
  });

  factory WeeklyAllowanceModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    final currencyStr = json['currency'] as String? ?? 'EGP';
    final currency = ExpenseCurrency.fromString(currencyStr);

    final dateStr = json['transaction_date'] as String;
    final transactionDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();

    String? creatorName;
    if (json['creator'] is Map<String, dynamic>) {
      creatorName = (json['creator'] as Map<String, dynamic>)['full_name'] as String?;
    } else if (json['creator_name'] != null) {
      creatorName = json['creator_name'] as String?;
    }

    return WeeklyAllowanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: json['note'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      creatorName: creatorName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final dateStr =
        '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}';
    return {
      if (includeId) 'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency.code,
      'transaction_date': dateStr,
      if (note != null && note!.isNotEmpty) 'note': note,
      'created_by': createdBy,
    };
  }

  factory WeeklyAllowanceModel.fromEntity(WeeklyAllowanceTransaction entity) {
    return WeeklyAllowanceModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      currency: entity.currency,
      transactionDate: entity.transactionDate,
      note: entity.note,
      createdBy: entity.createdBy,
      creatorName: entity.creatorName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
