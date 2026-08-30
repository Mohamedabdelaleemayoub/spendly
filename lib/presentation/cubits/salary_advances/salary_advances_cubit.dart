import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/salary_advance_repository.dart';
import 'salary_advances_state.dart';

class SalaryAdvancesCubit extends Cubit<SalaryAdvancesState> {
  SalaryAdvancesCubit({
    required this.salaryAdvanceRepository,
    required this.profileRepository,
  }) : super(const SalaryAdvancesInitial());

  final SalaryAdvanceRepository salaryAdvanceRepository;
  final ProfileRepository profileRepository;

  @override
  void emit(SalaryAdvancesState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadSalaryAdvances(
    String userId, {
    double? initialSalary,
    ExpenseCurrency? initialCurrency,
  }) async {
    emit(const SalaryAdvancesLoading());
    try {
      double salary = initialSalary ?? 0.0;
      ExpenseCurrency currency = initialCurrency ?? ExpenseCurrency.egp;

      // Always fetch latest persisted profile from repository as authoritative source
      final profile = await profileRepository.getProfile(userId);
      if (profile != null) {
        salary = profile.salaryAmount;
        currency = profile.salaryCurrency;
      }

      final advances = await salaryAdvanceRepository.getSalaryAdvances(userId);

      emit(SalaryAdvancesLoaded(
        userId: userId,
        salaryAmount: salary,
        salaryCurrency: currency,
        advances: advances,
      ));
    } on Failure catch (e) {
      emit(SalaryAdvancesError(e.message));
    } catch (e) {
      emit(SalaryAdvancesError('فشل تحميل السلف والراتب: $e'));
    }
  }

  Future<void> addSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is SalaryAdvancesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      final newAdvance = await salaryAdvanceRepository.createSalaryAdvance(
        userId: userId,
        amount: amount,
        currency: currency,
        advanceDate: advanceDate,
        note: note,
      );

      if (currentState is SalaryAdvancesLoaded) {
        final updatedList = [newAdvance, ...currentState.advances];
        emit(currentState.copyWith(
          advances: updatedList,
          isActionLoading: false,
        ));
      } else {
        await loadSalaryAdvances(userId);
      }
    } on Failure catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError(e.message));
    } catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError('فشل إضافة السلفة: $e'));
    }
  }

  Future<void> updateSalaryAdvance({
    required String id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is SalaryAdvancesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      final updated = await salaryAdvanceRepository.updateSalaryAdvance(
        id: id,
        amount: amount,
        currency: currency,
        advanceDate: advanceDate,
        note: note,
      );

      if (currentState is SalaryAdvancesLoaded) {
        final updatedList = currentState.advances.map((item) {
          return item.id == id ? updated : item;
        }).toList();

        emit(currentState.copyWith(
          advances: updatedList,
          isActionLoading: false,
        ));
      } else {
        await loadSalaryAdvances(userId);
      }
    } on Failure catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError(e.message));
    } catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError('فشل تعديل السلفة: $e'));
    }
  }

  Future<void> deleteSalaryAdvance(String id, String userId) async {
    final currentState = state;
    if (currentState is SalaryAdvancesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryAdvanceRepository.deleteSalaryAdvance(id);

      if (currentState is SalaryAdvancesLoaded) {
        final updatedList = currentState.advances.where((item) => item.id != id).toList();
        emit(currentState.copyWith(
          advances: updatedList,
          isActionLoading: false,
        ));
      } else {
        await loadSalaryAdvances(userId);
      }
    } on Failure catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError(e.message));
    } catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError('فشل حذف السلفة: $e'));
    }
  }

  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  }) async {
    final currentState = state;
    if (currentState is SalaryAdvancesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await salaryAdvanceRepository.updateEmployeeSalary(
        userId: userId,
        salaryAmount: salaryAmount,
        salaryCurrency: salaryCurrency,
      );

      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(
          salaryAmount: salaryAmount,
          salaryCurrency: salaryCurrency,
          isActionLoading: false,
        ));
      } else {
        await loadSalaryAdvances(userId);
      }
    } on Failure catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError(e.message));
    } catch (e) {
      if (currentState is SalaryAdvancesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(SalaryAdvancesError('فشل تعديل راتب الموظف: $e'));
    }
  }
}
