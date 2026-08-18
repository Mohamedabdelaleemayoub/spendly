enum ExpenseCurrency {
  egp('EGP'),
  usd('USD');

  const ExpenseCurrency(this.code);

  final String code;

  static ExpenseCurrency fromString(String? val) {
    if (val == null) return ExpenseCurrency.egp;
    final normalized = val.trim().toUpperCase();
    for (final c in ExpenseCurrency.values) {
      if (c.code == normalized) return c;
    }
    return ExpenseCurrency.egp;
  }

  String toDbString() => code;

  String get symbol {
    switch (this) {
      case ExpenseCurrency.egp:
        return 'EGP';
      case ExpenseCurrency.usd:
        return '\$';
    }
  }

  String symbolForLocale(String languageCode) {
    switch (this) {
      case ExpenseCurrency.egp:
        return languageCode == 'ar' ? 'ج.م' : 'EGP';
      case ExpenseCurrency.usd:
        return languageCode == 'ar' ? '\$' : 'USD';
    }
  }

  String localizedName(String languageCode) {
    switch (this) {
      case ExpenseCurrency.egp:
        return languageCode == 'ar' ? 'جنيه مصري (EGP)' : 'Egyptian Pound (EGP)';
      case ExpenseCurrency.usd:
        return languageCode == 'ar' ? 'دولار أمريكي (USD)' : 'US Dollar (USD)';
    }
  }
}
