enum Governorate {
  cairo,
  giza,
  alexandria,
  fayoum,
  dakahlia,
  sharqia,
  gharbia,
  qalyubia,
  monufia,
  beheira,
  kafrElSheikh,
  damietta,
  portSaid,
  ismailia,
  suez,
  northSinai,
  southSinai,
  beniSuef,
  minya,
  assiut,
  sohag,
  qena,
  luxor,
  aswan,
  redSea,
  newValley,
  matrouh;

  String toDbString() {
    switch (this) {
      case Governorate.cairo:
        return 'cairo';
      case Governorate.giza:
        return 'giza';
      case Governorate.alexandria:
        return 'alexandria';
      case Governorate.fayoum:
        return 'fayoum';
      case Governorate.dakahlia:
        return 'dakahlia';
      case Governorate.sharqia:
        return 'sharqia';
      case Governorate.gharbia:
        return 'gharbia';
      case Governorate.qalyubia:
        return 'qalyubia';
      case Governorate.monufia:
        return 'monufia';
      case Governorate.beheira:
        return 'beheira';
      case Governorate.kafrElSheikh:
        return 'kafr_el_sheikh';
      case Governorate.damietta:
        return 'damietta';
      case Governorate.portSaid:
        return 'port_said';
      case Governorate.ismailia:
        return 'ismailia';
      case Governorate.suez:
        return 'suez';
      case Governorate.northSinai:
        return 'north_sinai';
      case Governorate.southSinai:
        return 'south_sinai';
      case Governorate.beniSuef:
        return 'beni_suef';
      case Governorate.minya:
        return 'minya';
      case Governorate.assiut:
        return 'assiut';
      case Governorate.sohag:
        return 'sohag';
      case Governorate.qena:
        return 'qena';
      case Governorate.luxor:
        return 'luxor';
      case Governorate.aswan:
        return 'aswan';
      case Governorate.redSea:
        return 'red_sea';
      case Governorate.newValley:
        return 'new_valley';
      case Governorate.matrouh:
        return 'matrouh';
    }
  }

  static Governorate fromString(String? value) {
    if (value == null) return Governorate.cairo;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    for (final gov in Governorate.values) {
      if (gov.toDbString() == normalized || gov.name.toLowerCase() == normalized) {
        return gov;
      }
    }
    return Governorate.cairo;
  }

  String localizedName(String locale) {
    final isArabic = locale.toLowerCase().startsWith('ar');
    switch (this) {
      case Governorate.cairo:
        return isArabic ? 'القاهرة' : 'Cairo';
      case Governorate.giza:
        return isArabic ? 'الجيزة' : 'Giza';
      case Governorate.alexandria:
        return isArabic ? 'الإسكندرية' : 'Alexandria';
      case Governorate.fayoum:
        return isArabic ? 'الفيوم' : 'Fayoum';
      case Governorate.dakahlia:
        return isArabic ? 'الدقهلية' : 'Dakahlia';
      case Governorate.sharqia:
        return isArabic ? 'الشرقية' : 'Sharqia';
      case Governorate.gharbia:
        return isArabic ? 'الغربية' : 'Gharbia';
      case Governorate.qalyubia:
        return isArabic ? 'القليوبية' : 'Qalyubia';
      case Governorate.monufia:
        return isArabic ? 'المنوفية' : 'Monufia';
      case Governorate.beheira:
        return isArabic ? 'البحيرة' : 'Beheira';
      case Governorate.kafrElSheikh:
        return isArabic ? 'كفر الشيخ' : 'Kafr El Sheikh';
      case Governorate.damietta:
        return isArabic ? 'دمياط' : 'Damietta';
      case Governorate.portSaid:
        return isArabic ? 'بورسعيد' : 'Port Said';
      case Governorate.ismailia:
        return isArabic ? 'الإسماعيلية' : 'Ismailia';
      case Governorate.suez:
        return isArabic ? 'السويس' : 'Suez';
      case Governorate.northSinai:
        return isArabic ? 'شمال سيناء' : 'North Sinai';
      case Governorate.southSinai:
        return isArabic ? 'جنوب سيناء' : 'South Sinai';
      case Governorate.beniSuef:
        return isArabic ? 'بني سويف' : 'Beni Suef';
      case Governorate.minya:
        return isArabic ? 'المنيا' : 'Minya';
      case Governorate.assiut:
        return isArabic ? 'أسيوط' : 'Assiut';
      case Governorate.sohag:
        return isArabic ? 'سوهاج' : 'Sohag';
      case Governorate.qena:
        return isArabic ? 'قنا' : 'Qena';
      case Governorate.luxor:
        return isArabic ? 'الأقصر' : 'Luxor';
      case Governorate.aswan:
        return isArabic ? 'أسوان' : 'Aswan';
      case Governorate.redSea:
        return isArabic ? 'البحر الأحمر' : 'Red Sea';
      case Governorate.newValley:
        return isArabic ? 'الوادي الجديد' : 'New Valley';
      case Governorate.matrouh:
        return isArabic ? 'مطروح' : 'Matrouh';
    }
  }

  static List<Governorate> get outsideCairoGovernorates =>
      Governorate.values.where((g) => g != Governorate.cairo).toList();
}
