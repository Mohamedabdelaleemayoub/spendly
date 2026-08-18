import '../../domain/entities/employee_balance_summary.dart';

class EmployeeBalanceSummaryModel extends EmployeeBalanceSummary {
  const EmployeeBalanceSummaryModel({
    required super.userId,
    required super.name,
    super.email,
    super.role = 'employee',
    super.status = 'active',
    super.avatarUrl,
    required super.totalReceivedEgp,
    required super.totalSpentEgp,
    required super.availableBalanceEgp,
    required super.totalReceivedUsd,
    required super.totalSpentUsd,
    required super.availableBalanceUsd,
    super.lastAllowanceDate,
  });

  factory EmployeeBalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0') ?? 0.0;
    }

    double egpRec = 0.0;
    double egpSp = 0.0;
    double egpAvail = 0.0;

    double usdRec = 0.0;
    double usdSp = 0.0;
    double usdAvail = 0.0;

    if (json['egp'] is Map<String, dynamic>) {
      final egpMap = json['egp'] as Map<String, dynamic>;
      egpRec = parseNum(egpMap['total_received']);
      egpSp = parseNum(egpMap['total_spent']);
      egpAvail = parseNum(egpMap['available_balance']);
    } else {
      egpRec = parseNum(json['egp_received'] ?? json['total_received']);
      egpSp = parseNum(json['egp_spent'] ?? json['total_spent']);
      egpAvail = parseNum(json['egp_available'] ?? json['available_balance']);
    }

    if (json['usd'] is Map<String, dynamic>) {
      final usdMap = json['usd'] as Map<String, dynamic>;
      usdRec = parseNum(usdMap['total_received']);
      usdSp = parseNum(usdMap['total_spent']);
      usdAvail = parseNum(usdMap['available_balance']);
    } else {
      usdRec = parseNum(json['usd_received']);
      usdSp = parseNum(json['usd_spent']);
      usdAvail = parseNum(json['usd_available']);
    }

    return EmployeeBalanceSummaryModel(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'موظف',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'employee',
      status: json['status'] as String? ?? 'active',
      avatarUrl: json['avatar_url'] as String?,
      totalReceivedEgp: egpRec,
      totalSpentEgp: egpSp,
      availableBalanceEgp: egpAvail,
      totalReceivedUsd: usdRec,
      totalSpentUsd: usdSp,
      availableBalanceUsd: usdAvail,
      lastAllowanceDate: json['last_allowance_date'] != null
          ? DateTime.tryParse(json['last_allowance_date'] as String)
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
      totalReceivedEgp: entity.totalReceivedEgp,
      totalSpentEgp: entity.totalSpentEgp,
      availableBalanceEgp: entity.availableBalanceEgp,
      totalReceivedUsd: entity.totalReceivedUsd,
      totalSpentUsd: entity.totalSpentUsd,
      availableBalanceUsd: entity.availableBalanceUsd,
      lastAllowanceDate: entity.lastAllowanceDate,
    );
  }
}
