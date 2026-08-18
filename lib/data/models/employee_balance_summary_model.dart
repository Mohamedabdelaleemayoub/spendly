import '../../domain/entities/employee_balance_summary.dart';

class EmployeeBalanceSummaryModel extends EmployeeBalanceSummary {
  const EmployeeBalanceSummaryModel({
    required super.userId,
    required super.name,
    super.email,
    super.role = 'employee',
    super.status = 'active',
    super.avatarUrl,
    required super.totalReceived,
    required super.totalSpent,
    required super.availableBalance,
    super.lastAllowanceDate,
  });

  factory EmployeeBalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return EmployeeBalanceSummaryModel(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? 'موظف',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'employee',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      totalReceived: (json['total_received'] is num)
          ? (json['total_received'] as num).toDouble()
          : double.tryParse(json['total_received']?.toString() ?? '0') ?? 0.0,
      totalSpent: (json['total_spent'] is num)
          ? (json['total_spent'] as num).toDouble()
          : double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
      availableBalance: (json['available_balance'] is num)
          ? (json['available_balance'] as num).toDouble()
          : double.tryParse(json['available_balance']?.toString() ?? '0') ?? 0.0,
      lastAllowanceDate: json['last_allowance_date'] != null
          ? DateTime.parse(json['last_allowance_date'] as String)
          : null,
    );
  }

  factory EmployeeBalanceSummaryModel.fromEntity(EmployeeBalanceSummary entity) {
    return EmployeeBalanceSummaryModel(
      userId: entity.userId,
      name: entity.name,
      email: entity.email,
      role: entity.role,
      status: entity.status,
      avatarUrl: entity.avatarUrl,
      totalReceived: entity.totalReceived,
      totalSpent: entity.totalSpent,
      availableBalance: entity.availableBalance,
      lastAllowanceDate: entity.lastAllowanceDate,
    );
  }
}
