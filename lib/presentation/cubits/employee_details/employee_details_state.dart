import 'package:equatable/equatable.dart';
import '../../../domain/entities/employee_travel_stats.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/governorate.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/travel_bonus_settings.dart';
import '../../../domain/entities/trip_location_type.dart';

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
    required this.totalExpensesEgp,
    required this.totalExpensesUsd,
    required this.expensesCount,
    required this.thisMonthExpensesEgp,
    required this.thisMonthExpensesUsd,
    required this.todayExpensesEgp,
    required this.todayExpensesUsd,
    required this.travelStats,
    this.travelBonusSettings = const TravelBonusSettings(),
    this.searchQuery = '',
    this.selectedCurrency,
    this.selectedTripLocationType,
    this.selectedGovernorate,
    this.selectedCategoryId,
    this.selectedPaymentMethod,
    this.selectedStartDate,
    this.selectedEndDate,
    this.isFiltering = false,
  });

  final Profile profile;
  final List<Expense> expenses;
  final double totalExpensesEgp;
  final double totalExpensesUsd;
  final int expensesCount;
  final double thisMonthExpensesEgp;
  final double thisMonthExpensesUsd;
  final double todayExpensesEgp;
  final double todayExpensesUsd;
  final EmployeeTravelStats travelStats;
  final TravelBonusSettings travelBonusSettings;

  // Backward-compatibility getters (defaulting to EGP)
  double get totalExpenses => totalExpensesEgp;
  double get thisMonthExpenses => thisMonthExpensesEgp;
  double get todayExpenses => todayExpensesEgp;

  // Filter state
  final String searchQuery;
  final ExpenseCurrency? selectedCurrency;
  final TripLocationType? selectedTripLocationType;
  final Governorate? selectedGovernorate;
  final String? selectedCategoryId;
  final String? selectedPaymentMethod;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final bool isFiltering;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCurrency != null ||
      selectedTripLocationType != null ||
      selectedGovernorate != null ||
      selectedCategoryId != null ||
      selectedPaymentMethod != null ||
      selectedStartDate != null ||
      selectedEndDate != null;

  EmployeeDetailsLoaded copyWith({
    Profile? profile,
    List<Expense>? expenses,
    double? totalExpensesEgp,
    double? totalExpensesUsd,
    int? expensesCount,
    double? thisMonthExpensesEgp,
    double? thisMonthExpensesUsd,
    double? todayExpensesEgp,
    double? todayExpensesUsd,
    EmployeeTravelStats? travelStats,
    TravelBonusSettings? travelBonusSettings,
    String? searchQuery,
    ExpenseCurrency? selectedCurrency,
    TripLocationType? selectedTripLocationType,
    Governorate? selectedGovernorate,
    String? selectedCategoryId,
    String? selectedPaymentMethod,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    bool? isFiltering,
  }) {
    return EmployeeDetailsLoaded(
      profile: profile ?? this.profile,
      expenses: expenses ?? this.expenses,
      totalExpensesEgp: totalExpensesEgp ?? this.totalExpensesEgp,
      totalExpensesUsd: totalExpensesUsd ?? this.totalExpensesUsd,
      expensesCount: expensesCount ?? this.expensesCount,
      thisMonthExpensesEgp: thisMonthExpensesEgp ?? this.thisMonthExpensesEgp,
      thisMonthExpensesUsd: thisMonthExpensesUsd ?? this.thisMonthExpensesUsd,
      todayExpensesEgp: todayExpensesEgp ?? this.todayExpensesEgp,
      todayExpensesUsd: todayExpensesUsd ?? this.todayExpensesUsd,
      travelStats: travelStats ?? this.travelStats,
      travelBonusSettings: travelBonusSettings ?? this.travelBonusSettings,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCurrency: selectedCurrency,
      selectedTripLocationType: selectedTripLocationType,
      selectedGovernorate: selectedGovernorate,
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
        totalExpensesEgp,
        totalExpensesUsd,
        expensesCount,
        thisMonthExpensesEgp,
        thisMonthExpensesUsd,
        todayExpensesEgp,
        todayExpensesUsd,
        travelStats,
        travelBonusSettings,
        searchQuery,
        selectedCurrency,
        selectedTripLocationType,
        selectedGovernorate,
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
