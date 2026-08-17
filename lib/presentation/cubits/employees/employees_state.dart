import 'package:equatable/equatable.dart';
import '../../../domain/entities/employee_summary.dart';

sealed class EmployeesState extends Equatable {
  const EmployeesState();

  @override
  List<Object?> get props => [];
}

class EmployeesInitial extends EmployeesState {
  const EmployeesInitial();
}

class EmployeesLoading extends EmployeesState {
  const EmployeesLoading();
}

class EmployeesLoaded extends EmployeesState {
  const EmployeesLoaded({
    required this.employees,
    required this.filteredEmployees,
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
    this.totalCompanySpent = 0.0,
    this.totalCompanyTransactions = 0,
    this.isActionLoading = false,
    this.actionMessage,
  });

  final List<EmployeeSummary> employees;
  final List<EmployeeSummary> filteredEmployees;
  final String searchQuery;
  final String? roleFilter;
  final String? statusFilter;
  final double totalCompanySpent;
  final int totalCompanyTransactions;
  final bool isActionLoading;
  final String? actionMessage;

  EmployeesLoaded copyWith({
    List<EmployeeSummary>? employees,
    List<EmployeeSummary>? filteredEmployees,
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
    double? totalCompanySpent,
    int? totalCompanyTransactions,
    bool? isActionLoading,
    String? actionMessage,
  }) {
    return EmployeesLoaded(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      totalCompanySpent: totalCompanySpent ?? this.totalCompanySpent,
      totalCompanyTransactions: totalCompanyTransactions ?? this.totalCompanyTransactions,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        employees,
        filteredEmployees,
        searchQuery,
        roleFilter,
        statusFilter,
        totalCompanySpent,
        totalCompanyTransactions,
        isActionLoading,
        actionMessage,
      ];
}

class EmployeesError extends EmployeesState {
  const EmployeesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
