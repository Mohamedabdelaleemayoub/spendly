import 'package:equatable/equatable.dart';

class WeeklyWorkBudgetSummary extends Equatable {
  const WeeklyWorkBudgetSummary({
    this.userId,
    required this.startDate,
    required this.endDate,
    this.receivedEgp = 0.0,
    this.spentEgp = 0.0,
    this.receivedUsd = 0.0,
    this.spentUsd = 0.0,
  });

  final String? userId;
  final DateTime startDate;
  final DateTime endDate;
  final double receivedEgp;
  final double spentEgp;
  final double receivedUsd;
  final double spentUsd;

  double get remainingEgp => receivedEgp - spentEgp;
  double get remainingUsd => receivedUsd - spentUsd;

  WeeklyWorkBudgetSummary copyWith({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    double? receivedEgp,
    double? spentEgp,
    double? receivedUsd,
    double? spentUsd,
  }) {
    return WeeklyWorkBudgetSummary(
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      receivedEgp: receivedEgp ?? this.receivedEgp,
      spentEgp: spentEgp ?? this.spentEgp,
      receivedUsd: receivedUsd ?? this.receivedUsd,
      spentUsd: spentUsd ?? this.spentUsd,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        startDate,
        endDate,
        receivedEgp,
        spentEgp,
        receivedUsd,
        spentUsd,
      ];
}
