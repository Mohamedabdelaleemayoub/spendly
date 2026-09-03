import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../core/utils/payroll_calculator.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/payroll_summary.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/salary_payment_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/salary_payment_remote_datasource.dart';
import '../models/profile_model.dart';
import '../models/salary_payment_model.dart';

class SalaryPaymentRepositoryImpl implements SalaryPaymentRepository {
  SalaryPaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.profileRepository,
    this.localDatabase,
  });

  final SalaryPaymentRemoteDataSource remoteDataSource;
  final ProfileRepository profileRepository;
  final LocalDatabase? localDatabase;

  @override
  Future<List<SalaryPayment>> getSalaryPayments(String userId) async {
    try {
      final remote = await remoteDataSource.getSalaryPayments(userId);
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryPayments(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote getSalaryPayments failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getSalaryPayments(userId);
      }
      return [];
    }
  }

  @override
  Future<List<SalaryPayment>> getAllSalaryPayments() async {
    try {
      final remote = await remoteDataSource.getAllSalaryPayments();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryPayments(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote getAllSalaryPayments failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getAllSalaryPayments();
      }
      return [];
    }
  }

  @override
  Future<SalaryPayment> createSalaryPayment({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    final clientPaymentId = UuidGenerator.generate();
    final now = DateTime.now();

    final localModel = SalaryPaymentModel(
      id: clientPaymentId,
      userId: userId,
      amount: amount,
      currency: currency,
      paymentDate: paymentDate,
      salaryPeriodStart: salaryPeriodStart,
      salaryPeriodEnd: salaryPeriodEnd,
      note: note,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSalaryPayment(localModel);
    }

    try {
      final remote = await remoteDataSource.createSalaryPayment(
        id: clientPaymentId,
        userId: userId,
        amount: amount,
        currency: currency,
        paymentDate: paymentDate,
        salaryPeriodStart: salaryPeriodStart,
        salaryPeriodEnd: salaryPeriodEnd,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryPayment(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote createSalaryPayment failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_payment',
          entityId: clientPaymentId,
          operation: 'INSERT',
          payload: {
            'id': clientPaymentId,
            'user_id': userId,
            'amount': amount,
            'currency': currency.code,
            'payment_date': paymentDate.toIso8601String().split('T').first,
            'salary_period_start': salaryPeriodStart.toIso8601String().split('T').first,
            'salary_period_end': salaryPeriodEnd.toIso8601String().split('T').first,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<SalaryPayment> updateSalaryPayment({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  }) async {
    String existingUserId = '';
    String existingCreatedBy = '';
    String? existingCreatedByName;
    DateTime? existingCreatedAt;

    if (localDatabase != null && localDatabase!.isInitialized) {
      final existingList = await localDatabase!.getAllSalaryPayments();
      final existing = existingList.where((item) => item.id == id).firstOrNull;
      if (existing != null) {
        existingUserId = existing.userId;
        existingCreatedBy = existing.createdBy;
        existingCreatedByName = existing.createdByName;
        existingCreatedAt = existing.createdAt;
      }
    }

    final localModel = SalaryPaymentModel(
      id: id,
      userId: existingUserId,
      amount: amount,
      currency: currency,
      paymentDate: paymentDate,
      salaryPeriodStart: salaryPeriodStart,
      salaryPeriodEnd: salaryPeriodEnd,
      note: note,
      createdBy: existingCreatedBy,
      createdByName: existingCreatedByName,
      createdAt: existingCreatedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSalaryPayment(localModel);
    }

    try {
      final remote = await remoteDataSource.updateSalaryPayment(
        id: id,
        amount: amount,
        currency: currency,
        paymentDate: paymentDate,
        salaryPeriodStart: salaryPeriodStart,
        salaryPeriodEnd: salaryPeriodEnd,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryPayment(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote updateSalaryPayment failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_payment',
          entityId: id,
          operation: 'UPDATE',
          payload: {
            'id': id,
            'amount': amount,
            'currency': currency.code,
            'payment_date': paymentDate.toIso8601String().split('T').first,
            'salary_period_start': salaryPeriodStart.toIso8601String().split('T').first,
            'salary_period_end': salaryPeriodEnd.toIso8601String().split('T').first,
            'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<void> deleteSalaryPayment(String id) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.deleteSalaryPayment(id);
    }

    try {
      await remoteDataSource.deleteSalaryPayment(id);
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote deleteSalaryPayment failed ($e), enqueued in sync queue.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_payment',
          entityId: id,
          operation: 'DELETE',
          payload: {'id': id},
        );
      }
    }
  }

  @override
  Future<void> updateSalaryCycleConfig({
    required String userId,
    required String cycleType,
    required int cycleDays,
    required int cycleStartDay,
  }) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      final prof = await localDatabase!.getProfile(userId);
      if (prof != null) {
        await localDatabase!.saveProfile(ProfileModel.fromEntity(prof.copyWith(
          salaryCycleType: cycleType,
          salaryCycleDays: cycleDays,
          salaryCycleStartDay: cycleStartDay,
        )));
      }
    }

    try {
      await remoteDataSource.updateSalaryCycleConfig(
        userId: userId,
        cycleType: cycleType,
        cycleDays: cycleDays,
        cycleStartDay: cycleStartDay,
      );

      if (localDatabase != null && localDatabase!.isInitialized) {
        final prof = await localDatabase!.getProfile(userId);
        if (prof != null) {
          await localDatabase!.saveProfile(ProfileModel.fromEntity(prof.copyWith(
            salaryCycleType: cycleType,
            salaryCycleDays: cycleDays,
            salaryCycleStartDay: cycleStartDay,
          )));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SalaryPaymentRepositoryImpl] Remote updateSalaryCycleConfig failed ($e), updated locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'profile',
          entityId: userId,
          operation: 'UPDATE',
          payload: {
            'id': userId,
            'salary_cycle_type': cycleType,
            'salary_cycle_days': cycleDays,
            'salary_cycle_start_day': cycleStartDay,
          },
        );
      }
    }
  }

  @override
  Future<PayrollSummary?> getEmployeePayrollSummary(String userId, {DateTime? referenceDate}) async {
    final profile = await profileRepository.getProfile(userId);
    if (profile == null) return null;

    final payments = await getSalaryPayments(userId);
    return PayrollCalculator.calculateSummary(
      profile: profile,
      allPayments: payments,
      referenceDate: referenceDate,
    );
  }

  @override
  Future<List<PayrollSummary>> getAllPayrollSummaries({DateTime? referenceDate}) async {
    final employees = await profileRepository.getEmployees();
    final allPayments = await getAllSalaryPayments();

    final paymentsByUser = <String, List<SalaryPayment>>{};
    for (final p in allPayments) {
      paymentsByUser.putIfAbsent(p.userId, () => []).add(p);
    }

    final summaries = <PayrollSummary>[];
    for (final emp in employees) {
      if (emp.status != 'active') continue;
      final userPayments = paymentsByUser[emp.id] ?? [];
      final summary = PayrollCalculator.calculateSummary(
        profile: emp,
        allPayments: userPayments,
        referenceDate: referenceDate,
      );
      summaries.add(summary);
    }

    return summaries;
  }
}
