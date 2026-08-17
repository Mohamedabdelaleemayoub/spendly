import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';

sealed class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded({
    required this.expenses,
    this.hasMore = false,
    this.page = 0,
    this.selectedCategoryId,
    this.selectedUserId,
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  final List<Expense> expenses;
  final bool hasMore;
  final int page;
  final String? selectedCategoryId;
  final String? selectedUserId;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  ExpenseLoaded copyWith({
    List<Expense>? expenses,
    bool? hasMore,
    int? page,
    String? selectedCategoryId,
    String? selectedUserId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        hasMore,
        page,
        selectedCategoryId,
        selectedUserId,
        searchQuery,
        startDate,
        endDate,
      ];
}

class ExpenseActionInProgress extends ExpenseState {
  const ExpenseActionInProgress();
}

class ExpenseActionSuccess extends ExpenseState {
  const ExpenseActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ExpenseSingleLoaded extends ExpenseState {
  const ExpenseSingleLoaded(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
