import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/weekly_work_budget_summary.dart';
import '../models/weekly_allowance_model.dart';

abstract class WeeklyAllowanceRemoteDataSource {
  Future<List<WeeklyAllowanceModel>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<WeeklyAllowanceModel> createAllowanceTransaction({
    String? id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  });

  Future<WeeklyAllowanceModel> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  });

  Future<void> deleteAllowanceTransaction(String id);
}

class WeeklyAllowanceRemoteDataSourceImpl implements WeeklyAllowanceRemoteDataSource {
  WeeklyAllowanceRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<List<WeeklyAllowanceModel>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client
          .from(AppConstants.allowanceTransactionsTable)
          .select('*, creator:created_by(id, full_name, email, avatar_url)')
          .eq('user_id', userId);

      if (startDate != null) {
        final startStr =
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.gte('transaction_date', startStr);
      }

      if (endDate != null) {
        final endStr =
            '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.lte('transaction_date', endStr);
      }

      final response = await query
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => WeeklyAllowanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRemoteDataSourceImpl] Error getting transactions (returning empty): $e');
      return [];
    }
  }

  @override
  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr =
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    try {
      // 1. Try server-side RPC if migration 011 is applied
      final rpcRes = await client.rpc('get_weekly_work_budget_summary', params: {
        'p_start_date': startStr,
        'p_end_date': endStr,
        'p_user_id': ?userId,
      });

      if (rpcRes is Map<String, dynamic>) {
        return WeeklyWorkBudgetSummary(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          receivedEgp: (rpcRes['egp_received'] as num?)?.toDouble() ?? 0.0,
          spentEgp: (rpcRes['egp_spent'] as num?)?.toDouble() ?? 0.0,
          receivedUsd: (rpcRes['usd_received'] as num?)?.toDouble() ?? 0.0,
          spentUsd: (rpcRes['usd_spent'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('ℹ️ [WeeklyAllowanceRemoteDataSourceImpl] RPC unavailable, falling back to direct table queries: $e');
    }

    // 2. Direct query fallback
    try {
      var allowanceQuery = client
          .from(AppConstants.allowanceTransactionsTable)
          .select('amount, currency')
          .gte('transaction_date', startStr)
          .lte('transaction_date', endStr);

      var expensesQuery = client
          .from(AppConstants.expensesTable)
          .select('amount, currency')
          .gte('expense_date', startStr)
          .lte('expense_date', endStr);

      if (userId != null) {
        allowanceQuery = allowanceQuery.eq('user_id', userId);
        expensesQuery = expensesQuery.eq('user_id', userId);
      }

      final allowanceRes = await allowanceQuery;
      final expensesRes = await expensesQuery;

      double receivedEgp = 0.0;
      double receivedUsd = 0.0;
      for (final item in (allowanceRes as List<dynamic>)) {
        final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final curr = item['currency'] as String? ?? 'EGP';
        if (curr == 'USD') {
          receivedUsd += amt;
        } else {
          receivedEgp += amt;
        }
      }

      double spentEgp = 0.0;
      double spentUsd = 0.0;
      for (final item in (expensesRes as List<dynamic>)) {
        final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final curr = item['currency'] as String? ?? 'EGP';
        if (curr == 'USD') {
          spentUsd += amt;
        } else {
          spentEgp += amt;
        }
      }

      return WeeklyWorkBudgetSummary(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        receivedEgp: receivedEgp,
        spentEgp: spentEgp,
        receivedUsd: receivedUsd,
        spentUsd: spentUsd,
      );
    } catch (e) {
      debugPrint('ℹ️ [WeeklyAllowanceRemoteDataSourceImpl] Fallback query returned default: $e');
      return WeeklyWorkBudgetSummary(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        receivedEgp: 0.0,
        spentEgp: 0.0,
        receivedUsd: 0.0,
        spentUsd: 0.0,
      );
    }
  }

  @override
  Future<WeeklyAllowanceModel> createAllowanceTransaction({
    String? id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    try {
      final currentAdmin = client.auth.currentUser;
      if (currentAdmin == null) {
        throw const AuthException('User not authenticated');
      }

      final dateStr =
          '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}';

      final insertData = <String, dynamic>{
        'id': ?id,
        'user_id': userId,
        'amount': amount,
        'currency': currency.code,
        'transaction_date': dateStr,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'created_by': currentAdmin.id,
      };

      final response = await client
          .from(AppConstants.allowanceTransactionsTable)
          .insert(insertData)
          .select('*, creator:created_by(id, full_name, email, avatar_url)')
          .single();

      return WeeklyAllowanceModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<WeeklyAllowanceModel> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    try {
      final dateStr =
          '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}';

      final updateData = <String, dynamic>{
        'amount': amount,
        'currency': currency.code,
        'transaction_date': dateStr,
        'note': note?.trim(),
      };

      final response = await client
          .from(AppConstants.allowanceTransactionsTable)
          .update(updateData)
          .eq('id', id)
          .select('*, creator:created_by(id, full_name, email, avatar_url)')
          .single();

      return WeeklyAllowanceModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteAllowanceTransaction(String id) async {
    try {
      await client
          .from(AppConstants.allowanceTransactionsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
