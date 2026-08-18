import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.name,
    super.email,
    super.role = 'employee',
    super.status = 'active',
    super.avatarUrl,
    super.salaryAmount = 0.0,
    super.salaryCurrency = ExpenseCurrency.egp,
    super.createdAt,
    super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawSalary = json['salary_amount'];
    final salary = rawSalary is num
        ? rawSalary.toDouble()
        : double.tryParse(rawSalary?.toString() ?? '0') ?? 0.0;

    final currencyStr = json['salary_currency'] as String? ?? 'EGP';
    final currency = ExpenseCurrency.fromString(currencyStr);

    return ProfileModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'مستخدم',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'employee',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      salaryAmount: salary,
      salaryCurrency: currency,
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
      'full_name': name,
      if (email != null) 'email': email,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
      'salary_amount': salaryAmount,
      'salary_currency': salaryCurrency.code,
    };
  }

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      role: profile.role,
      status: profile.status,
      avatarUrl: profile.avatarUrl,
      salaryAmount: profile.salaryAmount,
      salaryCurrency: profile.salaryCurrency,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
