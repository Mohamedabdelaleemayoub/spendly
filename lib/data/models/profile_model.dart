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
    super.salaryCycleType = 'monthly',
    super.salaryCycleDays = 30,
    super.salaryCycleStartDay = 1,
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

    final cycleType = json['salary_cycle_type'] as String? ?? 'monthly';
    final rawDays = json['salary_cycle_days'];
    final cycleDays = rawDays is num ? rawDays.toInt() : int.tryParse(rawDays?.toString() ?? '30') ?? 30;
    final rawStartDay = json['salary_cycle_start_day'];
    final cycleStartDay = rawStartDay is num ? rawStartDay.toInt() : int.tryParse(rawStartDay?.toString() ?? '1') ?? 1;

    return ProfileModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'مستخدم',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'employee',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      salaryAmount: salary,
      salaryCurrency: currency,
      salaryCycleType: cycleType,
      salaryCycleDays: cycleDays,
      salaryCycleStartDay: cycleStartDay,
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
      'salary_cycle_type': salaryCycleType,
      'salary_cycle_days': salaryCycleDays,
      'salary_cycle_start_day': salaryCycleStartDay,
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
      salaryCycleType: profile.salaryCycleType,
      salaryCycleDays: profile.salaryCycleDays,
      salaryCycleStartDay: profile.salaryCycleStartDay,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
