import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/payroll_summary.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/salary_payment.dart';

class PayrollPeriodBounds {
  const PayrollPeriodBounds({
    required this.start,
    required this.end,
    required this.totalDays,
    required this.nextPaymentDate,
  });

  final DateTime start;
  final DateTime end;
  final int totalDays;
  final DateTime nextPaymentDate;
}

abstract final class PayrollCalculator {
  /// Calculates exact period start and end dates for an employee based on their configured cycle.
  static PayrollPeriodBounds calculatePeriodBounds({
    required Profile profile,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cycleType = profile.salaryCycleType.toLowerCase();
    final startDay = profile.salaryCycleStartDay.clamp(1, 28); // Cap at 28 to safely cover February
    final cycleDays = profile.salaryCycleDays.clamp(1, 365);

    if (cycleType == 'custom_days') {
      // Custom length cycle anchored around start day of current or previous month
      final anchorStart = (today.day >= startDay)
          ? DateTime(today.year, today.month, startDay)
          : DateTime(today.year, today.month - 1, startDay);

      // Find current cycle interval [start, end]
      DateTime currentStart = anchorStart;
      while (currentStart.add(Duration(days: cycleDays)).isBefore(today) ||
          currentStart.add(Duration(days: cycleDays)).isAtSameMomentAs(today)) {
        currentStart = currentStart.add(Duration(days: cycleDays));
      }
      while (currentStart.isAfter(today)) {
        currentStart = currentStart.subtract(Duration(days: cycleDays));
      }

      final currentEnd = currentStart.add(Duration(days: cycleDays - 1));
      final totalDays = cycleDays;
      final nextPayment = currentEnd;

      return PayrollPeriodBounds(
        start: currentStart,
        end: currentEnd,
        totalDays: totalDays,
        nextPaymentDate: nextPayment,
      );
    }

    // Default: 'monthly' calendar-accurate cycle
    DateTime periodStart;
    DateTime periodEnd;

    if (startDay == 1) {
      periodStart = DateTime(today.year, today.month, 1);
      final lastDay = DateTime(today.year, today.month + 1, 0).day;
      periodEnd = DateTime(today.year, today.month, lastDay);
    } else {
      if (today.day >= startDay) {
        periodStart = DateTime(today.year, today.month, startDay);
        // Next month target day
        final nextMonthTarget = DateTime(today.year, today.month + 1, startDay);
        periodEnd = nextMonthTarget.subtract(const Duration(days: 1));
      } else {
        periodStart = DateTime(today.year, today.month - 1, startDay);
        final targetEnd = DateTime(today.year, today.month, startDay);
        periodEnd = targetEnd.subtract(const Duration(days: 1));
      }
    }

    final totalDays = DateTime.utc(periodEnd.year, periodEnd.month, periodEnd.day)
            .difference(DateTime.utc(periodStart.year, periodStart.month, periodStart.day))
            .inDays +
        1;
    final nextPayment = periodEnd;

    return PayrollPeriodBounds(
      start: periodStart,
      end: periodEnd,
      totalDays: totalDays,
      nextPaymentDate: nextPayment,
    );
  }

  /// Builds a complete [PayrollSummary] for an employee given their payment history.
  static PayrollSummary calculateSummary({
    required Profile profile,
    required List<SalaryPayment> allPayments,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bounds = calculatePeriodBounds(profile: profile, referenceDate: today);

    // Filter payments belonging to the current period and matching profile salary currency
    final periodPayments = allPayments.where((p) {
      final pDate = DateTime(p.paymentDate.year, p.paymentDate.month, p.paymentDate.day);
      final inDateRange = !pDate.isBefore(bounds.start) && !pDate.isAfter(bounds.end);
      final matchesCurrency = p.currency == profile.salaryCurrency;
      return inDateRange && matchesCurrency;
    }).toList();

    // Sort period payments newest first
    periodPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    // Calculate total paid in period
    double totalPaid = 0.0;
    for (final p in periodPayments) {
      totalPaid += p.amount;
    }

    final salary = profile.salaryAmount;
    final remaining = (salary - totalPaid).clamp(0.0, double.infinity);
    final overpaid = (totalPaid > salary) ? (totalPaid - salary) : 0.0;

    // Paid days and remaining days calculation (exact ratio * totalPeriodDays)
    double paidDays = 0.0;
    if (salary > 0) {
      paidDays = (totalPaid / salary * bounds.totalDays).clamp(0.0, bounds.totalDays.toDouble());
    } else if (totalPaid > 0) {
      paidDays = bounds.totalDays.toDouble();
    }
    final remainingDays = (bounds.totalDays - paidDays).clamp(0.0, bounds.totalDays.toDouble());

    // Countdown calculation (DST immune)
    final daysUntil = DateTime.utc(bounds.nextPaymentDate.year, bounds.nextPaymentDate.month, bounds.nextPaymentDate.day)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;

    // Determine status
    PayrollPaymentStatus status;
    if (overpaid > 0) {
      status = PayrollPaymentStatus.overpaid;
    } else if (salary > 0 && totalPaid >= salary) {
      status = PayrollPaymentStatus.paid;
    } else if (totalPaid > 0) {
      status = PayrollPaymentStatus.partiallyPaid;
    } else {
      status = PayrollPaymentStatus.unpaid;
    }

    // Last payment from all history matching currency
    SalaryPayment? lastPayment;
    final matchingAll = allPayments.where((p) => p.currency == profile.salaryCurrency).toList();
    if (matchingAll.isNotEmpty) {
      matchingAll.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      lastPayment = matchingAll.first;
    }

    return PayrollSummary(
      profile: profile,
      salaryPeriodStart: bounds.start,
      salaryPeriodEnd: bounds.end,
      totalPeriodDays: bounds.totalDays,
      salaryAmount: salary,
      salaryCurrency: profile.salaryCurrency,
      totalPaidInPeriod: totalPaid,
      remainingSalary: remaining,
      overpaidAmount: overpaid,
      paidDays: paidDays,
      remainingDays: remainingDays,
      nextExpectedPaymentDate: bounds.nextPaymentDate,
      daysUntilPayment: daysUntil,
      status: status,
      lastPaymentAmount: lastPayment?.amount,
      lastPaymentDate: lastPayment?.paymentDate,
      periodPayments: periodPayments,
    );
  }

  /// Calculates upcoming cash-flow obligations across active employees separated by currency.
  static Map<ExpenseCurrency, double> calculateUpcomingObligations({
    required List<PayrollSummary> summaries,
    int dueWithinDays = 5,
  }) {
    final result = <ExpenseCurrency, double>{
      ExpenseCurrency.egp: 0.0,
      ExpenseCurrency.usd: 0.0,
    };

    for (final summary in summaries) {
      if (summary.remainingSalary > 0 && summary.daysUntilPayment <= dueWithinDays) {
        final curr = summary.salaryCurrency;
        result[curr] = (result[curr] ?? 0.0) + summary.remainingSalary;
      }
    }

    return result;
  }

  /// Formats period start and end dates as a concise human-readable string.
  static String formatPeriod(DateTime start, DateTime end, bool isArabic) {
    final startStr = '${start.day}/${start.month}';
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr – $endStr';
  }
}
