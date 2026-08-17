import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit({required this.expenseRepository})
      : super(const ExpenseInitial());

  final ExpenseRepository expenseRepository;

  @override
  void emit(ExpenseState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  List<Expense> _expenses = [];
  int _currentPage = 0;
  bool _hasMore = true;
  String? _selectedCategory;
  String? _selectedUserId;
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> loadExpenses({
    bool refresh = false,
    String? categoryId,
    String? userId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _expenses = [];
      _hasMore = true;
      _selectedCategory = categoryId;
      _selectedUserId = userId;
      _searchQuery = searchQuery;
      _startDate = startDate;
      _endDate = endDate;
    }

    if (!refresh && state is ExpenseLoading) return;
    if (!refresh && !_hasMore) return;

    if (_currentPage == 0) {
      emit(const ExpenseLoading());
    }

    try {
      final fetched = await expenseRepository.getExpenses(
        page: _currentPage,
        pageSize: AppConstants.pageSize,
        categoryId: _selectedCategory,
        userId: _selectedUserId,
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (fetched.length < AppConstants.pageSize) {
        _hasMore = false;
      } else {
        _hasMore = true;
        _currentPage++;
      }

      if (refresh || _currentPage == 1) {
        _expenses = fetched;
      } else {
        _expenses = [..._expenses, ...fetched];
      }

      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        hasMore: _hasMore,
        page: _currentPage,
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      ));
    } on Failure catch (e) {
      emit(ExpenseError(e.message));
    } catch (e) {
      emit(ExpenseError('فشل تحميل المصروفات: $e'));
    }
  }

  Future<Expense?> getExpenseDetails(String id) async {
    try {
      final expense = await expenseRepository.getExpenseById(id);
      emit(ExpenseSingleLoaded(expense));
      return expense;
    } on Failure catch (e) {
      emit(ExpenseError(e.message));
      return null;
    } catch (e) {
      emit(ExpenseError('فشل تحميل تفاصيل المصروف: $e'));
      return null;
    }
  }

  Future<bool> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    emit(const ExpenseActionInProgress());
    try {
      final newExpense = await expenseRepository.createExpense(
        title: title,
        amount: amount,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        categoryId: categoryId,
        notes: notes,
        receiptFile: receiptFile,
      );

      _expenses = [newExpense, ..._expenses];
      emit(const ExpenseActionSuccess('تمت إضافة المصروف بنجاح'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        hasMore: _hasMore,
        page: _currentPage,
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      ));
      return true;
    } on Failure catch (e) {
      emit(ExpenseError(e.message));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    } catch (e) {
      emit(ExpenseError('فشل إضافة المصروف: $e'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    }
  }

  Future<bool> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) async {
    emit(const ExpenseActionInProgress());
    try {
      final updated = await expenseRepository.updateExpense(
        id: id,
        title: title,
        amount: amount,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        categoryId: categoryId,
        notes: notes,
        receiptFile: receiptFile,
        existingReceiptUrl: existingReceiptUrl,
      );

      _expenses = _expenses.map((e) => e.id == updated.id ? updated : e).toList();
      emit(const ExpenseActionSuccess('تم تعديل المصروف بنجاح'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        hasMore: _hasMore,
        page: _currentPage,
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      ));
      return true;
    } on Failure catch (e) {
      emit(ExpenseError(e.message));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    } catch (e) {
      emit(ExpenseError('فشل تعديل المصروف: $e'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await expenseRepository.deleteExpense(id);
      _expenses = _expenses.where((e) => e.id != id).toList();
      emit(const ExpenseActionSuccess('تم حذف المصروف بنجاح'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        hasMore: _hasMore,
        page: _currentPage,
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      ));
      return true;
    } on Failure catch (e) {
      emit(ExpenseError(e.message));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    } catch (e) {
      emit(ExpenseError('فشل حذف المصروف: $e'));
      emit(ExpenseLoaded(
        expenses: List.unmodifiable(_expenses),
        selectedCategoryId: _selectedCategory,
        selectedUserId: _selectedUserId,
        searchQuery: _searchQuery,
      ));
      return false;
    }
  }
}
