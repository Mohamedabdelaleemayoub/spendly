import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/uuid_generator.dart';
import 'package:spendly/data/datasources/local_database.dart';
import 'package:spendly/data/models/admin_notification_model.dart';
import 'package:spendly/data/models/balance_transaction_model.dart';
import 'package:spendly/data/models/category_model.dart';
import 'package:spendly/data/models/expense_model.dart';
import 'package:spendly/data/models/profile_model.dart';
import 'package:spendly/data/models/salary_advance_model.dart';
import 'package:spendly/data/models/weekly_allowance_model.dart';
import 'package:spendly/domain/entities/balance_transaction.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/governorate.dart';
import 'package:spendly/domain/entities/trip_location_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late LocalDatabase localDb;

  setUp(() async {
    localDb = LocalDatabase();
    await localDb.init(customFactory: databaseFactoryFfi, inMemory: true);
  });

  tearDown(() async {
    await localDb.close();
  });

  group('1. UUID Generation & Idempotency', () {
    test('UuidGenerator creates RFC 4122 v4 UUIDs', () {
      final uuid1 = UuidGenerator.generate();
      final uuid2 = UuidGenerator.generate();

      expect(uuid1, isNotEmpty);
      expect(uuid2, isNotEmpty);
      expect(uuid1, isNot(equals(uuid2)));

      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(uuid1), isTrue);
      expect(uuidRegex.hasMatch(uuid2), isTrue);
    });
  });

  group('2. LocalDatabase Persistence & Queries', () {
    test('Profiles: save, retrieve and delete profile', () async {
      const profile = ProfileModel(
        id: 'usr_1',
        name: 'أحمد محمد',
        email: 'ahmed@spendly.com',
        role: 'employee',
        status: 'active',
        salaryAmount: 5000.0,
        salaryCurrency: ExpenseCurrency.egp,
      );

      await localDb.saveProfile(profile);
      final retrieved = await localDb.getProfile('usr_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('usr_1'));
      expect(retrieved.name, equals('أحمد محمد'));
      expect(retrieved.salaryAmount, equals(5000.0));

      final all = await localDb.getProfiles();
      expect(all.length, equals(1));

      await localDb.deleteProfile('usr_1');
      expect(await localDb.getProfile('usr_1'), isNull);
    });

    test('Categories: save, list and get by id', () async {
      final now = DateTime.now();
      final cat = CategoryModel(
        id: 'cat_travel',
        name: 'سفر وانتقالات',
        icon: 'flight',
        color: '#3498db',
        createdAt: now,
        updatedAt: now,
      );

      await localDb.saveCategory(cat);
      final list = await localDb.getCategories();
      expect(list.length, equals(1));
      expect(list.first.name, equals('سفر وانتقالات'));

      final single = await localDb.getCategoryById('cat_travel');
      expect(single, isNotNull);
      expect(single!.icon, equals('flight'));
    });

    test('Expenses: save, query with filters and preserve pending status', () async {
      final now = DateTime.now();
      final exp1 = ExpenseModel(
        id: 'exp_1',
        userId: 'usr_1',
        title: 'غداء عمل',
        amount: 250.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: now,
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final exp2 = ExpenseModel(
        id: 'exp_2',
        userId: 'usr_1',
        title: 'فندق الإسكندرية',
        amount: 1500.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.outsideCairo,
        governorate: Governorate.alexandria,
        paymentMethod: 'cash',
        expenseDate: now,
        syncStatus: SyncStatus.synced,
        createdAt: now,
        updatedAt: now,
      );

      await localDb.saveExpense(exp1);
      await localDb.saveExpense(exp2);

      final allUserExps = await localDb.getExpenses(userId: 'usr_1');
      expect(allUserExps.length, equals(2));

      final pending = await localDb.getPendingExpenses(userId: 'usr_1');
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('exp_1'));

      final outsideCairo = await localDb.getExpenses(tripLocationType: 'outsideCairo');
      expect(outsideCairo.length, equals(1));
      expect(outsideCairo.first.id, equals('exp_2'));
    });

    test('Weekly Allowances: save, query by user and date range', () async {
      final now = DateTime.now();
      final allowance = WeeklyAllowanceModel(
        id: 'all_1',
        userId: 'usr_1',
        amount: 3000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
        note: 'عهدة أسبوعية لمشروع القاهرة',
        createdBy: 'admin_1',
        createdAt: now,
        updatedAt: now,
      );

      await localDb.saveAllowanceTransaction(allowance);
      final txs = await localDb.getAllowanceTransactions(userId: 'usr_1');

      expect(txs.length, equals(1));
      expect(txs.first.amount, equals(3000.0));
      expect(txs.first.note, equals('عهدة أسبوعية لمشروع القاهرة'));
    });

    test('Salary Advances: save and query independently of allowances', () async {
      final now = DateTime.now();
      final adv = SalaryAdvanceModel(
        id: 'adv_1',
        userId: 'usr_1',
        amount: 1000.0,
        currency: ExpenseCurrency.egp,
        advanceDate: now,
        note: 'سلفة على راتب الشهر',
        createdBy: 'admin_1',
        createdAt: now,
        updatedAt: now,
      );

      await localDb.saveSalaryAdvance(adv);
      final advances = await localDb.getSalaryAdvances('usr_1');

      expect(advances.length, equals(1));
      expect(advances.first.amount, equals(1000.0));

      // Verify allowances table remains untouched
      final allowances = await localDb.getAllowanceTransactions(userId: 'usr_1');
      expect(allowances.isEmpty, isTrue);
    });

    test('Balance Transactions: save and query credit / adjustment', () async {
      final now = DateTime.now();
      final bTx = BalanceTransactionModel(
        id: 'btx_1',
        userId: 'usr_1',
        amount: 5000.0,
        currency: ExpenseCurrency.egp,
        type: BalanceTransactionType.credit,
        transactionDate: now,
        note: 'شحن رصيد نقدي',
        createdAt: now,
      );

      await localDb.saveBalanceTransaction(bTx);
      final list = await localDb.getBalanceTransactions('usr_1');

      expect(list.length, equals(1));
      expect(list.first.amount, equals(5000.0));
      expect(list.first.type, equals(BalanceTransactionType.credit));
    });

    test('Settings & Admin Notifications: save and read', () async {
      await localDb.saveSetting('require_admin_approval', {'enabled': true});
      final setting = await localDb.getSetting('require_admin_approval');
      expect(setting, isNotNull);
      expect(setting['enabled'], equals(true));

      final notif = AdminNotificationModel(
        id: 'notif_1',
        type: 'expense_created',
        userId: 'usr_1',
        title: 'مصروف جديد',
        message: 'قام الموظف بإضافة مصروف جديد',
        isRead: false,
        createdAt: DateTime.now(),
      );
      await localDb.saveNotifications([notif]);

      final notifs = await localDb.getNotifications();
      expect(notifs.length, equals(1));
      expect(notifs.first.title, equals('مصروف جديد'));

      await localDb.markNotificationAsRead('notif_1');
      final updatedNotifs = await localDb.getNotifications();
      expect(updatedNotifs.first.isRead, isTrue);
    });
  });

  group('3. Centralized Sync Queue (FIFO, Updates, Deletions)', () {
    test('Enqueues operations and returns in FIFO order', () async {
      await localDb.enqueueSyncOperation(
        operationId: 'op_1',
        entityType: 'expense',
        entityId: 'exp_1',
        operation: 'INSERT',
        payload: {'id': 'exp_1', 'amount': 100.0},
      );

      await localDb.enqueueSyncOperation(
        operationId: 'op_2',
        entityType: 'allowance_transaction',
        entityId: 'all_1',
        operation: 'INSERT',
        payload: {'id': 'all_1', 'amount': 500.0},
      );

      final pending = await localDb.getPendingSyncOperations();
      expect(pending.length, equals(2));
      expect(pending[0]['operation_id'], equals('op_1'));
      expect(pending[1]['operation_id'], equals('op_2'));

      // Update status to syncing
      await localDb.updateSyncOperationStatus(
        operationId: 'op_1',
        status: 'syncing',
        retryCount: 1,
      );

      final updated = await localDb.getPendingSyncOperations();
      expect(updated.first['retry_count'], equals(1));

      // Delete completed operation
      await localDb.deleteSyncOperation('op_1');
      final remaining = await localDb.getPendingSyncOperations();
      expect(remaining.length, equals(1));
      expect(remaining.first['operation_id'], equals('op_2'));
    });
  });

  group('4. Offline Weekly Allowance & Currency Isolation', () {
    test('Calculates received, spent, and remaining strictly isolated for EGP and USD', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 3);
      final end = DateTime(now.year, now.month, now.day + 3);

      // EGP Allowance: 2000
      await localDb.saveAllowanceTransaction(WeeklyAllowanceModel(
        id: 'all_egp_1',
        userId: 'usr_1',
        amount: 2000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
        createdBy: 'admin_1',
      ));

      // USD Allowance: 100
      await localDb.saveAllowanceTransaction(WeeklyAllowanceModel(
        id: 'all_usd_1',
        userId: 'usr_1',
        amount: 100.0,
        currency: ExpenseCurrency.usd,
        transactionDate: now,
        createdBy: 'admin_1',
      ));

      // EGP Expenses: 500 + 300 = 800
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_egp_1',
        userId: 'usr_1',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: now,
      ));
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_egp_2',
        userId: 'usr_1',
        amount: 300.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: now,
      ));

      // USD Expenses: 40
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_usd_1',
        userId: 'usr_1',
        amount: 40.0,
        currency: ExpenseCurrency.usd,
        paymentMethod: 'cash',
        expenseDate: now,
      ));

      // Query allowances and expenses for calculation
      final allowances = await localDb.getAllowanceTransactions(
        userId: 'usr_1',
        startDate: start,
        endDate: end,
      );
      final expenses = await localDb.getExpenses(
        userId: 'usr_1',
        startDate: start,
        endDate: end,
      );

      double receivedEgp = 0;
      double receivedUsd = 0;
      for (final a in allowances) {
        if (a.currency == ExpenseCurrency.usd) {
          receivedUsd += a.amount;
        } else {
          receivedEgp += a.amount;
        }
      }

      double spentEgp = 0;
      double spentUsd = 0;
      for (final e in expenses) {
        if (e.currency == ExpenseCurrency.usd) {
          spentUsd += e.amount;
        } else {
          spentEgp += e.amount;
        }
      }

      expect(receivedEgp, equals(2000.0));
      expect(spentEgp, equals(800.0));
      expect(receivedEgp - spentEgp, equals(1200.0)); // المتبقي EGP

      expect(receivedUsd, equals(100.0));
      expect(spentUsd, equals(40.0));
      expect(receivedUsd - spentUsd, equals(60.0)); // المتبقي USD
    });
  });
}
