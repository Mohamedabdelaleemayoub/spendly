import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/salary_advance.dart';

class SalaryAdvanceModel extends SalaryAdvance {
  const SalaryAdvanceModel({
    required super.id,
    required super.userId,
    required super.amount,
    super.currency = ExpenseCurrency.egp,
    required super.advanceDate,
    super.note,
    required super.createdBy,
    super.creatorName,
    super.createdAt,
    super.updatedAt,
  });

  factory SalaryAdvanceModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    final currencyStr = json['currency'] as String? ?? 'EGP';
    final currency = ExpenseCurrency.fromString(currencyStr);

    final dateStr = json['advance_date'] as String;
    final advanceDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();

    // Extract joined creator full_name if present
    String? creatorName;
    if (json['creator'] is Map<String, dynamic>) {
      creatorName = (json['creator'] as Map<String, dynamic>)['full_name'] as String?;
    } else if (json['creator_name'] != null) {
      creatorName = json['creator_name'] as String?;
    }

    return SalaryAdvanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: amount,
      currency: currency,
      advanceDate: advanceDate,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency.code,
      'advance_date': advanceDate.toIso8601String().split('T').first,
      if (note != null) 'note': note,
      'created_by': createdBy,
    };
  }

  factory SalaryAdvanceModel.fromEntity(SalaryAdvance advance) {
    return SalaryAdvanceModel(
      id: advance.id,
      userId: advance.userId,
      amount: advance.amount,
      currency: advance.currency,
      advanceDate: advance.advanceDate,
      note: advance.note,
      createdBy: advance.createdBy,
      creatorName: advance.creatorName,
      createdAt: advance.createdAt,
      updatedAt: advance.updatedAt,
    );
  }
}
