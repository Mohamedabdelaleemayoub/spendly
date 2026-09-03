import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/expense_currency.dart';
import '../models/salary_payment_model.dart';

abstract class SalaryPaymentRemoteDataSource {
  Future<List<SalaryPaymentModel>> getSalaryPayments(String userId);
  Future<List<SalaryPaymentModel>> getAllSalaryPayments();
  Future<SalaryPaymentModel> createSalaryPayment({
    String? id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  });
  Future<SalaryPaymentModel> updateSalaryPayment({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  });
  Future<void> deleteSalaryPayment(String id);
  Future<void> updateSalaryCycleConfig({
    required String userId,
    required String cycleType,
    required int cycleDays,
    required int cycleStartDay,
  });
}

class SalaryPaymentRemoteDataSourceImpl implements SalaryPaymentRemoteDataSource {
  SalaryPaymentRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<List<SalaryPaymentModel>> getSalaryPayments(String userId) async {
    try {
      final response = await client
          .from(AppConstants.salaryPaymentsTable)
          .select('*, creator:created_by(full_name)')
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SalaryPaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<SalaryPaymentModel>> getAllSalaryPayments() async {
    try {
      final response = await client
          .from(AppConstants.salaryPaymentsTable)
          .select('*, creator:created_by(full_name)')
          .order('payment_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SalaryPaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<SalaryPaymentModel> createSalaryPayment({
    String? id,
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = paymentDate.toIso8601String().split('T').first;
      final startStr = salaryPeriodStart.toIso8601String().split('T').first;
      final endStr = salaryPeriodEnd.toIso8601String().split('T').first;

      final payload = {
        'id': ?id,
        'user_id': userId,
        'amount': amount,
        'currency': currency.code,
        'payment_date': dateStr,
        'salary_period_start': startStr,
        'salary_period_end': endStr,
        if (note != null && note.isNotEmpty) 'note': note,
        'created_by': currentUserId,
      };

      final response = await client
          .from(AppConstants.salaryPaymentsTable)
          .insert(payload)
          .select('*, creator:created_by(full_name)')
          .single();

      return SalaryPaymentModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<SalaryPaymentModel> updateSalaryPayment({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    try {
      final dateStr = paymentDate.toIso8601String().split('T').first;
      final startStr = salaryPeriodStart.toIso8601String().split('T').first;
      final endStr = salaryPeriodEnd.toIso8601String().split('T').first;

      final payload = {
        'amount': amount,
        'currency': currency.code,
        'payment_date': dateStr,
        'salary_period_start': startStr,
        'salary_period_end': endStr,
        'note': note,
      };

      final response = await client
          .from(AppConstants.salaryPaymentsTable)
          .update(payload)
          .eq('id', id)
          .select('*, creator:created_by(full_name)')
          .single();

      return SalaryPaymentModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteSalaryPayment(String id) async {
    try {
      await client
          .from(AppConstants.salaryPaymentsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateSalaryCycleConfig({
    required String userId,
    required String cycleType,
    required int cycleDays,
    required int cycleStartDay,
  }) async {
    try {
      await client
          .from(AppConstants.profilesTable)
          .update({
            'salary_cycle_type': cycleType,
            'salary_cycle_days': cycleDays,
            'salary_cycle_start_day': cycleStartDay,
          })
          .eq('id', userId);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
