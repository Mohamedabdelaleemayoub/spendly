import 'package:equatable/equatable.dart';
import 'expense_currency.dart';

class EmployeeBalanceSummary extends Equatable {
  const EmployeeBalanceSummary({
    required this.userId,
    required this.name,
    this.email,
    this.role = 'employee',
    this.status = 'active',
    this.avatarUrl,
    required this.totalReceivedEgp,
    required this.totalSpentEgp,
    required this.availableBalanceEgp,
    required this.totalReceivedUsd,
    required this.totalSpentUsd,
    required this.availableBalanceUsd,
    this.lastAllowanceDate,
  });

  final String userId;
  final String name;
  final String? email;
  final String role;
  final String status;
  final String? avatarUrl;
  final double totalReceivedEgp;
  final double totalSpentEgp;
  final double availableBalanceEgp;
  final double totalReceivedUsd;
  final double totalSpentUsd;
  final double availableBalanceUsd;
  final DateTime? lastAllowanceDate;

  // Backward compatibility getters (mapping to EGP by default)
  double get totalReceived => totalReceivedEgp;
  double get totalSpent => totalSpentEgp;
  double get availableBalance => availableBalanceEgp;

  double availableBalanceFor(ExpenseCurrency currency) {
    switch (currency) {
      case ExpenseCurrency.egp:
        return availableBalanceEgp;
      case ExpenseCurrency.usd:
        return availableBalanceUsd;
    }
  }

  double totalReceivedFor(ExpenseCurrency currency) {
    switch (currency) {
      case ExpenseCurrency.egp:
        return totalReceivedEgp;
      case ExpenseCurrency.usd:
        return totalReceivedUsd;
    }
  }

  double totalSpentFor(ExpenseCurrency currency) {
    switch (currency) {
      case ExpenseCurrency.egp:
        return totalSpentEgp;
      case ExpenseCurrency.usd:
        return totalSpentUsd;
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
  bool get hasRemainingBalance => availableBalanceEgp > 0 || availableBalanceUsd > 0;

  EmployeeBalanceSummary copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    String? status,
    String? avatarUrl,
    double? totalReceivedEgp,
    double? totalSpentEgp,
    double? availableBalanceEgp,
    double? totalReceivedUsd,
    double? totalSpentUsd,
    double? availableBalanceUsd,
    DateTime? lastAllowanceDate,
  }) {
    return EmployeeBalanceSummary(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalReceivedEgp: totalReceivedEgp ?? this.totalReceivedEgp,
      totalSpentEgp: totalSpentEgp ?? this.totalSpentEgp,
      availableBalanceEgp: availableBalanceEgp ?? this.availableBalanceEgp,
      totalReceivedUsd: totalReceivedUsd ?? this.totalReceivedUsd,
      totalSpentUsd: totalSpentUsd ?? this.totalSpentUsd,
      availableBalanceUsd: availableBalanceUsd ?? this.availableBalanceUsd,
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
        totalReceivedEgp,
        totalSpentEgp,
        availableBalanceEgp,
        totalReceivedUsd,
        totalSpentUsd,
        availableBalanceUsd,
        lastAllowanceDate,
      ];
}
