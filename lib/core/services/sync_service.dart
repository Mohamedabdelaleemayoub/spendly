import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local_expense_datasource.dart';
import '../../domain/entities/expense.dart';

abstract class SyncService {
  Future<int> syncPendingExpenses({String? userId});
  Stream<SyncStatus> get syncStatusStream;
  bool get isSyncing;
  void dispose();
}

class SyncServiceImpl implements SyncService {
  SyncServiceImpl({
    required this.localDataSource,
    required this.supabaseClient,
  }) {
    try {
      _authSub = supabaseClient.auth.onAuthStateChange.listen((data) {
        if (data.session != null) {
          syncPendingExpenses();
        }
      });
    } catch (_) {}
  }

  final LocalExpenseDataSource localDataSource;
  final SupabaseClient supabaseClient;
  StreamSubscription? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _syncStatusController.close();
  }

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  bool _isCurrentlySyncing = false;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  bool get isSyncing => _isCurrentlySyncing;

  @override
  Future<int> syncPendingExpenses({String? userId}) async {
    if (_isCurrentlySyncing) {
      debugPrint('⏳ [SyncService] Sync already in progress. Skipping duplicate run.');
      return 0;
    }

    final currentUserId = userId ?? supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint('ℹ️ [SyncService] No authenticated user. Sync skipped.');
      return 0;
    }

    _isCurrentlySyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    int successCount = 0;

    try {
      final pendingList = await localDataSource.getPendingExpenses(userId: currentUserId);

      if (pendingList.isEmpty) {
        debugPrint('✅ [SyncService] No pending expenses to sync.');
        _isCurrentlySyncing = false;
        _syncStatusController.add(SyncStatus.synced);
        return 0;
      }

      debugPrint('🔄 [SyncService] Starting sync for ${pendingList.length} pending expense(s)...');

      for (final expense in pendingList) {
        try {
          await localDataSource.updateSyncStatus(expense.id, SyncStatus.syncing);

          // 1. Prepare idempotent upsert data with stable client UUID
          final upsertData = expense.toJson(includeId: true);

          // 2. Perform idempotent upsert to Supabase
          await supabaseClient
              .from(AppConstants.expensesTable)
              .upsert(
                upsertData,
                onConflict: 'id',
              );

          // 3. Mark as synced in persistent local storage
          await localDataSource.updateSyncStatus(expense.id, SyncStatus.synced);
          successCount++;
          debugPrint('✅ [SyncService] Successfully synced expense ID: ${expense.id}');
        } catch (e) {
          debugPrint('⚠️ [SyncService] Failed to sync expense ID ${expense.id}: $e');
          // Keep the expense locally, mark as failed for retry later
          await localDataSource.updateSyncStatus(expense.id, SyncStatus.failed);
        }
      }

      final remaining = await localDataSource.getPendingExpenses(userId: currentUserId);
      if (remaining.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
      } else {
        _syncStatusController.add(SyncStatus.failed);
      }
    } catch (e) {
      debugPrint('❌ [SyncService] Unexpected error during sync: $e');
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isCurrentlySyncing = false;
    }

    return successCount;
  }
}
