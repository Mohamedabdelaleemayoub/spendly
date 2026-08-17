import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    String? searchQuery,
  });

  Future<ExpenseModel> getExpenseById(String id);

  Future<ExpenseModel> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  });

  Future<ExpenseModel> updateExpense({
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

  Future<List<ExpenseModel>> getExpensesForMonth(DateTime month, {String? userId});
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  ExpenseRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  /// Standard PostgREST resource embedding referencing explicit foreign keys.
  static const String _selectColumns = '''
    *,
    categories:categories!expenses_category_id_fkey(
      id,
      name,
      icon,
      color
    ),
    profiles:profiles!expenses_user_id_fkey(
      id,
      full_name,
      email,
      role
    )
  ''';

  @override
  Future<List<ExpenseModel>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    String? searchQuery,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      var query = client
          .from(AppConstants.expensesTable)
          .select(_selectColumns);

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        query = query.eq('payment_method', paymentMethod);
      }

      if (startDate != null) {
        final startStr =
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.gte('expense_date', startStr);
      }

      if (endDate != null) {
        final endStr =
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.lte('expense_date', endStr);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('title', '%${searchQuery.trim()}%');
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('expense_date', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final response = await client
          .from(AppConstants.expensesTable)
          .select(_selectColumns)
          .eq('id', id)
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseModel> createExpense({
    required String title,
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw const AuthException('User not authenticated');
      }

      String? receiptUrl;
      if (receiptFile != null) {
        receiptUrl = await _uploadReceipt(user.id, receiptFile);
      }

      final insertData = <String, dynamic>{
        'user_id': user.id,
        'title': title.trim(),
        'description': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : title.trim(),
        'amount': amount,
        'payment_method': paymentMethod,
        'expense_date':
            '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      };
      if (categoryId != null) insertData['category_id'] = categoryId;
      if (notes != null && notes.trim().isNotEmpty) insertData['notes'] = notes.trim();
      if (receiptUrl != null) insertData['receipt_url'] = receiptUrl;

      final response = await client
          .from(AppConstants.expensesTable)
          .insert(insertData)
          .select(_selectColumns)
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseModel> updateExpense({
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
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw const AuthException('User not authenticated');
      }

      String? receiptUrl = existingReceiptUrl;
      if (receiptFile != null) {
        receiptUrl = await _uploadReceipt(user.id, receiptFile);
      }

      final updateData = {
        'category_id': categoryId,
        'title': title.trim(),
        'description': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : title.trim(),
        'amount': amount,
        'payment_method': paymentMethod,
        'expense_date':
            '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
        'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
        'receipt_url': receiptUrl,
      };

      final response = await client
          .from(AppConstants.expensesTable)
          .update(updateData)
          .eq('id', id)
          .select(_selectColumns)
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await client
          .from(AppConstants.expensesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesForMonth(DateTime month, {String? userId}) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final startStr =
          '${firstDay.year.toString().padLeft(4, '0')}-${firstDay.month.toString().padLeft(2, '0')}-01';
      final endStr =
          '${lastDay.year.toString().padLeft(4, '0')}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

      var query = client
          .from(AppConstants.expensesTable)
          .select(_selectColumns)
          .gte('expense_date', startStr)
          .lte('expense_date', endStr);

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('expense_date', ascending: false);

      return (response as List<dynamic>)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  Future<String> _uploadReceipt(String userId, File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
    final path = '$userId/$fileName';

    await client.storage.from(AppConstants.receiptsBucket).upload(path, file);
    final publicUrl = client.storage.from(AppConstants.receiptsBucket).getPublicUrl(path);
    return publicUrl;
  }
}
