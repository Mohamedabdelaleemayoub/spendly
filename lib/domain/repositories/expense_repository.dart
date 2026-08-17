import 'dart:io';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    String? searchQuery,
  });

  Future<Expense> getExpenseById(String id);

  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  });

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
  });

  Future<void> deleteExpense(String id);

  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId});
}
