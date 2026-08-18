import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/services/uuid_generator.dart';
import 'package:spendly/data/datasources/local_expense_datasource.dart';
import 'package:spendly/data/models/expense_model.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/employee_travel_stats.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/governorate.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/entities/travel_bonus_settings.dart';
import 'package:spendly/domain/entities/trip_location_type.dart';
import 'package:spendly/domain/repositories/expense_repository.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/domain/repositories/settings_repository.dart';
import 'package:spendly/presentation/cubits/employee_details/employee_details_cubit.dart';
import 'package:spendly/presentation/cubits/employee_details/employee_details_state.dart';
import 'package:spendly/presentation/cubits/settings/admin_settings_cubit.dart';
import 'package:spendly/presentation/cubits/settings/admin_settings_state.dart';

class MockExpenseRepository implements ExpenseRepository {
  List<Expense> mockExpenses = [];

  @override
  Future<List<Expense>> getExpenses({
    int page = 0,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? userId,
    String? paymentMethod,
    ExpenseCurrency? currency,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? searchQuery,
  }) async {
    return mockExpenses.where((e) {
      if (userId != null && e.userId != userId) return false;
      if (currency != null && e.currency != currency) return false;
      if (tripLocationType != null && e.tripLocationType != tripLocationType) return false;
      if (governorate != null && e.governorate != governorate) return false;
      if (startDate != null && e.expenseDate.isBefore(startDate)) return false;
      if (endDate != null && e.expenseDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  @override
  Future<Expense> getExpenseById(String id) async =>
      mockExpenses.firstWhere((e) => e.id == id);

  @override
  Future<Expense> createExpense({
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
  }) async {
    final exp = Expense(
      id: UuidGenerator.generate(),
      userId: 'user-1',
      title: title,
      amount: amount,
      currency: currency,
      tripLocationType: tripLocationType,
      governorate: tripLocationType == TripLocationType.cairo ? Governorate.cairo : governorate,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      notes: notes,
    );
    mockExpenses.add(exp);
    return exp;
  }

  @override
  Future<Expense> updateExpense({
    required String id,
    String title = '',
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    TripLocationType tripLocationType = TripLocationType.cairo,
    Governorate governorate = Governorate.cairo,
    required String paymentMethod,
    required DateTime expenseDate,
    String? categoryId,
    String? notes,
    File? receiptFile,
    String? existingReceiptUrl,
  }) async {
    final index = mockExpenses.indexWhere((e) => e.id == id);
    final updated = Expense(
      id: id,
      userId: 'user-1',
      title: title,
      amount: amount,
      currency: currency,
      tripLocationType: tripLocationType,
      governorate: tripLocationType == TripLocationType.cairo ? Governorate.cairo : governorate,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      notes: notes,
    );
    if (index >= 0) {
      mockExpenses[index] = updated;
    } else {
      mockExpenses.add(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    mockExpenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month, {String? userId, ExpenseCurrency? currency}) async {
    return mockExpenses;
  }

  @override
  Future<int> syncPendingExpenses({String? userId}) async => 0;
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<Profile?> getProfile(String id) async => Profile(
        id: id,
        name: 'Ahmed',
        email: 'ahmed@test.com',
        role: 'employee',
        status: 'active',
      );

  @override
  Future<List<Profile>> getEmployees() async => [
        const Profile(
          id: 'user-1',
          name: 'Ahmed',
          email: 'ahmed@test.com',
          role: 'employee',
          status: 'active',
        ),
      ];

  @override
  Future<Profile> updateProfile(Profile profile) async => profile;

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async => 'url';

  @override
  Future<void> deleteAvatar(String userId) async {}

  @override
  Future<Profile> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  }) async => Profile(id: userId, name: name, email: email, role: 'employee', status: 'active');

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async => [];

  @override
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async => Profile(id: 'new-emp', name: fullName, email: email, role: role, status: 'active');

  @override
  Future<void> deleteEmployee(String userId) async {}

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {}

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) async {}

  @override
  Future<void> approveUser(String userId) async {}

  @override
  Future<void> rejectUser(String userId) async {}
}

class MockSettingsRepository implements SettingsRepository {
  bool requireApproval = false;
  TravelBonusSettings travelBonus = const TravelBonusSettings();

  @override
  Future<bool> getRequireAdminApproval() async => requireApproval;

  @override
  Future<void> setRequireAdminApproval(bool enabled) async {
    requireApproval = enabled;
  }

  @override
  Future<TravelBonusSettings> getTravelBonusSettings() async => travelBonus;

  @override
  Future<void> setTravelBonusSettings(TravelBonusSettings settings) async {
    travelBonus = settings;
  }
}

void main() {
  group('Trip Location & Out-of-Cairo Travel Tracking Tests', () {
    late LocalExpenseDataSource localDataSource;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = LocalExpenseDataSourceImpl(prefs: prefs);
    });

    test('1. Cairo expense stores cairo and defaults governorate to cairo', () {
      final expense = Expense(
        id: 'exp-cairo-1',
        userId: 'user-1',
        amount: 250.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.cairo,
        governorate: Governorate.cairo,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
      );

      expect(expense.tripLocationType, equals(TripLocationType.cairo));
      expect(expense.governorate, equals(Governorate.cairo));
      expect(expense.isOutsideCairo, isFalse);

      final model = ExpenseModel.fromEntity(expense);
      final json = model.toJson();
      expect(json['trip_location_type'], equals('cairo'));
      expect(json['governorate'], equals('cairo'));
    });

    test('2. Outside-Cairo expense requires and validates governorate', () {
      final outsideGovs = Governorate.outsideCairoGovernorates;
      expect(outsideGovs.contains(Governorate.cairo), isFalse);
      expect(outsideGovs.contains(Governorate.fayoum), isTrue);
      expect(outsideGovs.contains(Governorate.giza), isTrue);
      expect(outsideGovs.contains(Governorate.alexandria), isTrue);

      // Deserialization with fallback
      final gov = Governorate.fromString('fayoum');
      expect(gov, equals(Governorate.fayoum));
      expect(gov.localizedName('en'), equals('Fayoum'));
      expect(gov.localizedName('ar'), equals('الفيوم'));
    });

    test('3. Outside-Cairo expense stores governorate correctly in JSON and DB payload', () {
      final expense = Expense(
        id: 'exp-out-1',
        userId: 'user-1',
        amount: 800.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.outsideCairo,
        governorate: Governorate.alexandria,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
      );

      expect(expense.tripLocationType, equals(TripLocationType.outsideCairo));
      expect(expense.governorate, equals(Governorate.alexandria));
      expect(expense.isOutsideCairo, isTrue);

      final model = ExpenseModel.fromEntity(expense);
      final json = model.toJson();
      expect(json['trip_location_type'], equals('outside_cairo'));
      expect(json['governorate'], equals('alexandria'));
    });

    test('4. Employee statistics correctly count total, inside Cairo, and outside Cairo trips', () {
      final expenses = [
        Expense(
          id: '1',
          userId: 'user-1',
          amount: 100,
          tripLocationType: TripLocationType.cairo,
          governorate: Governorate.cairo,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '2',
          userId: 'user-1',
          amount: 200,
          tripLocationType: TripLocationType.cairo,
          governorate: Governorate.cairo,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '3',
          userId: 'user-1',
          amount: 500,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '4',
          userId: 'user-1',
          amount: 600,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.alexandria,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '5',
          userId: 'user-1',
          amount: 400,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
      ];

      final stats = EmployeeTravelStats.fromExpenses(expenses);

      expect(stats.totalTrips, equals(5));
      expect(stats.insideCairoTrips, equals(2));
      expect(stats.outsideCairoTrips, equals(3));
    });

    test('5. Governorate breakdown aggregates outside-Cairo trips correctly', () {
      final expenses = [
        Expense(
          id: '1',
          userId: 'user-1',
          amount: 100,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '2',
          userId: 'user-1',
          amount: 200,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '3',
          userId: 'user-1',
          amount: 300,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '4',
          userId: 'user-1',
          amount: 400,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.giza,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '5',
          userId: 'user-1',
          amount: 500,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.alexandria,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
      ];

      final stats = EmployeeTravelStats.fromExpenses(expenses);

      expect(stats.governorateBreakdown[Governorate.fayoum], equals(3));
      expect(stats.governorateBreakdown[Governorate.giza], equals(1));
      expect(stats.governorateBreakdown[Governorate.alexandria], equals(1));
      expect(stats.governorateBreakdown[Governorate.cairo], isNull);
    });

    test('6. Date filters in EmployeeDetailsCubit dynamically update trip statistics', () async {
      final now = DateTime.now();
      final mockRepo = MockExpenseRepository();
      final mockProfile = MockProfileRepository();
      final mockSettings = MockSettingsRepository();

      mockRepo.mockExpenses = [
        Expense(
          id: 'today-1',
          userId: 'user-1',
          amount: 200,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: now,
        ),
        Expense(
          id: 'last-month-1',
          userId: 'user-1',
          amount: 300,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.alexandria,
          paymentMethod: 'cash',
          expenseDate: now.subtract(const Duration(days: 45)),
        ),
      ];

      final cubit = EmployeeDetailsCubit(
        expenseRepository: mockRepo,
        profileRepository: mockProfile,
        settingsRepository: mockSettings,
      );

      await cubit.loadEmployeeDetails('user-1');
      var state = cubit.state as EmployeeDetailsLoaded;
      expect(state.travelStats.totalTrips, equals(2));
      expect(state.travelStats.outsideCairoTrips, equals(2));

      // Filter by today only
      cubit.filterByDateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day));
      state = cubit.state as EmployeeDetailsLoaded;
      expect(state.travelStats.totalTrips, equals(1));
      expect(state.travelStats.outsideCairoTrips, equals(1));
      expect(state.travelStats.governorateBreakdown[Governorate.fayoum], equals(1));
      expect(state.travelStats.governorateBreakdown[Governorate.alexandria], isNull);
    });

    test('7. Offline persistence preserves trip_location_type and governorate in local store', () async {
      final offlineExpense = ExpenseModel(
        id: 'local-trip-1',
        userId: 'user-1',
        amount: 350.0,
        currency: ExpenseCurrency.egp,
        tripLocationType: TripLocationType.outsideCairo,
        governorate: Governorate.fayoum,
        paymentMethod: 'cash',
        expenseDate: DateTime(2026, 8, 18),
        syncStatus: SyncStatus.pending,
      );

      await localDataSource.saveExpense(offlineExpense);

      final retrieved = await localDataSource.getExpenseById('local-trip-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.tripLocationType, equals(TripLocationType.outsideCairo));
      expect(retrieved.governorate, equals(Governorate.fayoum));
      expect(retrieved.syncStatus, equals(SyncStatus.pending));
    });

    test('8. Sync status update preserves trip location details intact', () async {
      final offlineExpense = ExpenseModel(
        id: 'sync-trip-1',
        userId: 'user-1',
        amount: 450.0,
        currency: ExpenseCurrency.usd,
        tripLocationType: TripLocationType.outsideCairo,
        governorate: Governorate.redSea,
        paymentMethod: 'card',
        expenseDate: DateTime(2026, 8, 18),
        syncStatus: SyncStatus.pending,
      );

      await localDataSource.saveExpense(offlineExpense);
      await localDataSource.updateSyncStatus('sync-trip-1', SyncStatus.synced);

      final retrieved = await localDataSource.getExpenseById('sync-trip-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.syncStatus, equals(SyncStatus.synced));
      expect(retrieved.currency, equals(ExpenseCurrency.usd));
      expect(retrieved.tripLocationType, equals(TripLocationType.outsideCairo));
      expect(retrieved.governorate, equals(Governorate.redSea));
    });

    test('9. Travel bonus calculates potential bonus correctly from outside-Cairo trips', () {
      final expenses = [
        Expense(
          id: '1',
          userId: 'user-1',
          amount: 100,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.fayoum,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '2',
          userId: 'user-1',
          amount: 200,
          tripLocationType: TripLocationType.outsideCairo,
          governorate: Governorate.giza,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
        Expense(
          id: '3',
          userId: 'user-1',
          amount: 150,
          tripLocationType: TripLocationType.cairo,
          governorate: Governorate.cairo,
          paymentMethod: 'cash',
          expenseDate: DateTime.now(),
        ),
      ];

      final stats = EmployeeTravelStats.fromExpenses(expenses);
      expect(stats.outsideCairoTrips, equals(2));

      // When bonus is disabled
      const disabledSettings = TravelBonusSettings(enabled: false, bonusPerTrip: 150.0, currency: ExpenseCurrency.egp);
      expect(stats.calculatePotentialBonus(disabledSettings), equals(0.0));

      // When bonus is enabled
      const enabledSettings = TravelBonusSettings(enabled: true, bonusPerTrip: 150.0, currency: ExpenseCurrency.egp);
      expect(stats.calculatePotentialBonus(enabledSettings), equals(300.0));
    });

    test('10. Travel Bonus configuration is managed via AdminSettingsCubit', () async {
      final settingsRepo = MockSettingsRepository();
      final cubit = AdminSettingsCubit(settingsRepository: settingsRepo);

      await cubit.loadSettings();
      expect(cubit.state, isA<AdminSettingsLoaded>());

      await cubit.updateTravelBonusSettings(
        enabled: true,
        bonusPerTrip: 200.0,
        currency: ExpenseCurrency.egp,
      );

      final state = cubit.state as AdminSettingsLoaded;
      expect(state.travelBonusSettings.enabled, isTrue);
      expect(state.travelBonusSettings.bonusPerTrip, equals(200.0));
      expect(state.travelBonusSettings.currency, equals(ExpenseCurrency.egp));
    });
  });
}
