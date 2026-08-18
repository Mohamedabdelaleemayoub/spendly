import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/expense_currency.dart';
import '../models/salary_advance_model.dart';

abstract class SalaryAdvanceRemoteDataSource {
  Future<List<SalaryAdvanceModel>> getSalaryAdvances(String userId);
  Future<List<SalaryAdvanceModel>> getAllSalaryAdvances();
  Future<SalaryAdvanceModel> createSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  });
  Future<SalaryAdvanceModel> updateSalaryAdvance({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  });
  Future<void> deleteSalaryAdvance(String id);
  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  });
}

class SalaryAdvanceRemoteDataSourceImpl implements SalaryAdvanceRemoteDataSource {
  SalaryAdvanceRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<List<SalaryAdvanceModel>> getSalaryAdvances(String userId) async {
    try {
      final response = await client
          .from(AppConstants.salaryAdvancesTable)
          .select('*, creator:created_by(full_name)')
          .eq('user_id', userId)
          .order('advance_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SalaryAdvanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SalaryAdvanceModel>> getAllSalaryAdvances() async {
    try {
      final response = await client
          .from(AppConstants.salaryAdvancesTable)
          .select('*, creator:created_by(full_name)')
          .order('advance_date', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SalaryAdvanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<SalaryAdvanceModel> createSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = advanceDate.toIso8601String().split('T').first;
      final payload = {
        'user_id': userId,
        'amount': amount,
        'currency': currency.code,
        'advance_date': dateStr,
        if (note != null && note.isNotEmpty) 'note': note,
        'created_by': currentUserId,
      };

      final response = await client
          .from(AppConstants.salaryAdvancesTable)
          .insert(payload)
          .select('*, creator:created_by(full_name)')
          .single();

      return SalaryAdvanceModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<SalaryAdvanceModel> updateSalaryAdvance({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    try {
      final dateStr = advanceDate.toIso8601String().split('T').first;
      final payload = {
        'amount': amount,
        'currency': currency.code,
        'advance_date': dateStr,
        'note': note,
      };

      final response = await client
          .from(AppConstants.salaryAdvancesTable)
          .update(payload)
          .eq('id', id)
          .select('*, creator:created_by(full_name)')
          .single();

      return SalaryAdvanceModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteSalaryAdvance(String id) async {
    try {
      await client
          .from(AppConstants.salaryAdvancesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  }) async {
    try {
      await client
          .from(AppConstants.profilesTable)
          .update({
            'salary_amount': salaryAmount,
            'salary_currency': salaryCurrency.code,
          })
          .eq('id', userId);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
