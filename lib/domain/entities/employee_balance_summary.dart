import 'package:equatable/equatable.dart';

class EmployeeBalanceSummary extends Equatable {
  const EmployeeBalanceSummary({
    required this.userId,
    required this.name,
    this.email,
    this.role = 'employee',
    this.status = 'active',
    this.avatarUrl,
    required this.totalReceived,
    required this.totalSpent,
    required this.availableBalance,
    this.lastAllowanceDate,
  });

  final String userId;
  final String name;
  final String? email;
  final String role;
  final String status;
  final String? avatarUrl;
  final double totalReceived;
  final double totalSpent;
  final double availableBalance;
  final DateTime? lastAllowanceDate;

  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
  bool get hasRemainingBalance => availableBalance > 0;

  EmployeeBalanceSummary copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    String? status,
    String? avatarUrl,
    double? totalReceived,
    double? totalSpent,
    double? availableBalance,
    DateTime? lastAllowanceDate,
  }) {
    return EmployeeBalanceSummary(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalReceived: totalReceived ?? this.totalReceived,
      totalSpent: totalSpent ?? this.totalSpent,
      availableBalance: availableBalance ?? this.availableBalance,
      lastAllowanceDate: lastAllowanceDate ?? this.lastAllowanceDate,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        role,
        status,
        avatarUrl,
        totalReceived,
        totalSpent,
        availableBalance,
        lastAllowanceDate,
      ];
}
