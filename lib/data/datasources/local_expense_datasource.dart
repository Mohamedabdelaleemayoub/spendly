import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';

abstract class LocalExpenseDataSource {
  Future<void> saveExpense(ExpenseModel expense);
  Future<void> saveExpenses(List<ExpenseModel> expenses, {bool preservePending = true});
  Future<List<ExpenseModel>> getExpenses({String? userId});
  Future<ExpenseModel?> getExpenseById(String id);
  Future<List<ExpenseModel>> getPendingExpenses({String? userId});
  Future<void> updateSyncStatus(String id, SyncStatus status);
  Future<void> deleteExpense(String id);
  Future<void> clear();
}

class LocalExpenseDataSourceImpl implements LocalExpenseDataSource {
  LocalExpenseDataSourceImpl({required this.prefs});

  final SharedPreferences prefs;
  static const String _storageKey = 'spendly_offline_expenses_v1';

  Map<String, dynamic> _readStorageMap() {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      debugPrint('⚠️ [LocalExpenseDataSource] Error reading persistent storage: $e');
    }
    return {};
  }

  Future<void> _writeStorageMap(Map<String, dynamic> map) async {
    final encoded = jsonEncode(map);
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<void> saveExpense(ExpenseModel expense) async {
    final map = _readStorageMap();
    map[expense.id] = expense.toLocalJson();
    await _writeStorageMap(map);
  }

  @override
  Future<void> saveExpenses(
    List<ExpenseModel> expenses, {
    bool preservePending = true,
  }) async {
    final map = _readStorageMap();

    // If preservePending is true, keep existing pending/failed/syncing items
    final pendingItems = <String, dynamic>{};
    if (preservePending) {
      for (final entry in map.entries) {
        final val = entry.value;
        if (val is Map<String, dynamic>) {
          final syncStatus = val['sync_status'] as String?;
          if (syncStatus == SyncStatus.pending.value ||
              syncStatus == SyncStatus.failed.value ||
              syncStatus == SyncStatus.syncing.value) {
            pendingItems[entry.key] = val;
          }
        }
      }
    }

    final newMap = <String, dynamic>{};
    for (final exp in expenses) {
      newMap[exp.id] = exp.toLocalJson();
    }

    // Merge preserved pending items
    newMap.addAll(pendingItems);
    await _writeStorageMap(newMap);
  }

  @override
  Future<List<ExpenseModel>> getExpenses({String? userId}) async {
    final map = _readStorageMap();
    final list = <ExpenseModel>[];

    for (final entry in map.values) {
      if (entry is Map<String, dynamic>) {
        try {
          final model = ExpenseModel.fromJson(entry);
          if (userId == null || userId.isEmpty || model.userId == userId) {
            list.add(model);
          }
        } catch (e) {
          debugPrint('⚠️ [LocalExpenseDataSource] Corrupt item skipped: $e');
        }
      }
    }

    // Sort by date descending
    list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return list;
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    final map = _readStorageMap();
    final item = map[id];
    if (item is Map<String, dynamic>) {
      return ExpenseModel.fromJson(item);
    }
    return null;
  }

  @override
  Future<List<ExpenseModel>> getPendingExpenses({String? userId}) async {
    final map = _readStorageMap();
    final list = <ExpenseModel>[];

    for (final entry in map.values) {
      if (entry is Map<String, dynamic>) {
        final syncStatus = entry['sync_status'] as String?;
        if (syncStatus == SyncStatus.pending.value ||
            syncStatus == SyncStatus.failed.value ||
            syncStatus == SyncStatus.syncing.value) {
          try {
            final model = ExpenseModel.fromJson(entry);
            if (userId == null || userId.isEmpty || model.userId == userId) {
              list.add(model);
            }
          } catch (_) {}
        }
      }
    }

    return list;
  }

  @override
  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final map = _readStorageMap();
    final item = map[id];
    if (item is Map<String, dynamic>) {
      item['sync_status'] = status.value;
      item['updated_at'] = DateTime.now().toIso8601String();
      map[id] = item;
      await _writeStorageMap(map);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    final map = _readStorageMap();
    if (map.containsKey(id)) {
      map.remove(id);
      await _writeStorageMap(map);
    }
  }

  @override
  Future<void> clear() async {
    await prefs.remove(_storageKey);
  }
}
