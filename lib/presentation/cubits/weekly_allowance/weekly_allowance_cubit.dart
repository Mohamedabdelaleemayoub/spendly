import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/repositories/weekly_allowance_repository.dart';
import 'weekly_allowance_state.dart';

class WeeklyAllowanceCubit extends Cubit<WeeklyAllowanceState> {
  WeeklyAllowanceCubit({
    required this.weeklyAllowanceRepository,
  }) : super(const WeeklyAllowanceInitial());

  final WeeklyAllowanceRepository weeklyAllowanceRepository;

  WeeklyDateRange _currentWeekRange = DateTimeUtils.getThisWeekRange();
  WeeklyPeriodSelection _currentSelection = WeeklyPeriodSelection.thisWeek;
  ExpenseCurrency _currentCurrency = ExpenseCurrency.egp;
  String? _currentUserId;

  @override
  void emit(WeeklyAllowanceState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadWeeklyAllowance(
    String userId, {
    WeeklyPeriodSelection? periodSelection,
    WeeklyDateRange? customRange,
    ExpenseCurrency? currency,
  }) async {
    _currentUserId = userId;
    if (periodSelection != null) _currentSelection = periodSelection;
    if (currency != null) _currentCurrency = currency;

    if (customRange != null) {
      _currentWeekRange = customRange;
      _currentSelection = WeeklyPeriodSelection.custom;
    } else {
      switch (_currentSelection) {
        case WeeklyPeriodSelection.thisWeek:
          _currentWeekRange = DateTimeUtils.getThisWeekRange();
          break;
        case WeeklyPeriodSelection.previousWeek:
          _currentWeekRange = DateTimeUtils.getPreviousWeekRange();
          break;
        case WeeklyPeriodSelection.nextWeek:
          _currentWeekRange = DateTimeUtils.getNextWeekRange();
          break;
        case WeeklyPeriodSelection.custom:
          break;
      }
    }

    emit(const WeeklyAllowanceLoading());

    try {
      final summary = await weeklyAllowanceRepository.getWeeklyWorkBudgetSummary(
        userId: userId,
        startDate: _currentWeekRange.start,
        endDate: _currentWeekRange.end,
      );

      final transactions = await weeklyAllowanceRepository.getWeeklyAllowanceTransactions(
        userId: userId,
        startDate: _currentWeekRange.start,
        endDate: _currentWeekRange.end,
      );

      emit(WeeklyAllowanceLoaded(
        userId: userId,
        weekRange: _currentWeekRange,
        periodSelection: _currentSelection,
        selectedCurrency: _currentCurrency,
        summary: summary,
        transactions: transactions,
      ));
    } on Failure catch (e) {
      emit(WeeklyAllowanceError(e.message));
    } catch (e) {
      emit(WeeklyAllowanceError('فشل تحميل ميزانية العمل الأسبوعية: $e'));
    }
  }

  void changeCurrency(ExpenseCurrency currency) {
    _currentCurrency = currency;
    final currentState = state;
    if (currentState is WeeklyAllowanceLoaded) {
      emit(currentState.copyWith(selectedCurrency: currency));
    }
  }

  Future<void> selectPeriod(WeeklyPeriodSelection selection, {WeeklyDateRange? customRange}) async {
    if (_currentUserId == null) return;
    await loadWeeklyAllowance(
      _currentUserId!,
      periodSelection: selection,
      customRange: customRange,
    );
  }

  Future<void> addAllowance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is WeeklyAllowanceLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await weeklyAllowanceRepository.createAllowanceTransaction(
        userId: userId,
        amount: amount,
        currency: currency,
        transactionDate: transactionDate,
        note: note,
      );

      // Reload full week data to guarantee all calculations update dynamically
      await loadWeeklyAllowance(userId);
    } on Failure catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError(e.message));
    } catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError('فشل إضافة العهدة: $e'));
    }
  }

  Future<void> updateAllowance({
    required String id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is WeeklyAllowanceLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await weeklyAllowanceRepository.updateAllowanceTransaction(
        id: id,
        amount: amount,
        currency: currency,
        transactionDate: transactionDate,
        note: note,
      );

      // Reload full week data to recalculate both weeks if date moved
      await loadWeeklyAllowance(userId);
    } on Failure catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError(e.message));
    } catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError('فشل تعديل العهدة: $e'));
    }
  }

  Future<void> deleteAllowance(String id, String userId) async {
    final currentState = state;
    if (currentState is WeeklyAllowanceLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await weeklyAllowanceRepository.deleteAllowanceTransaction(id);
      await loadWeeklyAllowance(userId);
    } on Failure catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError(e.message));
    } catch (e) {
      if (currentState is WeeklyAllowanceLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(WeeklyAllowanceError('فشل حذف العهدة: $e'));
    }
  }
}
