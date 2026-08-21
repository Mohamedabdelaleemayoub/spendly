import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/services/supabase_service.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/profile.dart';
import '../injection/injection_container.dart';
import '../presentation/cubits/auth/auth_cubit.dart';
import '../presentation/cubits/auth/auth_state.dart';
import '../presentation/pages/audit/audit_logs_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/pending_approval_page.dart';
import '../presentation/pages/auth/rejected_account_page.dart';
import '../presentation/pages/auth/signup_page.dart';
import '../presentation/pages/categories/categories_page.dart';
import '../presentation/pages/dashboard/dashboard_page.dart';
import '../presentation/pages/employees/employee_details_page.dart';
import '../presentation/pages/employees/employees_page.dart';
import '../presentation/pages/expenses/add_expense_page.dart';
import '../presentation/pages/expenses/expense_details_page.dart';
import '../presentation/pages/expenses/expenses_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';
import '../presentation/pages/profile/change_password_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/reports/reports_page.dart';
import '../presentation/pages/shell/app_shell.dart';
import '../presentation/pages/splash/splash_page.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const pendingApproval = '/pending-approval';
  static const rejectedAccount = '/account-rejected';
  static const dashboard = '/dashboard';
  static const expenses = '/expenses';
  static const addExpense = '/expenses/add';
  static const editExpense = '/expenses/edit';
  static const expenseDetails = '/expenses/:id';
  static const categories = '/categories';
  static const reports = '/reports';
  static const profile = '/profile';
  static const changePassword = '/change-password';
  static const employees = '/employees';
  static const auditLogs = '/audit-logs';
}

/// Helper class to combine multiple broadcast streams into a Listenable for GoRouter.
class _MultiStreamListenable extends ChangeNotifier {
  _MultiStreamListenable(List<Stream<dynamic>> streams) {
    for (final stream in streams) {
      _subscriptions.add(
        stream.listen((_) {
          if (!_disposed) {
            notifyListeners();
          }
        }),
      );
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// Global [GoRouter] configuration for the app.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: kDebugMode,
  refreshListenable: _MultiStreamListenable([
    SupabaseService.client.auth.onAuthStateChange,
    sl<AuthCubit>().stream,
  ]),
  redirect: (context, state) {
    final session = SupabaseService.client.auth.currentSession;
    final isLoggedIn = session != null;
    final location = state.matchedLocation;
    final authState = sl<AuthCubit>().state;

    // Don't redirect on splash or onboarding
    if (location == AppRoutes.splash || location == AppRoutes.onboarding) {
      return null;
    }

    final isAuthRoute = location == AppRoutes.login || location == AppRoutes.signup;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

    // ── Pending Approval & Rejected Account Route Guards ──────────────────
    if (authState is AuthPendingApproval) {
      if (location != AppRoutes.pendingApproval) {
        return AppRoutes.pendingApproval;
      }
      return null;
    }

    if (authState is AuthRejected) {
      if (location != AppRoutes.rejectedAccount) {
        return AppRoutes.rejectedAccount;
      }
      return null;
    }

    if (isLoggedIn && (isAuthRoute || location == AppRoutes.pendingApproval || location == AppRoutes.rejectedAccount)) {
      if (authState is Authenticated) {
        return AppRoutes.dashboard;
      }
    }

    // ── Role Authorization Guard ──────────────────────────────────────
    if (location.startsWith(AppRoutes.employees) || location.startsWith(AppRoutes.auditLogs)) {
      if (authState is Authenticated) {
        if (!authState.isAdmin) {
          // Employee attempted to access Admin-only pages -> redirect to dashboard
          return AppRoutes.dashboard;
        }
      }
    }

    return null;
  },
  routes: [
    // ── Splash ────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),

    // ── Onboarding ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),

    // ── Login & SignUp (no shell) ─────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignUpPage(),
    ),

    // ── Pending Approval & Rejected Account Pages ─────────────────────
    GoRoute(
      path: AppRoutes.pendingApproval,
      builder: (context, state) => const PendingApprovalPage(),
    ),
    GoRoute(
      path: AppRoutes.rejectedAccount,
      builder: (context, state) => const RejectedAccountPage(),
    ),

    // ── Change Password (authenticated) ──────────────────────────────
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordPage(),
    ),

    // ── Audit Logs (authenticated Admin) ─────────────────────────────
    GoRoute(
      path: AppRoutes.auditLogs,
      builder: (context, state) => const AuditLogsPage(),
    ),

    // ── Main shell with bottom nav ────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ExpensesPage(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddExpensePage(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final expense = state.extra;
                return AddExpensePage(
                  initialExpense: expense is Expense ? expense : null,
                );
              },
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final expenseId = state.pathParameters['id'] ?? '';
                return ExpenseDetailsPage(
                  expenseId: expenseId,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.categories,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CategoriesPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reports,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportsPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.employees,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EmployeesPage(),
          ),
          routes: [
            GoRoute(
              path: ':employeeId',
              builder: (context, state) {
                final employeeId = state.pathParameters['employeeId'] ?? '';
                final profile = state.extra is Profile ? state.extra as Profile : null;
                return EmployeeDetailsPage(
                  employeeId: employeeId,
                  initialProfile: profile,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);
