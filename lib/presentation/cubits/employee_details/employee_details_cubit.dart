import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../dashboard/dashboard_state.dart';
import 'employee_details_state.dart';

class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit({
    required this.expenseRepository,
    required this.profileRepository,
  }) : super(const EmployeeDetailsInitial());

  final ExpenseRepository expenseRepository;
  final ProfileRepository profileRepository;

  @override
  void emit(EmployeeDetailsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  List<Expense> _allEmployeeExpenses = [];
  Profile? _profile;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> loadEmployeeDetails(String employeeId, {Profile? initialProfile}) async {
    emit(const EmployeeDetailsLoading());
    try {
      // 1. Fetch Profile
      var profile = initialProfile;
      profile ??= await profileRepository.getProfile(employeeId);

      if (profile == null) {
        emit(const EmployeeDetailsError('تعذر العثور على بيانات الموظف.'));
        return;
      }
      _profile = profile;

      // 2. Fetch all expenses for this employee
      final expenses = await expenseRepository.getExpenses(
        userId: employeeId,
        pageSize: 500,
      );
      _allEmployeeExpenses = expenses;

      // 3. Compute Summary Statistics
      final now = DateTime.now();
      double total = 0.0;
      double thisMonth = 0.0;
      double today = 0.0;

      for (final exp in expenses) {
        total += exp.amount;
        if (exp.expenseDate.year == now.year && exp.expenseDate.month == now.month) {
          thisMonth += exp.amount;
          if (exp.expenseDate.day == now.day) {
            today += exp.amount;
          }
        }
      }

      // 4. Apply current filters
      final filtered = _applyFilters();

      emit(EmployeeDetailsLoaded(
        profile: _profile!,
        expenses: filtered,
        totalExpenses: total,
        expensesCount: expenses.length,
        thisMonthExpenses: thisMonth,
        todayExpenses: today,
        searchQuery: _searchQuery,
        selectedCategoryId: _selectedCategory,
        selectedPaymentMethod: _selectedPaymentMethod,
        selectedStartDate: _startDate,
        selectedEndDate: _endDate,
      ));
    } on Failure catch (e) {
      emit(EmployeeDetailsError(e.message));
    } catch (e) {
      emit(EmployeeDetailsError('فشل تحميل تفاصيل الموظف: $e'));
    }
  }

  void searchExpenses(String query) {
    _searchQuery = query;
    _reemitFiltered();
  }

  void filterByCategory(String? categoryId) {
    _selectedCategory = categoryId;
    _reemitFiltered();
  }

  void filterByPaymentMethod(String? paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    _reemitFiltered();
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _reemitFiltered();
  }

  void filterByPeriod(ExpenseSummaryPeriod? period) {
    if (period == null) {
      _startDate = null;
      _endDate = null;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      switch (period) {
        case ExpenseSummaryPeriod.today:
          _startDate = today;
          _endDate = today;
          break;
        case ExpenseSummaryPeriod.week:
          final daysSinceSaturday = (now.weekday + 1) % 7;
          _startDate = today.subtract(Duration(days: daysSinceSaturday));
          _endDate = today;
          break;
        case ExpenseSummaryPeriod.month:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = today;
          break;
      }
    }
    _reemitFiltered();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPaymentMethod = null;
    _startDate = null;
    _endDate = null;
    _reemitFiltered();
  }

  void _reemitFiltered() {
    final currentState = state;
    if (currentState is! EmployeeDetailsLoaded) return;

    final filtered = _applyFilters();

    emit(currentState.copyWith(
      expenses: filtered,
      searchQuery: _searchQuery,
      selectedCategoryId: _selectedCategory,
      selectedPaymentMethod: _selectedPaymentMethod,
      selectedStartDate: _startDate,
      selectedEndDate: _endDate,
    ));
  }

  List<Expense> _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    return _allEmployeeExpenses.where((exp) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final titleMatches = exp.title.toLowerCase().contains(query);
        final notesMatches = exp.notes?.toLowerCase().contains(query) ?? false;
        if (!titleMatches && !notesMatches) return false;
      }

      // 2. Category
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (exp.categoryId != _selectedCategory) return false;
      }

      // 3. Payment Method
      if (_selectedPaymentMethod != null && _selectedPaymentMethod!.isNotEmpty) {
        if (exp.paymentMethod != _selectedPaymentMethod) return false;
      }

      // 4. Start Date
      if (_startDate != null) {
        final expDateOnly = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
        final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (expDateOnly.isBefore(startDateOnly)) return false;
      }

      // 5. End Date
      if (_endDate != null) {
        final expDateOnly = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
        final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (expDateOnly.isAfter(endDateOnly)) return false;
      }

      return true;
    }).toList();
  }
}
