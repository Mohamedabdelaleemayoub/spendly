import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../cubits/balance/employee_balance_cubit.dart';
import '../../cubits/balance/employee_balance_state.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/dashboard/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DashboardCubit>()..loadDashboard()),
        BlocProvider(create: (context) => sl<EmployeeBalanceCubit>()..loadBalance()),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return AppColors.primary;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  String _getPeriodLabel(BuildContext context, ExpenseSummaryPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    switch (period) {
      case ExpenseSummaryPeriod.today:
        return l10n.periodToday;
      case ExpenseSummaryPeriod.week:
        return l10n.periodThisWeek;
      case ExpenseSummaryPeriod.month:
        return l10n.periodThisMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      symbol: Localizations.localeOf(context).languageCode == 'ar' ? 'ر.س ' : 'SAR ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: () {
              context.read<DashboardCubit>().loadDashboard();
              context.read<EmployeeBalanceCubit>().loadBalance();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.addExpense);
          if (context.mounted) {
            context.read<DashboardCubit>().loadDashboard();
            context.read<EmployeeBalanceCubit>().loadBalance();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            final isAdmin = state.isAdmin;
            final currentPeriod = state.period;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<DashboardCubit>().loadDashboard(),
                  context.read<EmployeeBalanceCubit>().loadBalance(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Employee Available Balance Card (For employees & users)
                  BlocBuilder<EmployeeBalanceCubit, EmployeeBalanceState>(
                    builder: (context, balanceState) {
                      if (balanceState is EmployeeBalanceLoaded) {
                        final summary = balanceState.summary;
                        final isZeroOrNegative = summary.availableBalance <= 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isZeroOrNegative
                                  ? [const Color(0xFF636E72), const Color(0xFF2D3436)]
                                  : [const Color(0xFF00B894), const Color(0xFF00897B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isZeroOrNegative ? Colors.grey : const Color(0xFF00B894))
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.availableBalance,
                                        style: AppTextStyles.subtitle2.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      summary.hasRemainingBalance ? l10n.statusActive : l10n.noAvailableBalance,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currencyFormat.format(summary.availableBalance),
                                style: AppTextStyles.amountLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.totalReceived,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(summary.totalReceived),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        l10n.totalSpent,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(summary.totalSpent),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // 2. Period Selector Controls (Compact & Beautiful)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SegmentedButton<ExpenseSummaryPeriod>(
                      segments: [
                        ButtonSegment(
                          value: ExpenseSummaryPeriod.today,
                          label: Text(
                            l10n.periodToday,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.today, size: 16),
                        ),
                        ButtonSegment(
                          value: ExpenseSummaryPeriod.week,
                          label: Text(
                            l10n.periodThisWeek,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.view_week_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ExpenseSummaryPeriod.month,
                          label: Text(
                            l10n.periodThisMonth,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        ),
                      ],
                      selected: {currentPeriod},
                      onSelectionChanged: (newSelection) {
                        context.read<DashboardCubit>().changePeriod(newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        selectedForegroundColor: AppColors.primary,
                      ),
                    ),
                  ),

                  // 3. Main Banner: Reactive Period Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAdmin
                            ? [const Color(0xFF1E293B), AppColors.primaryDark]
                            : [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      isAdmin
                                          ? '${l10n.companyTotalExpenses} (${_getPeriodLabel(context, currentPeriod)})'
                                          : '${l10n.employeeTotalExpenses} (${_getPeriodLabel(context, currentPeriod)})',
                                      style: AppTextStyles.subtitle2.copyWith(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.roleAdmin,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode)
                                    .format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currencyFormat.format(state.activePeriodTotal),
                          style: AppTextStyles.amountLarge.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Mini Stats Row (Today, Active Count, Active Employees)
                  Row(
                    children: [
                      // Today Spending Card
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.today,
                                        size: 18,
                                        color: AppColors.secondaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.periodToday,
                                        style: AppTextStyles.caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currencyFormat.format(state.totalToday),
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Count for Active Period Card
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.expensesCountLabel,
                                        style: AppTextStyles.caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${state.activePeriodCount}',
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // If Admin: Active Employees Card
                      if (isAdmin) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.people_alt_outlined,
                                          size: 18,
                                          color: Color(0xFF6C5CE7),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          l10n.navEmployees,
                                          style: AppTextStyles.caption,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${state.employeeCount}',
                                    style: AppTextStyles.subtitle1.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Admin Only: Spending By Employee Section
                  if (isAdmin && state.employeeSpending.isNotEmpty) ...[
                    Text(
                      l10n.distributionByEmployee,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: state.employeeSpending.map((emp) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                context.push('/employees/${emp.userId}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                                child: Text(
                                                  emp.name.isNotEmpty
                                                      ? emp.name.characters.first.toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  emp.name,
                                                  style: AppTextStyles.bodyMedium.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${emp.count})',
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${currencyFormat.format(emp.amount)} (${emp.percentage.toStringAsFixed(1)}%)',
                                              style: AppTextStyles.caption.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textHint),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: emp.percentage > 0 ? (emp.percentage / 100).clamp(0.0, 1.0) : 0.0,
                                        backgroundColor: AppColors.surfaceVariant,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Category Breakdown Section
                  if (state.categorySpending.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.distributionByCategory,
                          style: AppTextStyles.heading3,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.reports),
                          child: Text(l10n.viewReports),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: state.categorySpending.take(4).map((cat) {
                            final catColor = _parseColor(cat.color);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${currencyFormat.format(cat.amount)} (${cat.percentage.toStringAsFixed(1)}%)',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: cat.percentage > 0 ? (cat.percentage / 100).clamp(0.0, 1.0) : 0.0,
                                      backgroundColor: AppColors.surfaceVariant,
                                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 7. Recent Expenses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAdmin
                            ? '${l10n.recentExpenses} (${l10n.navEmployees})'
                            : l10n.recentExpenses,
                        style: AppTextStyles.heading3,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.expenses),
                        child: Text(l10n.viewAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.recentExpenses.isEmpty) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textHint),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noExpensesThisPeriod,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...state.recentExpenses.map((expense) {
                      final catColor = _parseColor(expense.category?.color);
                      final paymentLabel = AppConstants.paymentMethodLabels[expense.paymentMethod] ??
                          expense.paymentMethod;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () async {
                            await context.push('/expenses/${expense.id}');
                            if (context.mounted) {
                              context.read<DashboardCubit>().loadDashboard();
                              context.read<EmployeeBalanceCubit>().loadBalance();
                            }
                          },
                          leading: Container(
                            width: 10,
                            height: 40,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expense.displayTitle,
                                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAdmin && expense.profile != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 90),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    expense.profile!.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${dateFormat.format(expense.expenseDate)} • $paymentLabel',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            currencyFormat.format(expense.amount),
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
