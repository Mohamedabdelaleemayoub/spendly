import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/services/uuid_generator.dart';
import 'package:spendly/data/datasources/local_expense_datasource.dart';
import 'package:spendly/data/models/expense_model.dart';
import 'package:spendly/domain/entities/admin_notification.dart';
import 'package:spendly/domain/entities/category.dart';
import 'package:spendly/domain/entities/employee_summary.dart';
import 'package:spendly/domain/entities/expense.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/repositories/auth_repository.dart';
import 'package:spendly/domain/repositories/notification_repository.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/domain/repositories/settings_repository.dart';
import 'package:spendly/presentation/cubits/auth/auth_cubit.dart';
import 'package:spendly/presentation/cubits/auth/auth_state.dart' as spendly_auth;
import 'package:spendly/presentation/cubits/notifications/admin_notification_cubit.dart';
import 'package:spendly/presentation/cubits/notifications/admin_notification_state.dart';
import 'package:spendly/presentation/cubits/settings/admin_settings_cubit.dart';
import 'package:spendly/presentation/cubits/settings/admin_settings_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockAuthRepository implements AuthRepository {
  supabase.User? mockUser;
  supabase.Session? mockSession;
  final _controller = StreamController<supabase.AuthState>.broadcast();

  @override
  supabase.User? get currentUser => mockUser;

  @override
  supabase.Session? get currentSession => mockSession;

  @override
  Stream<supabase.AuthState> get authStateChanges => _controller.stream;

  @override
  Future<supabase.AuthResponse> signInWithPassword({required String email, required String password}) async {
    return supabase.AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<supabase.AuthResponse> signUp({required String email, required String password, String? name}) async {
    return supabase.AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
    mockSession = null;
  }

  @override
  Future<supabase.UserResponse> updatePassword(String newPassword) async {
    return supabase.UserResponse.fromJson({});
  }
}

class MockSettingsRepository implements SettingsRepository {
  bool requireApproval = false;

  @override
  Future<bool> getRequireAdminApproval() async => requireApproval;

  @override
  Future<void> setRequireAdminApproval(bool enabled) async {
    requireApproval = enabled;
  }
}

class MockNotificationRepository implements NotificationRepository {
  List<AdminNotification> notifications = [];

  @override
  Future<List<AdminNotification>> getNotifications() async => notifications;

  @override
  Future<void> markAsRead(String id) async {
    notifications = notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
  }

  @override
  Future<void> markAllAsRead() async {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    return notifications.where((n) => !n.isRead).length;
  }
}

class MockFullProfileRepository implements ProfileRepository {
  Profile? returnedProfile;

  @override
  Future<Profile?> getProfile(String userId) async => returnedProfile;

  @override
  Future<Profile> ensureProfileExists({required String userId, required String name, String? email}) async {
    return returnedProfile ?? Profile(id: userId, name: name, email: email, status: 'active');
  }

  @override
  Future<Profile> updateProfile(Profile profile) async => profile;

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async => '';

  @override
  Future<void> deleteAvatar(String userId) async {}

  @override
  Future<List<Profile>> getEmployees() async => [];

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async => [];

