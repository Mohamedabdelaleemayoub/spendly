import 'dart:io';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({required this.remoteDataSource});

  final ExpenseRemoteDataSource remoteDataSource;

  @override
  Future<List<Expense>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    String? searchQuery,
  }) {
    return remoteDataSource.getExpenses(
      page: page,
      pageSize: pageSize,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      userId: userId,
      paymentMethod: paymentMethod,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Expense> getExpenseById(String id) {
    return remoteDataSource.getExpenseById(id);
  }

  @override
  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) {
    return remoteDataSource.createExpense(
      title: title,
      amount: amount,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      categoryId: categoryId,
      notes: notes,
      receiptFile: receiptFile,
    );
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) {
    return remoteDataSource.updateExpense(
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
  }

  @override
  Future<void> deleteExpense(String id) {
    return remoteDataSource.deleteExpense(id);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId}) {
    return remoteDataSource.getExpensesForMonth(month, userId: userId);
  }
}
