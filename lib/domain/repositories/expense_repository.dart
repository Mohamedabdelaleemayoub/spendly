import 'dart:io';
import '../entities/expense.dart';
import '../entities/expense_currency.dart';
import '../entities/governorate.dart';
import '../entities/trip_location_type.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    ExpenseCurrency? currency,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? searchQuery,
  });

  Future<Expense> getExpenseById(String id);

  Future<Expense> createExpense({
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  });

  Future<Expense> updateExpense({
    required String id,
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  });

  Future<void> deleteExpense(String id);

  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId, ExpenseCurrency? currency});

  Future<int> syncPendingExpenses({String? userId});
}
