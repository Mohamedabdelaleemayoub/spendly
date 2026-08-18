import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/trip_location_type.dart';
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
    ExpenseCurrency? currency,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? searchQuery,
  });

  Future<ExpenseModel> getExpenseById(String id);

  Future<ExpenseModel> createExpense({
    String? id,
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

  Future<ExpenseModel> updateExpense({
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

  Future<ExpenseModel> upsertExpense(ExpenseModel expense);

  Future<void> deleteExpense(String id);

  Future<List<ExpenseModel>> getExpensesForMonth(DateTime month, {String? userId, ExpenseCurrency? currency});
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
    ExpenseCurrency? currency,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? searchQuery,
  }) async {
    try {
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

      if (currency != null) {
        query = query.eq('currency', currency.toDbString());
      }

      if (tripLocationType != null) {
        query = query.eq('trip_location_type', tripLocationType.toDbString());
      }

      if (governorate != null) {
        query = query.eq('governorate', governorate.toDbString());
      }

      if (startDate != null) {
        final formattedStart =
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.gte('expense_date', formattedStart);
      }

      if (endDate != null) {
        final formattedEnd =
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.lte('expense_date', formattedEnd);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,description.ilike.%$q%,notes.ilike.%$q%');
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await query
          .order('expense_date', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> list = response as List<dynamic>;
      return list
          .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback: If filtered on currency/trip_location_type but column does not exist on schema yet
      if (e is PostgrestException && (e.code == '42703' || e.message.contains('does not exist'))) {
        try {
          var simpleQuery = client
              .from(AppConstants.expensesTable)
              .select(_selectColumns);

          if (userId != null && userId.isNotEmpty) {
            simpleQuery = simpleQuery.eq('user_id', userId);
          }
          if (categoryId != null && categoryId.isNotEmpty) {
            simpleQuery = simpleQuery.eq('category_id', categoryId);
          }
          if (startDate != null) {
            final formattedStart =
                '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
            simpleQuery = simpleQuery.gte('expense_date', formattedStart);
          }
          if (endDate != null) {
            final formattedEnd =
                '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
            simpleQuery = simpleQuery.lte('expense_date', formattedEnd);
          }

          final from = page * pageSize;
          final to = from + pageSize - 1;

          final response = await simpleQuery
              .order('expense_date', ascending: false)
              .order('created_at', ascending: false)
              .range(from, to);

          final List<dynamic> list = response as List<dynamic>;
          return list
              .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
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
    String? id,
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

      final effectiveGov = tripLocationType == TripLocationType.cairo
          ? Governorate.cairo
          : governorate;

      final insertData = <String, dynamic>{
        'id': ?id,
        'user_id': user.id,
        'title': title.trim(),
        'description': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : title.trim(),
        'amount': amount,
        'currency': currency.toDbString(),
        'trip_location_type': tripLocationType.toDbString(),
        'governorate': effectiveGov.toDbString(),
        'payment_method': paymentMethod,
        'expense_date':
            '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
        'category_id': ?categoryId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'receipt_url': ?receiptUrl,
      };

      final response = await client
          .from(AppConstants.expensesTable)
          .upsert(insertData, onConflict: 'id')
          .select(_selectColumns)
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseModel> upsertExpense(ExpenseModel expense) async {
    try {
      final response = await client
          .from(AppConstants.expensesTable)
          .upsert(expense.toJson(includeId: true), onConflict: 'id')
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

      final effectiveGov = tripLocationType == TripLocationType.cairo
          ? Governorate.cairo
          : governorate;

      final updateData = {
        'category_id': categoryId,
        'title': title.trim(),
        'description': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : title.trim(),
        'amount': amount,
        'currency': currency.toDbString(),
        'trip_location_type': tripLocationType.toDbString(),
        'governorate': effectiveGov.toDbString(),
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
      await client.from(AppConstants.expensesTable).delete().eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesForMonth(DateTime month, {String? userId, ExpenseCurrency? currency}) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final startStr =
          '${startOfMonth.year.toString().padLeft(4, '0')}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
      final endStr =
          '${endOfMonth.year.toString().padLeft(4, '0')}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

      var query = client
          .from(AppConstants.expensesTable)
          .select(_selectColumns)
          .gte('expense_date', startStr)
          .lte('expense_date', endStr);

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      if (currency != null) {
        query = query.eq('currency', currency.toDbString());
      }

      final response = await query
          .order('expense_date', ascending: false)
          .order('created_at', ascending: false);

      final List<dynamic> list = response as List<dynamic>;
      return list
          .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is PostgrestException && (e.code == '42703' || e.message.contains('does not exist'))) {
        try {
          final startOfMonth = DateTime(month.year, month.month, 1);
          final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
          final startStr =
              '${startOfMonth.year.toString().padLeft(4, '0')}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
          final endStr =
              '${endOfMonth.year.toString().padLeft(4, '0')}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

          var simpleQuery = client
              .from(AppConstants.expensesTable)
              .select(_selectColumns)
              .gte('expense_date', startStr)
              .lte('expense_date', endStr);

          if (userId != null && userId.isNotEmpty) {
            simpleQuery = simpleQuery.eq('user_id', userId);
          }

          final response = await simpleQuery
              .order('expense_date', ascending: false)
              .order('created_at', ascending: false);

          final List<dynamic> list = response as List<dynamic>;
          return list
              .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      throw mapExceptionToFailure(e);
    }
  }

  Future<String> _uploadReceipt(String userId, File file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last.toLowerCase();
      final path = '$userId/$timestamp.$extension';

      await client.storage
          .from(AppConstants.receiptsBucket)
          .upload(path, file);

      final publicUrl = client.storage
          .from(AppConstants.receiptsBucket)
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
