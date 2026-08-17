import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/profile.dart';

sealed class EmployeeDetailsState extends Equatable {
  const EmployeeDetailsState();

  @override
  List<Object?> get props => [];
}

class EmployeeDetailsInitial extends EmployeeDetailsState {
  const EmployeeDetailsInitial();
}

class EmployeeDetailsLoading extends EmployeeDetailsState {
  const EmployeeDetailsLoading();
}

class EmployeeDetailsLoaded extends EmployeeDetailsState {
  const EmployeeDetailsLoaded({
    required this.profile,
    required this.expenses,
    required this.totalExpenses,
    required this.expensesCount,
    required this.thisMonthExpenses,
    required this.todayExpenses,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedPaymentMethod,
    this.selectedStartDate,
    this.selectedEndDate,
    this.isFiltering = false,
  });

  final Profile profile;
  final List<Expense> expenses;
  final double totalExpenses;
  final int expensesCount;
  final double thisMonthExpenses;
  final double todayExpenses;

  // Filter state
  final String searchQuery;
  final String? selectedCategoryId;
  final String? selectedPaymentMethod;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final bool isFiltering;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategoryId != null ||
      selectedPaymentMethod != null ||
      selectedStartDate != null ||
      selectedEndDate != null;

  EmployeeDetailsLoaded copyWith({
    Profile? profile,
    List<Expense>? expenses,
    double? totalExpenses,
    int? expensesCount,
    double? thisMonthExpenses,
    double? todayExpenses,
    String? searchQuery,
    String? selectedCategoryId,
    String? selectedPaymentMethod,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    bool? isFiltering,
  }) {
    return EmployeeDetailsLoaded(
      profile: profile ?? this.profile,
      expenses: expenses ?? this.expenses,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expensesCount: expensesCount ?? this.expensesCount,
      thisMonthExpenses: thisMonthExpenses ?? this.thisMonthExpenses,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId,
      selectedPaymentMethod: selectedPaymentMethod,
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        expenses,
        totalExpenses,
        expensesCount,
        thisMonthExpenses,
        todayExpenses,
        searchQuery,
        selectedCategoryId,
        selectedPaymentMethod,
        selectedStartDate,
        selectedEndDate,
        isFiltering,
      ];
}

class EmployeeDetailsError extends EmployeeDetailsState {
  const EmployeeDetailsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
