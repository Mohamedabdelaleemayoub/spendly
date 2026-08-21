import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/expense.dart';
import '../models/admin_notification_model.dart';
import '../models/balance_transaction_model.dart';
import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../models/profile_model.dart';
import '../models/salary_advance_model.dart';
import '../models/weekly_allowance_model.dart';

/// Centralized Local Database for Spendly.
/// Provides offline storage, caching, and unified sync queue.
class LocalDatabase {
  LocalDatabase({Database? db}) {
    _db = db;
  }

  Database? _db;
  static const String _dbName = 'spendly_offline_v2.db';
  static const int _dbVersion = 1;

  Database get database {
    if (_db == null) {
      throw StateError('LocalDatabase is not initialized. Call init() first.');
    }
    return _db!;
  }

  bool get isInitialized => _db != null;

  Future<void> init({
    String? customPath,
    DatabaseFactory? customFactory,
    bool inMemory = false,
  }) async {
    if (_db != null && _db!.isOpen) return;

    if (kIsWeb) {
      return;
    }

    if (customFactory != null) {
      final String path = inMemory ? inMemoryDatabasePath : (customPath ?? inMemoryDatabasePath);
      _db = await customFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
        ),
      );
      return;
    }

    final String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docDir.path, _dbName);
    }

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    debugPrint('💾 [LocalDatabase] Initialized at path: $dbPath');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        role TEXT DEFAULT 'employee',
        status TEXT DEFAULT 'active',
        avatar_url TEXT,
        salary_amount REAL DEFAULT 0.0,
        salary_currency TEXT DEFAULT 'EGP',
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        title TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EGP',
        trip_location_type TEXT NOT NULL DEFAULT 'cairo',
        governorate TEXT DEFAULT 'cairo',
        payment_method TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        notes TEXT,
        receipt_url TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE allowance_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EGP',
        transaction_date TEXT NOT NULL,
        note TEXT,
        created_by TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE salary_advances (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EGP',
        advance_date TEXT NOT NULL,
        note TEXT,
        created_by TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE balance_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EGP',
        type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        note TEXT,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT,
        updated_by TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE admin_notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL DEFAULT 'registration_request',
        user_id TEXT,
        title TEXT,
        message TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        operation_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX idx_expenses_user_date ON expenses(user_id, expense_date);');
    await db.execute('CREATE INDEX idx_allowance_user_date ON allowance_transactions(user_id, transaction_date);');
    await db.execute('CREATE INDEX idx_salary_user_date ON salary_advances(user_id, advance_date);');
    await db.execute('CREATE INDEX idx_balance_user ON balance_transactions(user_id);');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status, created_at);');

    debugPrint('💾 [LocalDatabase] Tables and indexes created successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILES & EMPLOYEES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveProfile(ProfileModel profile) async {
    final db = database;
    await db.insert(
      'profiles',
      {
        'id': profile.id,
        'email': profile.email,
        'full_name': profile.name,
        'role': profile.role,
        'status': profile.status,
        'avatar_url': profile.avatarUrl,
        'salary_amount': profile.salaryAmount,
        'salary_currency': profile.salaryCurrency.code,
        'created_at': profile.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': profile.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveProfiles(List<ProfileModel> profiles) async {
    final db = database;
    final batch = db.batch();
    for (final profile in profiles) {
      batch.insert(
        'profiles',
        {
          'id': profile.id,
          'email': profile.email,
          'full_name': profile.name,
          'role': profile.role,
          'status': profile.status,
          'avatar_url': profile.avatarUrl,
          'salary_amount': profile.salaryAmount,
          'salary_currency': profile.salaryCurrency.code,
          'created_at': profile.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updated_at': profile.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<ProfileModel?> getProfile(String id) async {
    final db = database;
    final res = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return _profileFromRow(res.first);
  }

  Future<List<ProfileModel>> getProfiles() async {
    final db = database;
    final res = await db.query('profiles', orderBy: 'full_name ASC');
    return res.map(_profileFromRow).toList();
  }

  Future<void> deleteProfile(String id) async {
    final db = database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  ProfileModel _profileFromRow(Map<String, dynamic> row) {
    return ProfileModel.fromJson({
      'id': row['id'],
      'email': row['email'],
      'full_name': row['full_name'],
      'name': row['full_name'],
      'role': row['role'] ?? 'employee',
      'status': row['status'] ?? 'active',
      'avatar_url': row['avatar_url'],
      'salary_amount': row['salary_amount'] ?? 0.0,
      'salary_currency': row['salary_currency'] ?? 'EGP',
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORIES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveCategory(CategoryModel category) async {
    final db = database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'created_at': category.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': category.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    final db = database;
    final batch = db.batch();
    for (final cat in categories) {
      batch.insert(
        'categories',
        {
          'id': cat.id,
          'name': cat.name,
          'icon': cat.icon,
          'color': cat.color,
          'created_at': cat.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updated_at': cat.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = database;
    final res = await db.query('categories', orderBy: 'name ASC');
    return res.map((row) => CategoryModel.fromJson(row)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = database;
    final res = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return CategoryModel.fromJson(res.first);
  }

  Future<void> deleteCategory(String id) async {
    final db = database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPENSES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveExpense(ExpenseModel expense) async {
    final db = database;
    final nowStr = DateTime.now().toIso8601String();
    await db.insert(
      'expenses',
      {
        'id': expense.id,
        'user_id': expense.userId,
        'category_id': expense.categoryId,
        'title': expense.title,
        'amount': expense.amount,
        'currency': expense.currency.code,
        'trip_location_type': expense.tripLocationType.name,
        'governorate': expense.governorate.name,
        'payment_method': expense.paymentMethod,
        'expense_date': expense.expenseDate.toIso8601String(),
        'notes': expense.notes,
        'receipt_url': expense.receiptUrl,
        'sync_status': expense.syncStatus.value,
        'created_at': expense.createdAt?.toIso8601String() ?? nowStr,
        'updated_at': expense.updatedAt?.toIso8601String() ?? nowStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveExpenses(List<ExpenseModel> expenses, {bool preservePending = true}) async {
    final db = database;
    final batch = db.batch();
    final nowStr = DateTime.now().toIso8601String();

    final Set<String> pendingIds = {};
    if (preservePending) {
      final pendingRows = await db.query(
        'expenses',
        columns: ['id'],
        where: "sync_status IN ('pending', 'syncing', 'failed')",
      );
      for (final r in pendingRows) {
        pendingIds.add(r['id'] as String);
      }
    }

    for (final exp in expenses) {
      if (preservePending && pendingIds.contains(exp.id)) {
        continue;
      }
      batch.insert(
        'expenses',
        {
          'id': exp.id,
          'user_id': exp.userId,
          'category_id': exp.categoryId,
          'title': exp.title,
          'amount': exp.amount,
          'currency': exp.currency.code,
          'trip_location_type': exp.tripLocationType.name,
          'governorate': exp.governorate.name,
          'payment_method': exp.paymentMethod,
          'expense_date': exp.expenseDate.toIso8601String(),
          'notes': exp.notes,
          'receipt_url': exp.receiptUrl,
          'sync_status': exp.syncStatus.value,
          'created_at': exp.createdAt?.toIso8601String() ?? nowStr,
          'updated_at': exp.updatedAt?.toIso8601String() ?? nowStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ExpenseModel>> getExpenses({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? paymentMethod,
    String? currency,
    String? tripLocationType,
    String? governorate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null && userId.isNotEmpty) {
      conditions.add('user_id = ?');
      args.add(userId);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      conditions.add('payment_method = ?');
      args.add(paymentMethod);
    }
    if (currency != null && currency.isNotEmpty) {
      conditions.add('currency = ?');
      args.add(currency.toUpperCase());
    }
    if (tripLocationType != null && tripLocationType.isNotEmpty) {
      conditions.add('trip_location_type = ?');
      args.add(tripLocationType);
    }
    if (governorate != null && governorate.isNotEmpty) {
      conditions.add('governorate = ?');
      args.add(governorate);
    }
    if (startDate != null) {
      conditions.add('expense_date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('expense_date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR notes LIKE ?)');
      final pattern = '%${searchQuery.trim()}%';
      args.add(pattern);
      args.add(pattern);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final rows = await db.query(
      'expenses',
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'expense_date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    final categories = await getCategories();
    final catMap = {for (final c in categories) c.id: c};
    final profiles = await getProfiles();
    final profMap = {for (final p in profiles) p.id: p};

    return rows.map((r) => _expenseFromRow(r, catMap: catMap, profMap: profMap)).toList();
  }

  Future<ExpenseModel?> getExpenseById(String id) async {
    final db = database;
    final rows = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final cat = rows.first['category_id'] != null ? await getCategoryById(rows.first['category_id'] as String) : null;
    final prof = rows.first['user_id'] != null ? await getProfile(rows.first['user_id'] as String) : null;
    return _expenseFromRow(
      rows.first,
      catMap: cat != null ? {cat.id: cat} : null,
      profMap: prof != null ? {prof.id: prof} : null,
    );
  }

  Future<List<ExpenseModel>> getPendingExpenses({String? userId}) async {
    final db = database;
    final conditions = ["sync_status IN ('pending', 'syncing', 'failed')"];
    final args = <dynamic>[];
    if (userId != null && userId.isNotEmpty) {
      conditions.add('user_id = ?');
      args.add(userId);
    }

    final rows = await db.query(
      'expenses',
      where: conditions.join(' AND '),
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => _expenseFromRow(r)).toList();
  }

  Future<void> updateExpenseSyncStatus(String id, SyncStatus status) async {
    final db = database;
    await db.update(
      'expenses',
      {
        'sync_status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  ExpenseModel _expenseFromRow(
    Map<String, dynamic> row, {
    Map<String, CategoryModel>? catMap,
    Map<String, ProfileModel>? profMap,
  }) {
    final catId = row['category_id'] as String?;
    final userId = row['user_id'] as String?;
    final cat = catId != null && catMap != null ? catMap[catId] : null;
    final prof = userId != null && profMap != null ? profMap[userId] : null;

    return ExpenseModel.fromJson({
      'id': row['id'],
      'user_id': row['user_id'],
      'category_id': row['category_id'],
      'title': row['title'],
      'amount': row['amount'],
      'currency': row['currency'],
      'trip_location_type': row['trip_location_type'],
      'governorate': row['governorate'],
      'payment_method': row['payment_method'],
      'expense_date': row['expense_date'],
      'notes': row['notes'],
      'receipt_url': row['receipt_url'],
      'sync_status': row['sync_status'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      if (cat != null) 'category': cat.toJson(),
      if (prof != null) 'profile': prof.toJson(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ALLOWANCE TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveAllowanceTransaction(WeeklyAllowanceModel item) async {
    final db = database;
    await db.insert(
      'allowance_transactions',
      {
        'id': item.id,
        'user_id': item.userId,
        'amount': item.amount,
        'currency': item.currency.code,
        'transaction_date': item.transactionDate.toIso8601String(),
        'note': item.note,
        'created_by': item.createdBy,
        'sync_status': 'synced',
        'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': item.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllowanceTransactions(List<WeeklyAllowanceModel> items) async {
    final db = database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'allowance_transactions',
        {
          'id': item.id,
          'user_id': item.userId,
          'amount': item.amount,
          'currency': item.currency.code,
          'transaction_date': item.transactionDate.toIso8601String(),
          'note': item.note,
          'created_by': item.createdBy,
          'sync_status': 'synced',
          'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updated_at': item.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<WeeklyAllowanceModel>> getAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = database;
    final conditions = ['user_id = ?'];
    final args = <dynamic>[userId];

    if (startDate != null) {
      conditions.add('transaction_date >= ?');
      args.add(startDate.toIso8601String().split('T').first);
    }
    if (endDate != null) {
      conditions.add('transaction_date <= ?');
      args.add(endDate.toIso8601String().split('T').first);
    }

    final rows = await db.query(
      'allowance_transactions',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return rows.map((r) => WeeklyAllowanceModel.fromJson(r)).toList();
  }

  Future<List<WeeklyAllowanceModel>> getAllAllowanceTransactions() async {
    final db = database;
    final rows = await db.query(
      'allowance_transactions',
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map((r) => WeeklyAllowanceModel.fromJson(r)).toList();
  }

  Future<void> deleteAllowanceTransaction(String id) async {
    final db = database;
    await db.delete('allowance_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SALARY ADVANCES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveSalaryAdvance(SalaryAdvanceModel item) async {
    final db = database;
    await db.insert(
      'salary_advances',
      {
        'id': item.id,
        'user_id': item.userId,
        'amount': item.amount,
        'currency': item.currency.code,
        'advance_date': item.advanceDate.toIso8601String(),
        'note': item.note,
        'created_by': item.createdBy,
        'sync_status': 'synced',
        'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': item.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSalaryAdvances(List<SalaryAdvanceModel> items) async {
    final db = database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'salary_advances',
        {
          'id': item.id,
          'user_id': item.userId,
          'amount': item.amount,
          'currency': item.currency.code,
          'advance_date': item.advanceDate.toIso8601String(),
          'note': item.note,
          'created_by': item.createdBy,
          'sync_status': 'synced',
          'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updated_at': item.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SalaryAdvanceModel>> getSalaryAdvances(String userId) async {
    final db = database;
    final rows = await db.query(
      'salary_advances',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'advance_date DESC, created_at DESC',
    );
    return rows.map((r) => SalaryAdvanceModel.fromJson(r)).toList();
  }

  Future<List<SalaryAdvanceModel>> getAllSalaryAdvances() async {
    final db = database;
    final rows = await db.query(
      'salary_advances',
      orderBy: 'advance_date DESC, created_at DESC',
    );
    return rows.map((r) => SalaryAdvanceModel.fromJson(r)).toList();
  }

  Future<void> deleteSalaryAdvance(String id) async {
    final db = database;
    await db.delete('salary_advances', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BALANCE TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveBalanceTransaction(BalanceTransactionModel item) async {
    final db = database;
    await db.insert(
      'balance_transactions',
      {
        'id': item.id,
        'user_id': item.userId,
        'amount': item.amount,
        'currency': item.currency.code,
        'type': item.type.toDbString(),
        'transaction_date': item.transactionDate.toIso8601String(),
        'note': item.note,
        'created_by': item.createdBy,
        'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveBalanceTransactions(List<BalanceTransactionModel> items) async {
    final db = database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'balance_transactions',
        {
          'id': item.id,
          'user_id': item.userId,
          'amount': item.amount,
          'currency': item.currency.code,
          'type': item.type.toDbString(),
          'transaction_date': item.transactionDate.toIso8601String(),
          'note': item.note,
          'created_by': item.createdBy,
          'created_at': item.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<BalanceTransactionModel>> getBalanceTransactions(String userId) async {
    final db = database;
    final rows = await db.query(
      'balance_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map((r) => BalanceTransactionModel.fromJson(r)).toList();
  }

  Future<List<BalanceTransactionModel>> getAllBalanceTransactions() async {
    final db = database;
    final rows = await db.query(
      'balance_transactions',
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map((r) => BalanceTransactionModel.fromJson(r)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveSetting(String key, dynamic value, {String? updatedBy}) async {
    final db = database;
    final data = <String, dynamic>{
      'key': key,
      'value': jsonEncode(value),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (updatedBy != null) {
      data['updated_by'] = updatedBy;
    }
    await db.insert(
      'app_settings',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getSetting(String key) async {
    final db = database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first['value'] as String);
    } catch (_) {
      return rows.first['value'];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADMIN NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveNotifications(List<AdminNotificationModel> notifications) async {
    final db = database;
    final batch = db.batch();
    for (final notif in notifications) {
      batch.insert(
        'admin_notifications',
        {
          'id': notif.id,
          'type': notif.type,
          'user_id': notif.userId,
          'title': notif.title,
          'message': notif.message,
          'is_read': notif.isRead ? 1 : 0,
          'created_at': notif.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AdminNotificationModel>> getNotifications() async {
    final db = database;
    final rows = await db.query(
      'admin_notifications',
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return rows.map((r) {
      return AdminNotificationModel.fromJson({
        'id': r['id'],
        'type': r['type'] ?? 'registration_request',
        'user_id': r['user_id'],
        'title': r['title'],
        'message': r['message'],
        'is_read': (r['is_read'] as int?) == 1,
        'created_at': r['created_at'],
      });
    }).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = database;
    await db.update(
      'admin_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllNotificationsAsRead() async {
    final db = database;
    await db.update('admin_notifications', {'is_read': 1});
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CENTRALIZED SYNC QUEUE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> enqueueSyncOperation({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'sync_queue',
      {
        'operation_id': operationId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': jsonEncode(payload),
        'status': 'pending',
        'retry_count': 0,
        'last_error': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('📥 [LocalDatabase] Enqueued $operation for $entityType (ID: $entityId, Op: $operationId)');
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = database;
    return await db.query(
      'sync_queue',
      where: "status IN ('pending', 'syncing', 'failed')",
      orderBy: 'created_at ASC',
    );
  }

  Future<void> updateSyncOperationStatus({
    required String operationId,
    required String status,
    int? retryCount,
    String? lastError,
  }) async {
    final db = database;
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (retryCount != null) updateData['retry_count'] = retryCount;
    if (lastError != null) updateData['last_error'] = lastError;

    await db.update(
      'sync_queue',
      updateData,
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> deleteSyncOperation(String operationId) async {
    final db = database;
    await db.delete('sync_queue', where: 'operation_id = ?', whereArgs: [operationId]);
  }

  Future<void> clearAll() async {
    final db = database;
    await db.delete('profiles');
    await db.delete('categories');
    await db.delete('expenses');
    await db.delete('allowance_transactions');
    await db.delete('salary_advances');
    await db.delete('balance_transactions');
    await db.delete('app_settings');
    await db.delete('admin_notifications');
    await db.delete('sync_queue');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
