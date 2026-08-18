import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ', decimalDigits: 2);

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const SizedBox(height: 20),

                  if (state.totalAmount == 0) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.pie_chart_outline, size: 56, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              const Text('لا توجد بيانات لهذا الشهر', style: AppTextStyles.heading3),
                              const SizedBox(height: 4),
                              const Text('لم يتم تسجيل أي مصروفات خلال هذا الشهر', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Admin Only: Spending By Employee Section in Reports
                    if (isAdmin && state.employeeSpending.isNotEmpty) ...[
                      const Text('توزيع المصروفات حسب الموظفين', style: AppTextStyles.heading3),
                      const SizedBox(height: 10),
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
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor:
                                                      AppColors.primary.withValues(alpha: 0.15),
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
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(${emp.count} عملية)',
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${currencyFormat.format(emp.amount)} (${emp.percentage.toStringAsFixed(1)}%)',
                                                style: AppTextStyles.caption.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.chevron_left, size: 16, color: AppColors.textHint),
                                            ],
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
                      const SizedBox(height: 20),
                    ],

                    // Category Breakdown Pie Chart
                    const Text('توزيع المصروفات حسب الفئات', style: AppTextStyles.heading3),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
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
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: state.categorySpending.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final cat = entry.value;
                                    final isTouched = i == _touchedIndex;
                                    final radius = isTouched ? 55.0 : 45.0;

                                    return PieChartSectionData(
                                      color: _parseColor(cat.color),
                                      value: cat.amount,
                                      title: isTouched
                                          ? '${cat.percentage.toStringAsFixed(1)}%'
                                          : (cat.percentage > 5
                                              ? '${cat.percentage.toStringAsFixed(0)}%'
                                              : ''),
                                      radius: radius,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Category List
                            ...state.categorySpending.map((cat) {
                              final catColor = _parseColor(cat.color);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: catColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${currencyFormat.format(cat.amount)}  (${cat.percentage.toStringAsFixed(1)}%)',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
