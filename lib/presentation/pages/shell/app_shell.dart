import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../widgets/common/sync_status_indicator.dart';

class _TabDestination {
  const _TabDestination({
    required this.route,
    required this.labelBuilder,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String Function(AppLocalizations l10n) labelBuilder;
  final IconData icon;
  final IconData selectedIcon;
}

/// Role-aware bottom navigation shell that wraps authenticated pages.
///
/// Automatically adjusts navigation tabs based on user role (Admin vs Employee)
/// and updates dynamically with the active locale.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const List<_TabDestination> _employeeTabs = [
    _TabDestination(
      route: AppRoutes.dashboard,
      labelBuilder: _getNavDashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _TabDestination(
      route: AppRoutes.expenses,
      labelBuilder: _getNavExpenses,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _TabDestination(
      route: AppRoutes.reports,
      labelBuilder: _getNavReports,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _TabDestination(
      route: AppRoutes.categories,
      labelBuilder: _getNavCategories,
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
    ),
    _TabDestination(
      route: AppRoutes.profile,
      labelBuilder: _getNavProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  static const List<_TabDestination> _adminTabs = [
    _TabDestination(
      route: AppRoutes.dashboard,
      labelBuilder: _getNavDashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _TabDestination(
      route: AppRoutes.expenses,
      labelBuilder: _getNavAllExpenses,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _TabDestination(
      route: AppRoutes.reports,
      labelBuilder: _getNavReports,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _TabDestination(
      route: AppRoutes.employees,
      labelBuilder: _getNavEmployees,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _TabDestination(
      route: AppRoutes.profile,
      labelBuilder: _getNavProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  static String _getNavDashboard(AppLocalizations l) => l.navDashboard;
  static String _getNavExpenses(AppLocalizations l) => l.navExpenses;
  static String _getNavAllExpenses(AppLocalizations l) => l.navAllExpenses;
  static String _getNavReports(AppLocalizations l) => l.navReports;
  static String _getNavCategories(AppLocalizations l) => l.navCategories;
  static String _getNavEmployees(AppLocalizations l) => l.navEmployees;
  static String _getNavProfile(AppLocalizations l) => l.navProfile;

  int _currentIndex(BuildContext context, List<_TabDestination> tabs) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < tabs.length; i++) {
      if (location == tabs[i].route ||
          (tabs[i].route != AppRoutes.dashboard && location.startsWith(tabs[i].route))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final bool isAdmin = (authState is Authenticated) && authState.isAdmin;
          final tabs = isAdmin ? _adminTabs : _employeeTabs;
          final index = _currentIndex(context, tabs);

          return Scaffold(
            body: Column(
              children: [
                const SyncStatusIndicator(),
                Expanded(child: child),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(tabs[i].route),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              destinations: tabs
                  .map(
                    (tab) => NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: tab.labelBuilder(l10n),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
