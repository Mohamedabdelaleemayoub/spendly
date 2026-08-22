import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/expense_currency.dart';
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
        BlocProvider<DashboardCubit>(
          create: (context) => sl<DashboardCubit>()..loadDashboard(),
        ),
        BlocProvider<EmployeeBalanceCubit>(
          create: (context) => sl<EmployeeBalanceCubit>()..loadBalance(),
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
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

  String _formatAmount(double amount, ExpenseCurrency currency, bool isArabic) {
    final symbol = currency.symbolForLocale(isArabic ? 'ar' : 'en');
    return '${amount.toStringAsFixed(2)} $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
            final selectedCurrency = state.selectedCurrency;

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<DashboardCubit>().loadDashboard(),
                  context.read<EmployeeBalanceCubit>().loadBalance(),
                ]);
              },
              child: ResponsiveContentContainer(
                maxWidth: Breakpoints.maxContentWidth,
                child: ListView(
                  padding: Responsive.pagePadding(context),
                  children: [
                  // 1. Dual Available Balance Card (EGP & USD)
                  BlocBuilder<EmployeeBalanceCubit, EmployeeBalanceState>(
                    builder: (context, balanceState) {
                      if (balanceState is EmployeeBalanceLoaded) {
                        final summary = balanceState.summary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B894), Color(0xFF00897B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00B894).withValues(alpha: 0.3),
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
                              const SizedBox(height: 14),

                              // Side-by-side EGP & USD Available Balances
                              Row(
                                children: [
                                  // EGP Balance
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'EGP (جنيه مصري)',
                                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatAmount(summary.availableBalanceEgp, ExpenseCurrency.egp, isArabic),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${l10n.totalReceived}: ${_formatAmount(summary.totalReceivedEgp, ExpenseCurrency.egp, isArabic)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // USD Balance
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'USD (دولار أمريكي)',
                                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatAmount(summary.availableBalanceUsd, ExpenseCurrency.usd, isArabic),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${l10n.totalReceived}: ${_formatAmount(summary.totalReceivedUsd, ExpenseCurrency.usd, isArabic)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
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

                  // 2. Period Selector Controls
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

                  // 3. Main Banner: Dual Multi-Currency Period Totals (Never Mixed)
                  Container(
                    padding: const EdgeInsets.all(18),
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
                            Text(
                              isAdmin
                                  ? '${l10n.companyTotalExpenses} (${_getPeriodLabel(context, currentPeriod)})'
                                  : '${l10n.employeeTotalExpenses} (${_getPeriodLabel(context, currentPeriod)})',
                              style: AppTextStyles.subtitle2.copyWith(
                                color: Colors.white70,
                                fontSize: 13,
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

                        // Two distinct currency totals
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('EGP', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatAmount(state.activePeriodTotalEgp, ExpenseCurrency.egp, isArabic),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('USD', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatAmount(state.activePeriodTotalUsd, ExpenseCurrency.usd, isArabic),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Mini Stats Row (Count, Active Employees)
                  Row(
                    children: [
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

                  // Currency breakdown switch (EGP / USD)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.distributionByCategory,
                          style: AppTextStyles.heading3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SegmentedButton<ExpenseCurrency>(
                        segments: const [
                          ButtonSegment(value: ExpenseCurrency.egp, label: Text('EGP')),
                          ButtonSegment(value: ExpenseCurrency.usd, label: Text('USD')),
                        ],
                        selected: {selectedCurrency},
                        onSelectionChanged: (set) {
                          context.read<DashboardCubit>().changeCurrency(set.first);
                        },
                        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 5. Category Breakdown Section
                  if (state.categorySpending.isNotEmpty) ...[
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
                                        '${_formatAmount(cat.amount, selectedCurrency, isArabic)} (${cat.percentage.toStringAsFixed(1)}%)',
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
                  ] else ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            '${l10n.noExpensesFound} (${selectedCurrency.code})',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Admin Only: Spending By Employee Section
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
                            final empAmt = selectedCurrency == ExpenseCurrency.usd ? emp.amountUsd : emp.amountEgp;
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
                                              '${_formatAmount(empAmt, selectedCurrency, isArabic)} (${emp.percentage.toStringAsFixed(1)}%)',
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

                  // 7. Travel Activity Section (Inside / Outside Cairo Trips & Top Traveler)
                  if (state.outsideCairoTripsCount > 0 || state.insideCairoTripsCount > 0) ...[
                    Row(
                      children: [
                        const Icon(Icons.commute, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.travelActivity,
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTravelCountTile(
                                    label: l10n.insideCairoTrips,
                                    count: state.insideCairoTripsCount,
                                    color: const Color(0xFF0984E3),
                                    icon: Icons.location_city,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTravelCountTile(
                                    label: l10n.outsideCairoTrips,
                                    count: state.outsideCairoTripsCount,
                                    color: const Color(0xFFE17055),
                                    icon: Icons.flight_takeoff,
                                  ),
                                ),
                              ],
                            ),
                            if (state.topTravelerName != null && state.topTravelerOutsideTrips > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: AppColors.secondaryDark),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${l10n.topTraveler}: ${state.topTravelerName}',
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${state.topTravelerOutsideTrips} ${l10n.tripsCountUnit}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 8. Salaries & Advances Overview (Admin Only)
                  if (state.isAdmin && (state.totalSalariesEgp > 0 || state.totalSalaryAdvancesEgp > 0)) ...[
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: Color(0xFF6C5CE7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.salariesOverview,
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.totalSalaries, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(state.totalSalariesEgp, ExpenseCurrency.egp, isArabic),
                                    style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF6C5CE7)),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: AppColors.divider),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.totalAdvances, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatAmount(state.totalSalaryAdvancesEgp, ExpenseCurrency.egp, isArabic),
                                      style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFE17055)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 36, color: AppColors.divider),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(l10n.totalRemainingSalaries, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(state.totalRemainingSalariesEgp, ExpenseCurrency.egp, isArabic),
                                    style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00B894)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // 9. Weekly Work Budget Overview Section (This Week - Admin only)
                  if (isAdmin) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range, size: 18, color: Color(0xFF0984E3)),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.weeklyWorkBudget} (${l10n.thisWeek})',
                                style: AppTextStyles.heading3,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // EGP Row
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('EGP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(l10n.totalReceivedWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatAmount(state.weeklyReceivedEgp, ExpenseCurrency.egp, isArabic),
                                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(l10n.totalSpentWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatAmount(state.weeklySpentEgp, ExpenseCurrency.egp, isArabic),
                                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.error),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(l10n.totalRemainingWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatAmount(state.weeklyRemainingEgp, ExpenseCurrency.egp, isArabic),
                                              style: AppTextStyles.caption.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: state.weeklyRemainingEgp >= 0 ? const Color(0xFF00B894) : AppColors.error,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (state.weeklyReceivedUsd > 0 || state.weeklySpentUsd > 0) ...[
                                const Divider(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('USD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryDark)),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(l10n.totalReceivedWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatAmount(state.weeklyReceivedUsd, ExpenseCurrency.usd, isArabic),
                                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(l10n.totalSpentWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatAmount(state.weeklySpentUsd, ExpenseCurrency.usd, isArabic),
                                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.error),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(l10n.totalRemainingWeekly, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatAmount(state.weeklyRemainingUsd, ExpenseCurrency.usd, isArabic),
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: state.weeklyRemainingUsd >= 0 ? const Color(0xFF00B894) : AppColors.error,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 10. Recent Expenses Section
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isAdmin
                              ? '${l10n.recentExpenses} (${l10n.navEmployees})'
                              : l10n.recentExpenses,
                          style: AppTextStyles.heading3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                            '${dateFormat.format(expense.expenseDate)} • $paymentLabel • ${expense.currency.code}',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatAmount(expense.amount, expense.currency, isArabic),
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
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTravelCountTile({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

