import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/salary_payment.dart';

class SalaryPaymentModel extends SalaryPayment {
  const SalaryPaymentModel({
    required super.id,
    required super.userId,
    required super.amount,
    super.currency = ExpenseCurrency.egp,
    required super.paymentDate,
    required super.salaryPeriodStart,
    required super.salaryPeriodEnd,
    super.note,
    required super.createdBy,
    super.createdByName,
    super.createdAt,
    super.updatedAt,
  });

  factory SalaryPaymentModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    final currencyStr = json['currency'] as String? ?? 'EGP';
    final currency = ExpenseCurrency.fromString(currencyStr);

    final paymentDateStr = json['payment_date'] as String? ?? DateTime.now().toIso8601String();
    final periodStartStr = json['salary_period_start'] as String? ?? paymentDateStr;
    final periodEndStr = json['salary_period_end'] as String? ?? paymentDateStr;

    // Handle nested creator relation if populated
    String? creatorName;
    if (json['creator'] is Map<String, dynamic>) {
      creatorName = json['creator']['full_name'] as String?;
    } else if (json['created_by_name'] != null) {
      creatorName = json['created_by_name'] as String?;
    }

    return SalaryPaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: amount,
      currency: currency,
      paymentDate: DateTime.tryParse(paymentDateStr)?.toLocal() ?? DateTime.now(),
      salaryPeriodStart: DateTime.tryParse(periodStartStr)?.toLocal() ?? DateTime.now(),
      salaryPeriodEnd: DateTime.tryParse(periodEndStr)?.toLocal() ?? DateTime.now(),
      note: json['note'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdByName: creatorName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final dateStr = paymentDate.toIso8601String().split('T').first;
    final startStr = salaryPeriodStart.toIso8601String().split('T').first;
    final endStr = salaryPeriodEnd.toIso8601String().split('T').first;

    return {
      if (includeId) 'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency.code,
      'payment_date': dateStr,
      'salary_period_start': startStr,
      'salary_period_end': endStr,
      if (note != null && note!.isNotEmpty) 'note': note,
      'created_by': createdBy,
    };
  }

  factory SalaryPaymentModel.fromEntity(SalaryPayment entity) {
    return SalaryPaymentModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      currency: entity.currency,
      paymentDate: entity.paymentDate,
      salaryPeriodStart: entity.salaryPeriodStart,
      salaryPeriodEnd: entity.salaryPeriodEnd,
      note: entity.note,
      createdBy: entity.createdBy,
      createdByName: entity.createdByName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
