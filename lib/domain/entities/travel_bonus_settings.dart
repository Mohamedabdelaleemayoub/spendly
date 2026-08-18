import 'package:equatable/equatable.dart';
import 'expense_currency.dart';

class TravelBonusSettings extends Equatable {
  const TravelBonusSettings({
    this.enabled = false,
    this.bonusPerTrip = 100.0,
    this.currency = ExpenseCurrency.egp,
  });

  final bool enabled;
  final double bonusPerTrip;
  final ExpenseCurrency currency;

  TravelBonusSettings copyWith({
    bool? enabled,
    double? bonusPerTrip,
    ExpenseCurrency? currency,
  }) {
    return TravelBonusSettings(
      enabled: enabled ?? this.enabled,
      bonusPerTrip: bonusPerTrip ?? this.bonusPerTrip,
      currency: currency ?? this.currency,
    );
  }

  factory TravelBonusSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TravelBonusSettings();
    return TravelBonusSettings(
      enabled: json['enabled'] as bool? ?? false,
      bonusPerTrip: (json['bonus_per_trip'] as num?)?.toDouble() ?? 100.0,
      currency: ExpenseCurrency.fromString(json['currency'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bonus_per_trip': bonusPerTrip,
      'currency': currency.toDbString(),
    };
  }

  @override
  List<Object?> get props => [enabled, bonusPerTrip, currency];
}
