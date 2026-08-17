import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';

class CategorySpending extends Equatable {
  const CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  final String name;
  final double amount;
  final String color;
  final String icon;
  final double percentage;

  @override
  List<Object?> get props => [name, amount, color, icon, percentage];
}

class EmployeeSpending extends Equatable {
  const EmployeeSpending({
    required this.userId,
    required this.name,
    required this.email,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  final String userId;
  final String name;
  final String? email;
  final double amount;
  final int count;
  final double percentage;

  @override
  List<Object?> get props => [userId, name, email, amount, count, percentage];
}

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.isAdmin,
    required this.totalThisMonth,
    required this.totalToday,
    required this.countThisMonth,
    required this.employeeCount,
    required this.recentExpenses,
    required this.categorySpending,
    this.employeeSpending = const [],
  });

  final bool isAdmin;
  final double totalThisMonth;
  final double totalToday;
  final int countThisMonth;
  final int employeeCount;
  final List<Expense> recentExpenses;
  final List<CategorySpending> categorySpending;
  final List<EmployeeSpending> employeeSpending;

  @override
  List<Object?> get props => [
        isAdmin,
        totalThisMonth,
        totalToday,
        countThisMonth,
        employeeCount,
        recentExpenses,
        categorySpending,
        employeeSpending,
      ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
