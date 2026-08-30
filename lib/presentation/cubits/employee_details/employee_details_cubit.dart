import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/employee_travel_stats.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/governorate.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/travel_bonus_settings.dart';
import '../../../domain/entities/trip_location_type.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../dashboard/dashboard_state.dart';
import 'employee_details_state.dart';

class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit({
    required this.expenseRepository,
    required this.profileRepository,
    this.settingsRepository,
  }) : super(const EmployeeDetailsInitial());

  final ExpenseRepository expenseRepository;
  final ProfileRepository profileRepository;
  final SettingsRepository? settingsRepository;

  @override
  void emit(EmployeeDetailsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  List<Expense> _allEmployeeExpenses = [];
  Profile? _profile;
  TravelBonusSettings _bonusSettings = const TravelBonusSettings();

  String _searchQuery = '';
  ExpenseCurrency? _selectedCurrency;
  TripLocationType? _selectedTripLocationType;
  Governorate? _selectedGovernorate;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> loadEmployeeDetails(String employeeId, {Profile? initialProfile}) async {
    emit(const EmployeeDetailsLoading());
    try {
      // 1. Fetch Profile (always fetch latest from repository as authoritative source)
      var profile = await profileRepository.getProfile(employeeId);
      profile ??= initialProfile;

      if (profile == null) {
        emit(const EmployeeDetailsError('تعذر العثور على بيانات الموظف.'));
        return;
      }
      _profile = profile;

      // 2. Fetch travel bonus settings
      if (settingsRepository != null) {
        try {
          _bonusSettings = await settingsRepository!.getTravelBonusSettings();
        } catch (_) {}
      }

      // 3. Fetch all expenses for this employee
      final expenses = await expenseRepository.getExpenses(
        userId: employeeId,
        pageSize: 500,
      );
      _allEmployeeExpenses = expenses;

      // 4. Compute Multi-Currency Summary Statistics
      final now = DateTime.now();
      double totalEgp = 0.0;
      double totalUsd = 0.0;
      double thisMonthEgp = 0.0;
      double thisMonthUsd = 0.0;
      double todayEgp = 0.0;
      double todayUsd = 0.0;

      for (final exp in expenses) {
        if (exp.currency == ExpenseCurrency.usd) {
          totalUsd += exp.amount;
          if (exp.expenseDate.year == now.year && exp.expenseDate.month == now.month) {
            thisMonthUsd += exp.amount;
            if (exp.expenseDate.day == now.day) {
              todayUsd += exp.amount;
            }
          }
        } else {
          totalEgp += exp.amount;
          if (exp.expenseDate.year == now.year && exp.expenseDate.month == now.month) {
            thisMonthEgp += exp.amount;
            if (exp.expenseDate.day == now.day) {
              todayEgp += exp.amount;
            }
          }
        }
      }

      // 5. Apply current filters and compute Travel Stats
      final filtered = _applyFilters();
      final travelStats = EmployeeTravelStats.fromExpenses(filtered);

      emit(EmployeeDetailsLoaded(
        profile: _profile!,
        expenses: filtered,
        totalExpensesEgp: totalEgp,
        totalExpensesUsd: totalUsd,
        expensesCount: expenses.length,
        thisMonthExpensesEgp: thisMonthEgp,
        thisMonthExpensesUsd: thisMonthUsd,
        todayExpensesEgp: todayEgp,
        todayExpensesUsd: todayUsd,
        travelStats: travelStats,
        travelBonusSettings: _bonusSettings,
        searchQuery: _searchQuery,
        selectedCurrency: _selectedCurrency,
        selectedTripLocationType: _selectedTripLocationType,
        selectedGovernorate: _selectedGovernorate,
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

  void filterByCurrency(ExpenseCurrency? currency) {
    _selectedCurrency = currency;
    _reemitFiltered();
  }

  void filterByTripLocation(TripLocationType? type) {
    _selectedTripLocationType = type;
    if (type == TripLocationType.cairo) {
      _selectedGovernorate = null;
    }
    _reemitFiltered();
  }

  void filterByGovernorate(Governorate? gov) {
    _selectedGovernorate = gov;
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
    _selectedCurrency = null;
    _selectedTripLocationType = null;
    _selectedGovernorate = null;
    _selectedCategory = null;
    _selectedPaymentMethod = null;
    _startDate = null;
    _endDate = null;
    _reemitFiltered();
  }

  void updateProfileSalary(double amount, ExpenseCurrency currency) {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        salaryAmount: amount,
        salaryCurrency: currency,
      );
      final currentState = state;
      if (currentState is EmployeeDetailsLoaded) {
        emit(currentState.copyWith(profile: _profile!));
      }
    }
  }

  void _reemitFiltered() {
    final currentState = state;
    if (currentState is! EmployeeDetailsLoaded) return;

    final filtered = _applyFilters();
    final travelStats = EmployeeTravelStats.fromExpenses(filtered);

    emit(currentState.copyWith(
      expenses: filtered,
      travelStats: travelStats,
      searchQuery: _searchQuery,
      selectedCurrency: _selectedCurrency,
      selectedTripLocationType: _selectedTripLocationType,
      selectedGovernorate: _selectedGovernorate,
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

      // 2. Currency
      if (_selectedCurrency != null && exp.currency != _selectedCurrency) {
        return false;
      }

      // 3. Trip Location Type
      if (_selectedTripLocationType != null && exp.tripLocationType != _selectedTripLocationType) {
        return false;
      }

      // 4. Governorate
      if (_selectedGovernorate != null && exp.governorate != _selectedGovernorate) {
        return false;
      }

      // 5. Category
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (exp.categoryId != _selectedCategory) return false;
      }

      // 6. Payment Method
      if (_selectedPaymentMethod != null && _selectedPaymentMethod!.isNotEmpty) {
        if (exp.paymentMethod != _selectedPaymentMethod) return false;
      }

      // 7. Start Date
      if (_startDate != null) {
        final expDateOnly = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
        final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (expDateOnly.isBefore(startDateOnly)) return false;
      }

      // 8. End Date
      if (_endDate != null) {
        final expDateOnly = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
        final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (expDateOnly.isAfter(endDateOnly)) return false;
      }

      return true;
    }).toList();
  }
}
