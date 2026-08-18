import 'package:equatable/equatable.dart';
import 'expense.dart';
import 'governorate.dart';
import 'travel_bonus_settings.dart';
import 'trip_location_type.dart';

class EmployeeTravelStats extends Equatable {
  const EmployeeTravelStats({
    required this.totalTrips,
    required this.insideCairoTrips,
    required this.outsideCairoTrips,
    required this.governorateBreakdown,
  });

  final int totalTrips;
  final int insideCairoTrips;
  final int outsideCairoTrips;
  final Map<Governorate, int> governorateBreakdown;

  double calculatePotentialBonus(TravelBonusSettings settings) {
    if (!settings.enabled) return 0.0;
    return outsideCairoTrips * settings.bonusPerTrip;
  }

  factory EmployeeTravelStats.fromExpenses(List<Expense> expenses) {
    int total = expenses.length;
    int insideCairo = 0;
    int outsideCairo = 0;
    final Map<Governorate, int> breakdown = {};

    for (final exp in expenses) {
      if (exp.tripLocationType == TripLocationType.outsideCairo) {
        outsideCairo++;
        breakdown[exp.governorate] = (breakdown[exp.governorate] ?? 0) + 1;
      } else {
        insideCairo++;
      }
    }

    return EmployeeTravelStats(
      totalTrips: total,
      insideCairoTrips: insideCairo,
      outsideCairoTrips: outsideCairo,
      governorateBreakdown: breakdown,
    );
  }

  @override
  List<Object?> get props => [
        totalTrips,
        insideCairoTrips,
        outsideCairoTrips,
        governorateBreakdown,
      ];
}
