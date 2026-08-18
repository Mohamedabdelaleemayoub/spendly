import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../datasources/local_expense_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncService,
    required this.supabaseClient,
  });

  final ExpenseRemoteDataSource remoteDataSource;
  final LocalExpenseDataSource localDataSource;
  final SyncService syncService;
  final SupabaseClient supabaseClient;

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
  }) async {
    final currentUserId = userId ?? supabaseClient.auth.currentUser?.id;

    try {
      // 1. Fetch remote expenses
      final remoteList = await remoteDataSource.getExpenses(
        page: page,
        pageSize: pageSize,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        userId: userId,
        paymentMethod: paymentMethod,
        searchQuery: searchQuery,
      );

      // Cache remote items in persistent local storage
      if (page == 0) {
        await localDataSource.saveExpenses(remoteList, preservePending: true);
      }

      // 2. Fetch locally stored pending / syncing / failed expenses for current user
      final localPending = await localDataSource.getPendingExpenses(userId: currentUserId);

      // Filter local pending according to query parameters
      final filteredPending = localPending.where((exp) {
        if (categoryId != null && categoryId.isNotEmpty && exp.categoryId != categoryId) {
          return false;
        }
        if (paymentMethod != null && paymentMethod.isNotEmpty && exp.paymentMethod != paymentMethod) {
          return false;
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final query = searchQuery.trim().toLowerCase();
          final matchesTitle = exp.title.toLowerCase().contains(query);
          final matchesNotes = exp.notes?.toLowerCase().contains(query) ?? false;
          if (!matchesTitle && !matchesNotes) return false;
        }
        if (startDate != null) {
          final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          if (expDate.isBefore(start)) return false;
        }
        if (endDate != null) {
          final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          if (expDate.isAfter(end)) return false;
        }
        return true;
      }).toList();

      // Merge: Local pending on top, remote below (eliminating any duplicate IDs)
      final seenIds = <String>{};
      final combined = <Expense>[];

      for (final exp in filteredPending) {
        if (seenIds.add(exp.id)) {
          combined.add(exp);
        }
      }

      for (final exp in remoteList) {
        if (seenIds.add(exp.id)) {
          combined.add(exp);
        }
      }

      return combined;
    } catch (e) {
      debugPrint('⚠️ [ExpenseRepositoryImpl] Remote getExpenses failed ($e), falling back to local persistent store.');
      // Offline fallback: load from persistent local storage
      final localAll = await localDataSource.getExpenses(userId: currentUserId);

      return localAll.where((exp) {
        if (categoryId != null && categoryId.isNotEmpty && exp.categoryId != categoryId) {
          return false;
        }
        if (paymentMethod != null && paymentMethod.isNotEmpty && exp.paymentMethod != paymentMethod) {
          return false;
        }
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final query = searchQuery.trim().toLowerCase();
          final matchesTitle = exp.title.toLowerCase().contains(query);
          final matchesNotes = exp.notes?.toLowerCase().contains(query) ?? false;
          if (!matchesTitle && !matchesNotes) return false;
        }
        if (startDate != null) {
          final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          if (expDate.isBefore(start)) return false;
        }
        if (endDate != null) {
          final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          if (expDate.isAfter(end)) return false;
        }
        return true;
      }).toList();
    }
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    try {
      final remote = await remoteDataSource.getExpenseById(id);
      await localDataSource.saveExpense(remote);
      return remote;
    } catch (_) {
      final local = await localDataSource.getExpenseById(id);
      if (local != null) return local;
      rethrow;
    }
  }

  @override
  Future<Expense> createExpense({
    String title = '',
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    final currentUserId = supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) {
      throw const AuthException('User not authenticated');
    }

    // 1. Generate stable RFC 4122 v4 Client UUID
    final clientExpenseId = UuidGenerator.generate();
    final now = DateTime.now();

    // 2. Build local expense entity with pending sync status
    final localExpense = ExpenseModel(
      id: clientExpenseId,
      userId: currentUserId,
      categoryId: categoryId,
      title: title.trim(),
      amount: amount,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      notes: notes?.trim(),
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    // 3. Persist safely in persistent local storage FIRST
    await localDataSource.saveExpense(localExpense);
    debugPrint('💾 [ExpenseRepositoryImpl] Expense persisted locally with ID: $clientExpenseId (Pending)');

    // 4. Attempt remote synchronization
    try {
      final remoteModel = await remoteDataSource.createExpense(
        id: clientExpenseId,
        title: title.trim(),
        amount: amount,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        categoryId: categoryId,
        notes: notes,
        receiptFile: receiptFile,
      );

      final syncedModel = remoteModel.copyWith(syncStatus: SyncStatus.synced);
      await localDataSource.saveExpense(ExpenseModel.fromEntity(syncedModel));
      debugPrint('☁️ [ExpenseRepositoryImpl] Expense successfully synced to server (ID: $clientExpenseId)');
      return syncedModel;
    } catch (e) {
      debugPrint('📱 [ExpenseRepositoryImpl] Network unavailable/failed: $e. Remaining in persistent local queue.');
      // Return the saved local pending expense so user flow continues seamlessly
      return localExpense;
    }
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    String title = '',
    required double amount,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) async {
    final existing = await localDataSource.getExpenseById(id);
    final updatedLocal = (existing ?? ExpenseModel(
      id: id,
      userId: supabaseClient.auth.currentUser?.id ?? '',
      amount: amount,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
    )).copyWith(
      title: title.trim(),
      amount: amount,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      categoryId: categoryId,
      notes: notes?.trim(),
      receiptUrl: existingReceiptUrl,
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    await localDataSource.saveExpense(ExpenseModel.fromEntity(updatedLocal));

    try {
      final remoteModel = await remoteDataSource.updateExpense(
        id: id,
        title: title.trim(),
        amount: amount,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        categoryId: categoryId,
        notes: notes,
        receiptFile: receiptFile,
        existingReceiptUrl: existingReceiptUrl,
      );

      final synced = remoteModel.copyWith(syncStatus: SyncStatus.synced);
      await localDataSource.saveExpense(ExpenseModel.fromEntity(synced));
      return synced;
    } catch (e) {
      debugPrint('⚠️ [ExpenseRepositoryImpl] Remote update failed ($e). Kept pending locally.');
      return updatedLocal;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await localDataSource.deleteExpense(id);
    try {
      await remoteDataSource.deleteExpense(id);
    } catch (e) {
      debugPrint('⚠️ [ExpenseRepositoryImpl] Remote delete error ($e), deleted locally.');
    }
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId}) async {
    try {
      final remoteList = await remoteDataSource.getExpensesForMonth(month, userId: userId);
      return remoteList;
    } catch (e) {
      debugPrint('⚠️ [ExpenseRepositoryImpl] Remote getExpensesForMonth failed ($e), calculating from local store.');
      final localAll = await localDataSource.getExpenses(userId: userId);
      return localAll.where((exp) {
        return exp.expenseDate.year == month.year && exp.expenseDate.month == month.month;
      }).toList();
    }
  }

  @override
  Future<int> syncPendingExpenses({String? userId}) {
    return syncService.syncPendingExpenses(userId: userId);
  }
}
