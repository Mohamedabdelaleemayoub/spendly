enum TripLocationType {
  cairo,
  outsideCairo;

  String toDbString() {
    switch (this) {
      case TripLocationType.cairo:
        return 'cairo';
      case TripLocationType.outsideCairo:
        return 'outside_cairo';
    }
  }

  static TripLocationType fromString(String? value) {
    if (value == null) return TripLocationType.cairo;
    switch (value.trim().toLowerCase()) {
      case 'outside_cairo':
      case 'outsidecairo':
      case 'outside':
        return TripLocationType.outsideCairo;
      case 'cairo':
      default:
        return TripLocationType.cairo;
    }
  }

  String localizedName(String locale) {
    final isArabic = locale.toLowerCase().startsWith('ar');
    switch (this) {
      case TripLocationType.cairo:
        return isArabic ? 'داخل القاهرة' : 'Inside Cairo';
      case TripLocationType.outsideCairo:
        return isArabic ? 'خارج القاهرة' : 'Outside Cairo';
    }
  }
}
