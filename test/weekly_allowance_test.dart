import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendly/domain/entities/expense_currency.dart';
import 'package:spendly/domain/entities/profile.dart';
import 'package:spendly/domain/repositories/auth_repository.dart';
import 'package:spendly/domain/repositories/profile_repository.dart';
import 'package:spendly/presentation/cubits/auth/auth_cubit.dart';
import 'package:spendly/presentation/cubits/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockProfileRepository mockProfileRepository;
  late StreamController<supa.AuthState> authStateController;

  setUpAll(() {
    registerFallbackValue(Profile(id: 'dummy', name: 'dummy'));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockProfileRepository = MockProfileRepository();
    authStateController = StreamController<supa.AuthState>.broadcast();

    when(() => mockAuthRepository.currentSession).thenReturn(null);
    when(() => mockAuthRepository.currentUser).thenReturn(null);
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);
  });

  tearDown(() {
    authStateController.close();
  });

  group('Admin Approval Workflow Tests', () {
    test('1. Pending user is held at AuthPendingApproval and blocked from app entry', () async {
      final user = supa.User(
        id: 'pending-user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final session = supa.Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: user,
      );

      final pendingProfile = Profile(
        id: 'pending-user-1',
        name: 'Pending Employee',
        email: 'pending@company.com',
        role: 'employee',
        status: 'pending',
        salaryAmount: 5000,
        salaryCurrency: ExpenseCurrency.egp,
      );

      when(() => mockProfileRepository.getProfile('pending-user-1'))
          .thenAnswer((_) async => pendingProfile);

      final cubit = AuthCubit(
        authRepository: mockAuthRepository,
        profileRepository: mockProfileRepository,
      );

      // Trigger session update
      authStateController.add(supa.AuthState(supa.AuthChangeEvent.signedIn, session));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state, isA<AuthPendingApproval>());
      final pendingState = cubit.state as AuthPendingApproval;
      expect(pendingState.profile.isPending, isTrue);
      expect(pendingState.profile.name, 'Pending Employee');
    });

    test('3. Inactive/Deactivated user is signed out with error message', () async {
      final user = supa.User(
        id: 'inactive-user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final session = supa.Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: user,
      );

      final inactiveProfile = Profile(
        id: 'inactive-user-1',
        name: 'Deactivated Employee',
        email: 'inactive@company.com',
        role: 'employee',
        status: 'inactive',
        salaryAmount: 5000,
        salaryCurrency: ExpenseCurrency.egp,
      );

      when(() => mockProfileRepository.getProfile('inactive-user-1'))
          .thenAnswer((_) async => inactiveProfile);
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

      final cubit = AuthCubit(
        authRepository: mockAuthRepository,
        profileRepository: mockProfileRepository,
      );

      authStateController.add(supa.AuthState(supa.AuthChangeEvent.signedIn, session));
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockAuthRepository.signOut()).called(1);
      expect(cubit.state, isA<AuthError>());
    });

    test('4. Approved active user transitions to Authenticated state normally', () async {
      final user = supa.User(
        id: 'active-user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final session = supa.Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: user,
      );

      final activeProfile = Profile(
        id: 'active-user-1',
        name: 'Active Employee',
        email: 'active@company.com',
        role: 'employee',
        status: 'active',
        salaryAmount: 8000,
        salaryCurrency: ExpenseCurrency.egp,
      );

      when(() => mockProfileRepository.getProfile('active-user-1'))
          .thenAnswer((_) async => activeProfile);

      final cubit = AuthCubit(
        authRepository: mockAuthRepository,
        profileRepository: mockProfileRepository,
      );

      authStateController.add(supa.AuthState(supa.AuthChangeEvent.signedIn, session));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state, isA<Authenticated>());
      final authState = cubit.state as Authenticated;
      expect(authState.profile?.isActive, isTrue);
      expect(authState.profile?.name, 'Active Employee');
    });
  });
}