  @override
  Future<Profile> createEmployee({required String email, required String password, required String fullName, String role = 'employee'}) async {
    return Profile(id: 'new_id', name: fullName, email: email, role: role);
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RFC 4122 v4 UUID Generator Tests', () {
    test('generate() produces valid RFC 4122 v4 UUID strings', () {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      for (int i = 0; i < 50; i++) {
        final uuid = UuidGenerator.generate();
        expect(uuid.length, 36);
        expect(uuidRegex.hasMatch(uuid), true, reason: 'Failed for UUID: $uuid');
      }
    });

    test('generate() produces distinct IDs across repeated calls', () {
      final ids = <String>{};
      for (int i = 0; i < 100; i++) {
        final id = UuidGenerator.generate();
        expect(ids.contains(id), false);
        ids.add(id);
      }
      expect(ids.length, 100);
    });
  });

  group('LocalExpenseDataSource & Offline Persistence Tests', () {
    late SharedPreferences prefs;
    late LocalExpenseDataSource localDataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = LocalExpenseDataSourceImpl(prefs: prefs);
    });

    test('saveExpense, getExpenses, getPendingExpenses, and updateSyncStatus', () async {
      final expense1 = ExpenseModel(
        id: 'uuid-1',
        userId: 'user-123',
        title: 'Lunch Meeting',
        amount: 85.50,
        paymentMethod: 'cash',
        expenseDate: DateTime(2026, 8, 18),
        syncStatus: SyncStatus.pending,
      );

      final expense2 = ExpenseModel(
        id: 'uuid-2',
        userId: 'user-123',
        title: '',
        amount: 200.0,
        paymentMethod: 'credit_card',
        expenseDate: DateTime(2026, 8, 17),
        syncStatus: SyncStatus.synced,
      );

      // Save expenses locally
      await localDataSource.saveExpense(expense1);
      await localDataSource.saveExpense(expense2);

      // Fetch all for user
      final all = await localDataSource.getExpenses(userId: 'user-123');
      expect(all.length, 2);

      // Fetch pending for user
      final pending = await localDataSource.getPendingExpenses(userId: 'user-123');
      expect(pending.length, 1);
      expect(pending.first.id, 'uuid-1');
      expect(pending.first.syncStatus, SyncStatus.pending);

      // Update sync status of pending item to synced
      await localDataSource.updateSyncStatus('uuid-1', SyncStatus.synced);
      final remainingPending = await localDataSource.getPendingExpenses(userId: 'user-123');
      expect(remainingPending.isEmpty, true);

      final updatedItem = await localDataSource.getExpenseById('uuid-1');
      expect(updatedItem?.syncStatus, SyncStatus.synced);
    });

    test('saveExpenses preserves existing pending items during cache refresh', () async {
      final pendingExpense = ExpenseModel(
        id: 'local-uuid-pending',
        userId: 'user-123',
        title: 'Local Offline Expense',
        amount: 45.0,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await localDataSource.saveExpense(pendingExpense);

      final serverExpense = ExpenseModel(
        id: 'server-uuid-1',
        userId: 'user-123',
        title: 'Server Synced Expense',
        amount: 120.0,
        paymentMethod: 'cash',
        expenseDate: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      // Cache refresh from server with preservePending: true
      await localDataSource.saveExpenses([serverExpense], preservePending: true);

      final all = await localDataSource.getExpenses(userId: 'user-123');
      expect(all.length, 2);
      expect(all.any((e) => e.id == 'local-uuid-pending'), true);
      expect(all.any((e) => e.id == 'server-uuid-1'), true);
    });
  });

  group('Expense Entity Display Title & Validation Logic Tests', () {
    test('displayTitle falls back gracefully when title is empty', () {
      final date = DateTime(2026, 8, 18);

      final expenseWithTitle = Expense(
        id: '1',
        userId: 'u1',
        title: 'Team Dinner',
        amount: 150.0,
        paymentMethod: 'cash',
        expenseDate: date,
      );
      expect(expenseWithTitle.displayTitle, 'Team Dinner');

      final expenseWithCategory = Expense(
        id: '2',
        userId: 'u1',
        title: '',
        category: const Category(id: 'c1', name: 'وقود ومواصلات', icon: 'local_gas_station', color: '#10B981'),
        amount: 50.0,
        paymentMethod: 'cash',
        expenseDate: date,
      );
      expect(expenseWithCategory.displayTitle, 'وقود ومواصلات');

      final expenseWithNotes = Expense(
        id: '3',
        userId: 'u1',
        title: '',
        notes: 'ملاحظة الفاتورة 1234',
        amount: 30.0,
        paymentMethod: 'cash',
        expenseDate: date,
      );
      expect(expenseWithNotes.displayTitle, 'ملاحظة الفاتورة 1234');

      final genericExpense = Expense(
        id: '4',
        userId: 'u1',
        title: '',
        amount: 10.0,
        paymentMethod: 'cash',
        expenseDate: date,
      );
      expect(genericExpense.displayTitle, 'مصروف');
    });
  });

  group('AdminSettingsCubit Tests', () {
    test('loadSettings and toggleRequireAdminApproval', () async {
      final repo = MockSettingsRepository();
      final cubit = AdminSettingsCubit(settingsRepository: repo);

      await cubit.loadSettings();
      expect(cubit.state, isA<AdminSettingsLoaded>());
      expect((cubit.state as AdminSettingsLoaded).requireAdminApproval, false);

      await cubit.toggleRequireAdminApproval(true);
      expect((cubit.state as AdminSettingsLoaded).requireAdminApproval, true);
      expect(repo.requireApproval, true);

      await cubit.toggleRequireAdminApproval(false);
      expect((cubit.state as AdminSettingsLoaded).requireAdminApproval, false);
      expect(repo.requireApproval, false);
    });
  });

  group('AdminNotificationCubit Tests', () {
    test('loadNotifications and markAsRead', () async {
      final repo = MockNotificationRepository();
      repo.notifications = [
        AdminNotification(
          id: 'notif-1',
          type: 'registration_request',
          title: 'طلب تسجيل جديد',
          message: 'يرغب محمد بالانضمام',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AdminNotification(
          id: 'notif-2',
          type: 'registration_request',
          title: 'طلب تسجيل جديد',
          message: 'يرغب أحمد بالانضمام',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      final cubit = AdminNotificationCubit(notificationRepository: repo);

      await cubit.loadNotifications();
      expect(cubit.state, isA<AdminNotificationLoaded>());
      final loaded = cubit.state as AdminNotificationLoaded;
      expect(loaded.notifications.length, 2);
      expect(loaded.unreadCount, 2);

      await cubit.markAsRead('notif-1');
      final updated = cubit.state as AdminNotificationLoaded;
      expect(updated.unreadCount, 1);

      await cubit.markAllAsRead();
      final allRead = cubit.state as AdminNotificationLoaded;
      expect(allRead.unreadCount, 0);
    });
  });

  group('AuthCubit Pending Approval and Rejected Account State Tests', () {
    test('AuthCubit transitions to AuthPendingApproval when user profile status is pending', () async {
      final authRepo = MockAuthRepository();
      final profileRepo = MockFullProfileRepository();

      const pendingProfile = Profile(
        id: 'user_pending_123',
        name: 'Pending User',
        email: 'pending@spendly.com',
        role: 'employee',
        status: 'pending',
      );
      profileRepo.returnedProfile = pendingProfile;

      final testUser = supabase.User(
        id: 'user_pending_123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-08-18T00:00:00.000Z',
      );
      authRepo.mockUser = testUser;
      authRepo.mockSession = supabase.Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: testUser,
      );

      final authCubit = AuthCubit(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      // Sign in
      await authCubit.signIn(email: 'pending@spendly.com', password: 'password123');

      expect(authCubit.state, isA<spendly_auth.AuthPendingApproval>());
      final state = authCubit.state as spendly_auth.AuthPendingApproval;
      expect(state.profile.isPending, true);
      expect(state.profile.name, 'Pending User');
    });

    test('AuthCubit transitions to AuthRejected when user profile status is rejected', () async {
      final authRepo = MockAuthRepository();
      final profileRepo = MockFullProfileRepository();

      const rejectedProfile = Profile(
        id: 'user_rejected_123',
        name: 'Rejected User',
        email: 'rejected@spendly.com',
        role: 'employee',
        status: 'rejected',
      );
      profileRepo.returnedProfile = rejectedProfile;

      final testUser = supabase.User(
        id: 'user_rejected_123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-08-18T00:00:00.000Z',
      );
      authRepo.mockUser = testUser;
      authRepo.mockSession = supabase.Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: testUser,
      );

      final authCubit = AuthCubit(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      await authCubit.signIn(email: 'rejected@spendly.com', password: 'password123');

      expect(authCubit.state, isA<spendly_auth.AuthRejected>());
      final state = authCubit.state as spendly_auth.AuthRejected;
      expect(state.profile.isRejected, true);
    });
  });
}
