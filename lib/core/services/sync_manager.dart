import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/local_database.dart';
import '../../data/models/admin_notification_model.dart';
import '../../data/models/balance_transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/salary_advance_model.dart';
import '../../data/models/weekly_allowance_model.dart';
import '../../domain/entities/expense.dart';
import '../constants/app_constants.dart';
import 'connectivity_service.dart';

abstract class SyncManager {
  Future<int> syncAll({String? userId});
  Stream<SyncStatus> get syncStatusStream;
  SyncStatus get currentStatus;
  bool get isSyncing;
  void dispose();
}

class SyncManagerImpl implements SyncManager {
  SyncManagerImpl({
    required this.localDatabase,
    required this.supabaseClient,
    required this.connectivityService,
  }) {
    _init();
  }

  final LocalDatabase localDatabase;
  final SupabaseClient supabaseClient;
  final ConnectivityService connectivityService;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  StreamSubscription? _authSub;
  StreamSubscription? _connectivitySub;
  Timer? _periodicTimer;

  bool _isCurrentlySyncing = false;
  SyncStatus _currentStatus = SyncStatus.synced;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  bool get isSyncing => _isCurrentlySyncing;

  void _init() {
    // 1. Listen for Supabase Auth state changes
    try {
      _authSub = supabaseClient.auth.onAuthStateChange.listen((data) {
        if (data.session != null && connectivityService.isOnline) {
          syncAll();
        }
      });
    } catch (_) {}

    // 2. Listen for Connectivity changes (Offline -> Online trigger)
    _connectivitySub = connectivityService.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        debugPrint('🌐 [SyncManager] Online detected! Triggering automatic background sync...');
        syncAll();
      } else {
        _updateStatus(SyncStatus.pending);
      }
    });

    // 3. Periodic safe interval sync while online (every 5 minutes)
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (connectivityService.isOnline && !_isCurrentlySyncing) {
        syncAll();
      }
    });
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  @override
  Future<int> syncAll({String? userId}) async {
    if (_isCurrentlySyncing) {
      debugPrint('⏳ [SyncManager] Sync already in progress. Skipping duplicate call.');
      return 0;
    }

    if (!connectivityService.isOnline) {
      debugPrint('ℹ️ [SyncManager] Device is offline. Sync deferred.');
      _updateStatus(SyncStatus.pending);
      return 0;
    }

    final currentUserId = userId ?? supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint('ℹ️ [SyncManager] No authenticated user. Sync skipped.');
      return 0;
    }

    _isCurrentlySyncing = true;
    _updateStatus(SyncStatus.syncing);

    int successCount = 0;
    int failCount = 0;

    try {
      debugPrint('🔄 [SyncManager] Starting full synchronization...');

      // ── Step 1: Push Centralized Sync Queue Operations (FIFO Order) ────
      final pendingOps = await localDatabase.getPendingSyncOperations();
      debugPrint('📥 [SyncManager] Found ${pendingOps.length} pending operations in sync_queue.');

      for (final op in pendingOps) {
        final opId = op['operation_id'] as String;
        final entityType = op['entity_type'] as String;
        final entityId = op['entity_id'] as String;
        final operation = op['operation'] as String;
        final retryCount = (op['retry_count'] as int? ?? 0) + 1;

        try {
          Map<String, dynamic> payload = {};
          try {
            payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
          } catch (_) {}

          await _processQueueOperation(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
          );

          // Mark operation deleted from sync_queue upon success
          await localDatabase.deleteSyncOperation(opId);
          successCount++;
          debugPrint('✅ [SyncManager] Successfully processed $operation for $entityType ($entityId)');
        } catch (e) {
          debugPrint('⚠️ [SyncManager] Failed $operation for $entityType ($entityId): $e');
          final isPermanent = _isPermanentError(e);
          final status = isPermanent ? 'failed' : 'pending';
          await localDatabase.updateSyncOperationStatus(
            operationId: opId,
            status: status,
            retryCount: retryCount,
            lastError: e.toString(),
          );
          failCount++;
        }
      }

      // ── Step 2: Push Any Remaining Pending Expenses ───────────────────
      final pendingExpenses = await localDatabase.getPendingExpenses(userId: currentUserId);
      for (final exp in pendingExpenses) {
        try {
          await localDatabase.updateExpenseSyncStatus(exp.id, SyncStatus.syncing);
          final upsertData = exp.toJson(includeId: true);
          await supabaseClient.from(AppConstants.expensesTable).upsert(
                upsertData,
                onConflict: 'id',
              );
          await localDatabase.updateExpenseSyncStatus(exp.id, SyncStatus.synced);
          successCount++;
        } catch (e) {
          debugPrint('⚠️ [SyncManager] Pending expense sync error for ${exp.id}: $e');
          await localDatabase.updateExpenseSyncStatus(exp.id, SyncStatus.failed);
          failCount++;
        }
      }

      // ── Step 3: Pull Latest Server Data & Update Local Database ────────
      await _pullLatestServerData(currentUserId);

      // Determine final sync status
      final remainingOps = await localDatabase.getPendingSyncOperations();
      final remainingExp = await localDatabase.getPendingExpenses(userId: currentUserId);

      if (remainingOps.isEmpty && remainingExp.isEmpty) {
        _updateStatus(SyncStatus.synced);
        debugPrint('✅ [SyncManager] Full synchronization completed successfully ($successCount ops synced).');
      } else {
        _updateStatus(SyncStatus.failed);
        debugPrint('⚠️ [SyncManager] Sync completed with $failCount pending/failed items.');
      }
    } catch (e) {
      debugPrint('❌ [SyncManager] Unexpected error during syncAll: $e');
      _updateStatus(SyncStatus.failed);
    } finally {
      _isCurrentlySyncing = false;
    }

    return successCount;
  }

  Future<void> _processQueueOperation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    switch (entityType) {
      case 'expense':
        if (operation == 'DELETE') {
          await supabaseClient.from(AppConstants.expensesTable).delete().eq('id', entityId);
          await localDatabase.deleteExpense(entityId);
        } else {
          await supabaseClient.from(AppConstants.expensesTable).upsert(payload, onConflict: 'id');
          await localDatabase.updateExpenseSyncStatus(entityId, SyncStatus.synced);
        }
        break;

      case 'allowance_transaction':
        if (operation == 'DELETE') {
          await supabaseClient.from(AppConstants.allowanceTransactionsTable).delete().eq('id', entityId);
          await localDatabase.deleteAllowanceTransaction(entityId);
        } else {
          await supabaseClient.from(AppConstants.allowanceTransactionsTable).upsert(payload, onConflict: 'id');
        }
        break;

      case 'salary_advance':
        if (operation == 'DELETE') {
          await supabaseClient.from(AppConstants.salaryAdvancesTable).delete().eq('id', entityId);
          await localDatabase.deleteSalaryAdvance(entityId);
        } else {
          await supabaseClient.from(AppConstants.salaryAdvancesTable).upsert(payload, onConflict: 'id');
        }
        break;

      case 'category':
        if (operation == 'DELETE') {
          await supabaseClient.from(AppConstants.categoriesTable).delete().eq('id', entityId);
          await localDatabase.deleteCategory(entityId);
        } else {
          await supabaseClient.from(AppConstants.categoriesTable).upsert(payload, onConflict: 'id');
        }
        break;

      case 'profile':
        if (operation == 'DELETE') {
          await localDatabase.deleteProfile(entityId);
        } else {
          await supabaseClient.from(AppConstants.profilesTable).upsert(payload, onConflict: 'id');
        }
        break;

      case 'settings':
        await supabaseClient.from('app_settings').upsert(payload, onConflict: 'key');
        break;

      default:
        debugPrint('⚠️ [SyncManager] Unknown entity type: $entityType');
    }
  }

  Future<void> _pullLatestServerData(String currentUserId) async {
    try {
      debugPrint('⬇️ [SyncManager] Pulling latest data from Supabase...');

      // 1. Pull Profiles
      try {
        final profilesRes = await supabaseClient
            .from(AppConstants.profilesTable)
            .select()
            .order('full_name', ascending: true);
        final profiles = (profilesRes as List<dynamic>)
            .map((j) => ProfileModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveProfiles(profiles);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling profiles: $e');
      }

      // 2. Pull Categories
      try {
        final catRes = await supabaseClient
            .from(AppConstants.categoriesTable)
            .select()
            .order('created_at', ascending: true);
        final categories = (catRes as List<dynamic>)
            .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveCategories(categories);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling categories: $e');
      }

      // 3. Pull Expenses
      try {
        final expRes = await supabaseClient
            .from(AppConstants.expensesTable)
            .select('*, category:categories(*), profile:profiles(*)')
            .order('expense_date', ascending: false)
            .limit(300);

        final expenses = (expRes as List<dynamic>)
            .map((j) => ExpenseModel.fromEntity(
                  ExpenseModel.fromJson(j as Map<String, dynamic>).copyWith(
                    syncStatus: SyncStatus.synced,
                  ),
                ))
            .toList();
        await localDatabase.saveExpenses(expenses, preservePending: true);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling expenses: $e');
      }

      // 4. Pull Allowance Transactions
      try {
        final allowRes = await supabaseClient
            .from(AppConstants.allowanceTransactionsTable)
            .select('*, creator:created_by(id, full_name, email, avatar_url)')
            .order('transaction_date', ascending: false)
            .limit(200);

        final allowances = (allowRes as List<dynamic>)
            .map((j) => WeeklyAllowanceModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveAllowanceTransactions(allowances);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling allowance transactions: $e');
      }

      // 5. Pull Salary Advances
      try {
        final salRes = await supabaseClient
            .from(AppConstants.salaryAdvancesTable)
            .select('*, creator:created_by(full_name)')
            .order('advance_date', ascending: false)
            .limit(200);

        final advances = (salRes as List<dynamic>)
            .map((j) => SalaryAdvanceModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveSalaryAdvances(advances);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling salary advances: $e');
      }

      // 6. Pull Balance Transactions
      try {
        final balRes = await supabaseClient
            .from(AppConstants.balanceTransactionsTable)
            .select('*, creator:created_by(id, full_name, email, avatar_url)')
            .order('transaction_date', ascending: false)
            .limit(200);

        final balances = (balRes as List<dynamic>)
            .map((j) => BalanceTransactionModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveBalanceTransactions(balances);
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling balance transactions: $e');
      }

      // 7. Pull App Settings
      try {
        final settingsRes = await supabaseClient.from('app_settings').select();
        for (final row in (settingsRes as List<dynamic>)) {
          final k = row['key'] as String;
          final v = row['value'];
          await localDatabase.saveSetting(k, v);
        }
      } catch (e) {
        debugPrint('⚠️ [SyncManager] Error pulling app settings: $e');
      }

      // 8. Pull Admin Notifications (if admin)
      try {
        final notifRes = await supabaseClient
            .from('admin_notifications')
            .select('*, profiles:profiles!admin_notifications_user_id_fkey(id, full_name, email, role, status, avatar_url)')
            .order('created_at', ascending: false)
            .limit(50);

        final notifs = (notifRes as List<dynamic>)
            .map((j) => AdminNotificationModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDatabase.saveNotifications(notifs);
      } catch (_) {}

      debugPrint('✅ [SyncManager] Data pull completed and cached locally.');
    } catch (e) {
      debugPrint('⚠️ [SyncManager] Error during server pull: $e');
    }
  }

  bool _isPermanentError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection closed')) {
      return false;
    }

    if (error is PostgrestException) {
      final code = error.code;
      if (code != null && (code.startsWith('23') || code.startsWith('42') || code == 'P0001')) {
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _syncStatusController.close();
  }
}
