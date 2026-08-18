import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/expense_currency.dart';
import '../models/balance_transaction_model.dart';
import '../models/employee_balance_summary_model.dart';

abstract class BalanceRemoteDataSource {
  Future<BalanceTransactionModel> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  });

  Future<EmployeeBalanceSummaryModel> getEmployeeBalanceSummary(String userId);

  Future<List<EmployeeBalanceSummaryModel>> getAllEmployeeBalances();

  Future<List<BalanceTransactionModel>> getBalanceTransactions(String userId);
}

class BalanceRemoteDataSourceImpl implements BalanceRemoteDataSource {
  BalanceRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<BalanceTransactionModel> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    try {
      final currentAdmin = client.auth.currentUser;
      if (currentAdmin == null) {
        throw const AuthException('User not authenticated');
      }

      final date = transactionDate ?? DateTime.now();
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final insertData = <String, dynamic>{
        'user_id': userId,
        'amount': amount,
        'currency': currency.toDbString(),
        'type': 'credit',
        'transaction_date': dateStr,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'created_by': currentAdmin.id,
      };

      final response = await client
          .from(AppConstants.balanceTransactionsTable)
          .insert(insertData)
          .select('*, creator:created_by(id, full_name, email, avatar_url)')
          .single();

      return BalanceTransactionModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [BalanceRemoteDataSourceImpl] Error adding balance: $e');
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<EmployeeBalanceSummaryModel> getEmployeeBalanceSummary(String userId) async {
    try {
      final rpcRes = await client.rpc('get_employee_balance_summary', params: {
        'p_user_id': userId,
      });

      if (rpcRes is Map<String, dynamic>) {
        final profileRes = await client
            .from(AppConstants.profilesTable)
            .select('full_name, email, role, status, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        final map = Map<String, dynamic>.from(rpcRes);
        if (profileRes != null) {
          map['name'] = profileRes['full_name'] ?? profileRes['name'] ?? 'مستخدم';
          map['email'] = profileRes['email'];
          map['role'] = profileRes['role'];
          map['status'] = profileRes['status'];
          map['avatar_url'] = profileRes['avatar_url'];
        }
        return EmployeeBalanceSummaryModel.fromJson(map);
      }

      // Fallback calculation if RPC is not deployed yet
      dynamic creditsRes;
      try {
        creditsRes = await client
            .from(AppConstants.balanceTransactionsTable)
            .select('amount, currency, type')
            .eq('user_id', userId);
      } catch (_) {
        try {
          creditsRes = await client
              .from(AppConstants.balanceTransactionsTable)
              .select('amount, type')
              .eq('user_id', userId);
        } catch (_) {
          creditsRes = [];
        }
      }

      double egpReceived = 0.0;
      double egpAdjustSub = 0.0;
      double usdReceived = 0.0;
      double usdAdjustSub = 0.0;

      for (final row in (creditsRes as List)) {
        final amt = (row['amount'] as num).toDouble();
        final type = row['type'] as String;
        final curr = (row['currency'] as String?)?.toUpperCase() ?? 'EGP';

        if (curr == 'USD') {
          if (type == 'adjustment_sub') {
            usdAdjustSub += amt;
          } else {
            usdReceived += amt;
          }
        } else {
          if (type == 'adjustment_sub') {
            egpAdjustSub += amt;
          } else {
            egpReceived += amt;
          }
        }
      }

      dynamic expensesRes;
      try {
        expensesRes = await client
            .from(AppConstants.expensesTable)
            .select('amount, currency')
            .eq('user_id', userId);
      } catch (_) {
        try {
          expensesRes = await client
              .from(AppConstants.expensesTable)
              .select('amount')
              .eq('user_id', userId);
        } catch (_) {
          expensesRes = [];
        }
      }

      double egpSpent = 0.0;
      double usdSpent = 0.0;
      for (final row in (expensesRes as List)) {
        final amt = (row['amount'] as num).toDouble();
        final curr = (row['currency'] as String?)?.toUpperCase() ?? 'EGP';
        if (curr == 'USD') {
          usdSpent += amt;
        } else {
          egpSpent += amt;
        }
      }

      dynamic profileRes;
      try {
        profileRes = await client
            .from(AppConstants.profilesTable)
            .select('full_name, email, role, status, avatar_url')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        try {
          profileRes = await client
              .from(AppConstants.profilesTable)
              .select('full_name, email, role, avatar_url')
              .eq('id', userId)
              .maybeSingle();
        } catch (_) {
          profileRes = null;
        }
      }

      return EmployeeBalanceSummaryModel(
        userId: userId,
        name: profileRes?['full_name'] as String? ?? profileRes?['name'] as String? ?? 'موظف',
        email: profileRes?['email'] as String?,
        role: profileRes?['role'] as String? ?? 'employee',
        status: profileRes?['status'] as String? ?? 'active',
        avatarUrl: profileRes?['avatar_url'] as String?,
        totalReceivedEgp: egpReceived,
        totalSpentEgp: egpSpent,
        availableBalanceEgp: egpReceived - egpAdjustSub - egpSpent,
        totalReceivedUsd: usdReceived,
        totalSpentUsd: usdSpent,
        availableBalanceUsd: usdReceived - usdAdjustSub - usdSpent,
      );
    } catch (e) {
      debugPrint('❌ [BalanceRemoteDataSourceImpl] Error getting balance summary: $e');
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<EmployeeBalanceSummaryModel>> getAllEmployeeBalances() async {
    try {
      final rpcRes = await client.rpc('get_all_employee_balances');
      if (rpcRes is List) {
        return rpcRes
            .map((item) => EmployeeBalanceSummaryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [BalanceRemoteDataSourceImpl] RPC get_all_employee_balances failed ($e), falling back.');
      // Fallback: Query profiles and aggregate
      dynamic profilesRes;
      try {
        profilesRes = await client
            .from(AppConstants.profilesTable)
            .select('id, full_name, email, role, status, avatar_url');
      } catch (_) {
        try {
          profilesRes = await client
              .from(AppConstants.profilesTable)
              .select('id, full_name, email, role, avatar_url');
        } catch (_) {
          profilesRes = [];
        }
      }

      final List<EmployeeBalanceSummaryModel> summaries = [];
      for (final p in (profilesRes as List)) {
        final uid = p['id'] as String;
        try {
          final summary = await getEmployeeBalanceSummary(uid);
          summaries.add(summary);
        } catch (_) {}
      }
      return summaries;
    }
  }

  @override
  Future<List<BalanceTransactionModel>> getBalanceTransactions(String userId) async {
    try {
      final response = await client
          .from(AppConstants.balanceTransactionsTable)
          .select('*, creator:created_by(id, full_name, email, avatar_url)')
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => BalanceTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BalanceRemoteDataSourceImpl] Error getting balance transactions: $e');
      throw mapExceptionToFailure(e);
    }
  }
}
