import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/uuid_generator.dart';
import 'package:spendly/data/datasources/local_database.dart';
import 'package:spendly/data/models/audit_log_model.dart';
import 'package:spendly/data/models/category_model.dart';
import 'package:spendly/data/models/expense_model.dart';
import 'package:spendly/data/models/weekly_allowance_model.dart';
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

  group('1. Audit Logs Persistence & Filtering', () {
    test('Saves, queries, and filters audit logs by entity and action', () async {
      final now = DateTime.now();

      final log1 = AuditLogModel(
        id: 'aud_1',
        userId: 'usr_admin',
        userName: 'Admin User',
        action: 'expense_created',
        entityType: 'expense',
        entityId: 'exp_100',
        newValue: {'amount': 450.0, 'currency': 'EGP'},
        createdAt: now,
      );

      final log2 = AuditLogModel(
        id: 'aud_2',
        userId: 'usr_admin',
        userName: 'Admin User',
        action: 'salary_advance_created',
        entityType: 'salary_advance',
        entityId: 'adv_200',
        newValue: {'amount': 1000.0},
        createdAt: now.add(const Duration(seconds: 1)),
      );

      await localDb.saveAuditLog(log1);
      await localDb.saveAuditLog(log2);

      final allLogs = await localDb.getAuditLogs();
      expect(allLogs.length, equals(2));

      // Filter by entity_type
      final expenseLogs = await localDb.getAuditLogs(entityType: 'expense');
      expect(expenseLogs.length, equals(1));
      expect(expenseLogs.first.id, equals('aud_1'));
      expect(expenseLogs.first.action, equals('expense_created'));
      expect(expenseLogs.first.newValue?['amount'], equals(450.0));

      // Filter by action
      final advanceLogs = await localDb.getAuditLogs(action: 'salary_advance_created');
      expect(advanceLogs.length, equals(1));
      expect(advanceLogs.first.entityType, equals('salary_advance'));
    });
  });

  group('2. Delete Synchronization & Resurrection Prevention', () {
    test('Deleted records in sync_queue are NOT resurrected during pull sync', () async {
      final now = DateTime.now();

      final exp1 = ExpenseModel(
        id: 'exp_to_delete',
        userId: 'usr_1',
        title: 'تذكرة قطار',
        amount: 150.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: now,
        syncStatus: SyncStatus.synced,
      );

      final exp2 = ExpenseModel(
        id: 'exp_to_keep',
        userId: 'usr_1',
        title: 'عشاء عمل',
        amount: 300.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: now,
        syncStatus: SyncStatus.synced,
      );

      // Initially save both
      await localDb.saveExpenses([exp1, exp2]);
      expect((await localDb.getExpenses()).length, equals(2));

      // User deletes exp1 offline:
      // 1. Delete from expenses table
      await localDb.deleteExpense('exp_to_delete');
      // 2. Enqueue DELETE operation in sync_queue
      await localDb.enqueueSyncOperation(
        operationId: UuidGenerator.generate(),
        entityType: 'expense',
        entityId: 'exp_to_delete',
        operation: 'DELETE',
        payload: {'id': 'exp_to_delete'},
      );

      expect((await localDb.getExpenses()).length, equals(1));

      // Simulate remote pull that returns the remote list (still containing exp1 before remote delete is pushed)
      final remoteList = [exp1, exp2];
      await localDb.saveExpenses(remoteList, preservePending: true);

      // Verify exp1 was NOT resurrected!
      final localExpensesAfterPull = await localDb.getExpenses();
      expect(localExpensesAfterPull.length, equals(1));
      expect(localExpensesAfterPull.first.id, equals('exp_to_keep'));
    });

    test('Deleted allowance transactions are NOT resurrected during pull sync', () async {
      final now = DateTime.now();

      final allow1 = WeeklyAllowanceModel(
        id: 'allow_del',
        userId: 'usr_1',
        amount: 1000.0,
        currency: ExpenseCurrency.egp,
        transactionDate: now,
        createdBy: 'admin_1',
      );

      await localDb.saveAllowanceTransaction(allow1);
      expect((await localDb.getAllowanceTransactions(userId: 'usr_1')).length, equals(1));

      // Delete locally and enqueue
      await localDb.deleteAllowanceTransaction('allow_del');
      await localDb.enqueueSyncOperation(
        operationId: UuidGenerator.generate(),
        entityType: 'allowance_transaction',
        entityId: 'allow_del',
        operation: 'DELETE',
        payload: {'id': 'allow_del'},
      );

      expect((await localDb.getAllowanceTransactions(userId: 'usr_1')).isEmpty, isTrue);

      // Simulate pull sync with stale server data
      await localDb.saveAllowanceTransactions([allow1]);

      // Verify it remains deleted
      final listAfterPull = await localDb.getAllowanceTransactions(userId: 'usr_1');
      expect(listAfterPull.isEmpty, isTrue);
    });
  });

  group('3. Multi-Currency Reports & Aggregations Isolation', () {
    test('Calculates separate EGP and USD totals and breakdowns', () async {
      final now = DateTime.now();

      final catFood = CategoryModel(id: 'cat_food', name: 'طعام', icon: 'restaurant', color: '#FF5722');
      final catTravel = CategoryModel(id: 'cat_travel', name: 'سفر', icon: 'flight', color: '#2196F3');
      await localDb.saveCategories([catFood, catTravel]);

      // EGP Expenses: 500 (Food), 300 (Travel) = 800 EGP
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_egp_1',
        userId: 'usr_1',
        categoryId: 'cat_food',
        amount: 500.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'cash',
        expenseDate: now,
      ));
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_egp_2',
        userId: 'usr_1',
        categoryId: 'cat_travel',
        amount: 300.0,
        currency: ExpenseCurrency.egp,
        paymentMethod: 'credit_card',
        expenseDate: now,
      ));

      // USD Expenses: 50 (Travel) = 50 USD
      await localDb.saveExpense(ExpenseModel(
        id: 'exp_usd_1',
        userId: 'usr_1',
        categoryId: 'cat_travel',
        amount: 50.0,
        currency: ExpenseCurrency.usd,
        paymentMethod: 'credit_card',
        expenseDate: now,
      ));

      final allExpenses = await localDb.getExpenses();

      double totalEgp = 0;
      double totalUsd = 0;
      for (final e in allExpenses) {
        if (e.currency == ExpenseCurrency.usd) {
          totalUsd += e.amount;
        } else {
          totalEgp += e.amount;
        }
      }

      expect(totalEgp, equals(800.0));
      expect(totalUsd, equals(50.0));

      // Filter by EGP only
      final egpExpenses = await localDb.getExpenses(currency: 'EGP');
      expect(egpExpenses.length, equals(2));

      // Filter by USD only
      final usdExpenses = await localDb.getExpenses(currency: 'USD');
      expect(usdExpenses.length, equals(1));
      expect(usdExpenses.first.amount, equals(50.0));
    });
  });
}
