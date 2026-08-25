import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../injection/injection_container.dart';
import '../../cubits/report/report_cubit.dart';
import '../../cubits/report/report_state.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReportCubit>()..loadReport(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  int _touchedIndex = -1;

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReportCubit>().loadReport(),
          ),
        ],
      ),
      body: BlocConsumer<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportLoaded) {
            final currencyFormat = NumberFormat.currency(
              symbol: '${state.selectedCurrency.symbol} ',
              decimalDigits: 2,
            );
            final monthFormat = DateFormat('MMMM yyyy', 'ar');
            final daysInMonth = DateTime(
              state.selectedMonth.year,
              state.selectedMonth.month + 1,
              0,
            ).day;
            final dailyAverage = state.totalAmount > 0 ? state.totalAmount / daysInMonth : 0.0;
            final isAdmin = state.isAdmin;

            return RefreshIndicator(
              onRefresh: () => context.read<ReportCubit>().loadReport(state.selectedMonth),
              child: ResponsiveContentContainer(
                maxWidth: Breakpoints.maxContentWidth,
                child: ListView(
                  padding: Responsive.pagePadding(context),
                  children: [
                  // Month Selector Banner
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => context.read<ReportCubit>().previousMonth(),
                            tooltip: 'الشهر السابق',
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                monthFormat.format(state.selectedMonth),
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => context.read<ReportCubit>().nextMonth(),
                            tooltip: 'الشهر التالي',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Currency Selector Toggle
                  SegmentedButton<ExpenseCurrency>(
                    segments: const [
                      ButtonSegment(
                        value: ExpenseCurrency.egp,
                        label: Text('جنيه مصري (EGP)'),
                        icon: Icon(Icons.money),
                      ),
                      ButtonSegment(
                        value: ExpenseCurrency.usd,
                        label: Text('دولار أمريكي (USD)'),
                        icon: Icon(Icons.attach_money),
                      ),
                    ],
                    selected: {state.selectedCurrency},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        context.read<ReportCubit>().changeCurrency(set.first);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Summary Cards Row
                  Row(
                    children: [
                      // Total Spent
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: isAdmin ? const Color(0xFF1E293B) : AppColors.primary,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdmin ? 'إجمالي مصروفات الشركة' : 'إجمالي المصروفات',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(state.totalAmount),
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Daily Average
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المعدل اليومي', style: AppTextStyles.caption),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(dailyAverage),
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (state.totalCount == 0) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مصروفات مسجلة لهذا الشهر بالعملة المختارة',
                              style: AppTextStyles.subtitle1.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Daily Spending Chart (Bar Chart)
                    const Text('المصروفات اليومية', style: AppTextStyles.heading3),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: state.dailySpending.map((e) => e.amount).fold<double>(0, (prev, el) => el > prev ? el : prev) * 1.2 + 10,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'يوم ${group.x}\n${currencyFormat.format(rod.toY)}',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final day = value.toInt();
                                          if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text('$day', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  barGroups: state.dailySpending.map((d) {
                                    return BarChartGroupData(
                                      x: d.day,
                                      barRods: [
                                        BarChartRodData(
                                          toY: d.amount,
                                          color: AppColors.primary,
                                          width: 6,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Breakdown (Pie Chart)
                    const Text('توزيع المصروفات حسب الفئة', style: AppTextStyles.heading3),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (state.categorySpending.isNotEmpty) ...[
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: List.generate(state.categorySpending.length, (i) {
                                      final isTouched = i == _touchedIndex;
                                      final cat = state.categorySpending[i];
                                      final color = _parseColor(cat.color);
                                      final radius = isTouched ? 60.0 : 50.0;
                                      return PieChartSectionData(
                                        color: color,
                                        value: cat.amount,
                                        title: '${cat.percentage.toStringAsFixed(0)}%',
                                        radius: radius,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...state.categorySpending.map((cat) {
                                final color = _parseColor(cat.color);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(cat.amount),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${cat.percentage.toStringAsFixed(1)}%)',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Employee Breakdown (For Admin)
                    if (isAdmin && state.employeeSpending.isNotEmpty) ...[
                      const Text('توزيع المصروفات حسب الموظف', style: AppTextStyles.heading3),
                      const SizedBox(height: 10),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: state.employeeSpending.map((emp) {
                              final amount = state.selectedCurrency == ExpenseCurrency.usd
                                  ? emp.amountUsd
                                  : emp.amountEgp;
                              return InkWell(
                                onTap: () => context.push('/employees/${emp.userId}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              emp.name,
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${currencyFormat.format(amount)} (${emp.percentage.toStringAsFixed(1)}%)',
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
                                          value: emp.percentage / 100,
                                          backgroundColor: AppColors.surfaceVariant,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
                                          minHeight: 8,
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
                      const SizedBox(height: 24),
                    ],

                    // Payment Method Breakdown
                    const Text('توزيع حسب طريقة الدفع', style: AppTextStyles.heading3),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: state.paymentMethodSpending.map((pay) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pay.label,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${currencyFormat.format(pay.amount)} (${pay.percentage.toStringAsFixed(1)}%)',
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
                                      value: pay.percentage / 100,
                                      backgroundColor: AppColors.surfaceVariant,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.secondary,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }

          if (state is ReportError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_problem, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<ReportCubit>().loadReport(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
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
}
