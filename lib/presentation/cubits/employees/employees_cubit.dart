import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/employee_summary.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'employees_state.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit({required this.profileRepository})
      : super(const EmployeesInitial());

  final ProfileRepository profileRepository;

  @override
  void emit(EmployeesState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  List<EmployeeSummary> _allEmployees = [];
  String _currentSearch = '';
  String? _currentRoleFilter;
  String? _currentStatusFilter;

  Future<void> loadEmployees({String? actionMessage}) async {
    final currentState = state;
    if (currentState is! EmployeesLoaded) {
      emit(const EmployeesLoading());
    }

    try {
      final employees = await profileRepository.getEmployeesWithStats();
      _allEmployees = employees;

      double totalSpent = 0.0;
      int totalTransactions = 0;
      for (final emp in employees) {
        // Only count active employee expenses in company statistics
        if (emp.profile.isActive) {
          totalSpent += emp.totalExpenses;
          totalTransactions += emp.expensesCount;
        }
      }

      final filtered = _applyFilters(_allEmployees, _currentSearch, _currentRoleFilter, _currentStatusFilter);

      emit(EmployeesLoaded(
        employees: employees,
        filteredEmployees: filtered,
        searchQuery: _currentSearch,
        roleFilter: _currentRoleFilter,
        statusFilter: _currentStatusFilter,
        totalCompanySpent: totalSpent,
        totalCompanyTransactions: totalTransactions,
        isActionLoading: false,
        actionMessage: actionMessage,
      ));
    } on Failure catch (e) {
      emit(EmployeesError(e.message));
    } catch (e) {
      emit(EmployeesError('فشل تحميل قائمة الموظفين: $e'));
    }
  }

  void searchEmployees(String query) {
    _currentSearch = query;
    _reapplyFilters();
  }

  void filterByRole(String? role) {
    _currentRoleFilter = role;
    _reapplyFilters();
  }

  void filterByStatus(String? status) {
    _currentStatusFilter = status;
    _reapplyFilters();
  }

  void _reapplyFilters() {
    final currentState = state;
    if (currentState is! EmployeesLoaded) return;

    final filtered = _applyFilters(_allEmployees, _currentSearch, _currentRoleFilter, _currentStatusFilter);

    emit(currentState.copyWith(
      filteredEmployees: filtered,
      searchQuery: _currentSearch,
      roleFilter: _currentRoleFilter,
      statusFilter: _currentStatusFilter,
    ));
  }

  List<EmployeeSummary> _applyFilters(
    List<EmployeeSummary> list,
    String query,
    String? role,
    String? status,
  ) {
    final trimmed = query.trim().toLowerCase();

    return list.where((emp) {
      final matchesQuery = trimmed.isEmpty ||
          emp.profile.name.toLowerCase().contains(trimmed) ||
          (emp.profile.email?.toLowerCase().contains(trimmed) ?? false) ||
          emp.profile.id.toLowerCase().contains(trimmed);

      final matchesRole = role == null || role.isEmpty || emp.profile.role == role;
      final matchesStatus = status == null || status.isEmpty || emp.profile.status == status;

      return matchesQuery && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.createEmployee(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      await loadEmployees(actionMessage: 'تم إنشاء حساب المستخدم بنجاح');
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل إضافة المستخدم: $e'));
    }
  }

  Future<void> updateEmployeeRole(String userId, String newRole) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.updateEmployeeRole(userId, newRole);
      final msg = newRole == 'admin' ? 'تمت ترقية المستخدم إلى مدير بنجاح' : 'تم تحويل المستخدم إلى موظف بنجاح';
      await loadEmployees(actionMessage: msg);
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل تعديل الصلاحية: $e'));
    }
  }

  Future<void> toggleEmployeeStatus(String userId, String newStatus) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.toggleEmployeeStatus(userId, newStatus);
      final msg = newStatus == 'active' ? 'تم تفعيل حساب المستخدم بنجاح' : 'تم تعطيل حساب المستخدم بنجاح';
      await loadEmployees(actionMessage: msg);
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل تحديث حالة الحساب: $e'));
    }
  }

  Future<void> approveUser(String userId) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.approveUser(userId);
      await loadEmployees(actionMessage: 'تم اعتماد وتفعيل حساب المستخدم بنجاح');
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل اعتماد المستخدم: $e'));
    }
  }

  Future<void> rejectUser(String userId) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.rejectUser(userId);
      await loadEmployees(actionMessage: 'تم رفض طلب المستخدم');
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل رفض المستخدم: $e'));
    }
  }

  Future<void> deleteEmployee(String userId) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await profileRepository.deleteEmployee(userId);
      await loadEmployees(actionMessage: 'تم حذف حساب المستخدم بنجاح');
    } on Failure catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError(e.message));
    } catch (e) {
      if (currentState is EmployeesLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(EmployeesError('فشل حذف المستخدم: $e'));
    }
  }
}
