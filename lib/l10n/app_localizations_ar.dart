// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Spendly';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navExpenses => 'مصروفاتي';

  @override
  String get navAllExpenses => 'كل المصروفات';

  @override
  String get navReports => 'التقارير';

  @override
  String get navCategories => 'الفئات';

  @override
  String get navEmployees => 'الموظفين';

  @override
  String get navProfile => 'الحساب';

  @override
  String get loginTitle => 'مرحباً بك مجدداً';

  @override
  String get loginSubtitle => 'سجل الدخول لمتابعة مصروفاتك وإدارتها بكل سهولة';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get signupTitle => 'انضم إلى Spendly';

  @override
  String get signupSubtitle => 'أنشئ حسابك لإدارة المصروفات ومتابعة الفواتير';

  @override
  String get signupButton => 'إنشاء الحساب';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get createAccountLink => 'إنشاء حساب جديد';

  @override
  String get signInLink => 'تسجيل الدخول';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@company.com';

  @override
  String get emailRequired => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordTooShort => 'كلمة المرور يجب ألا تقل عن 6 أحرف';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameHint => 'محمد علي';

  @override
  String get fullNameRequired => 'يرجى إدخال الاسم';

  @override
  String get roleAdmin => 'مدير النظام';

  @override
  String get roleEmployee => 'موظف';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get editNameTitle => 'تعديل الاسم';

  @override
  String get joinedDateLabel => 'تاريخ الانضمام';

  @override
  String get unspecified => 'غير محدد';

  @override
  String get userLoadFailed => 'تعذر تحميل بيانات المستخدم';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirmMessage =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟';

  @override
  String get settingsHeader => 'التفضيلات والأمان';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English (الإنجليزية)';

  @override
  String get selectLanguage => 'اختر لغة التطبيق';

  @override
  String get themeLabel => 'المظهر والوضع';

  @override
  String get themeLight => 'الوضع الفاتح (Light)';

  @override
  String get themeDark => 'الوضع الداكن (Dark)';

  @override
  String get themeSystem => 'تلقائي حسب النظام';

  @override
  String get selectTheme => 'اختر مظهر التطبيق';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordSubtitle => 'تحديث كلمة مرور حسابك بأمان';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get currentPasswordRequired => 'يرجى إدخال كلمة المرور الحالية';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get newPasswordRequired => 'يرجى إدخال كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordRequired => 'يرجى تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordMustBeDifferent =>
      'كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور الحالية';

  @override
  String get passwordChangeSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get changePasswordButton => 'تغيير كلمة المرور';

  @override
  String get changePasswordHeaderInfo =>
      'أدخل كلمة المرور الحالية ثم اختر كلمة مرور جديدة قوية تتكون من 6 أحرف على الأقل.';

  @override
  String get profileImageTitle => 'صورة الملف الشخصي';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get takePhoto => 'التقاط صورة بالكاميرا';

  @override
  String get removePhoto => 'حذف الصورة الحالية';

  @override
  String get photoUploadedSuccess => 'تم تحديث الصورة الشخصية بنجاح';

  @override
  String get photoRemovedSuccess => 'تم حذف الصورة الشخصية';

  @override
  String get photoUploadError => 'فشل رفع الصورة الشخصية';

  @override
  String get addExpenseTitle => 'إضافة مصروف جديد';

  @override
  String get editExpenseTitle => 'تعديل المصروف';

  @override
  String get expenseDetailsTitle => 'تفاصيل المصروف';

  @override
  String get deleteExpenseTitle => 'حذف المصروف';

  @override
  String get deleteExpenseConfirm => 'هل أنت متأكد من حذف هذا المصروف؟';

  @override
  String get expenseTitleLabel => 'عنوان المصروف';

  @override
  String get expenseTitleOptional => 'عنوان المصروف (اختياري)';

  @override
  String get expenseAmountLabel => 'المبلغ';

  @override
  String get expenseCategoryLabel => 'الفئة';

  @override
  String get expenseCategoryRequiredLabel => 'الفئة *';

  @override
  String get categoryRequired => 'يرجى اختيار فئة المصروف';

  @override
  String get defaultExpenseTitle => 'مصروف';

  @override
  String get expenseDateLabel => 'التاريخ';

  @override
  String get expenseNotesLabel => 'ملاحظات';

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get cashPayment => 'نقداً';

  @override
  String get creditCardPayment => 'بطاقة ائتمان';

  @override
  String get bankTransferPayment => 'تحويل بنكي';

  @override
  String get filterAll => 'الجميع';

  @override
  String get filterAllCategories => 'كل الفئات';

  @override
  String get filterEmployee => 'الموظف:';

  @override
  String get noExpensesFound => 'لا توجد مصروفات مسجلة';

  @override
  String get noExpensesAdmin => 'لا توجد مصروفات تطابق البحث';

  @override
  String get searchHint => 'البحث في المصروفات...';

  @override
  String get profileUpdateSuccess => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get genericError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get employeesTitle => 'إدارة الموظفين';

  @override
  String get addUserButton => 'إضافة مستخدم';

  @override
  String get addUserTitle => 'إضافة مستخدم جديد';

  @override
  String get userRoleLabel => 'الصلاحية';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusInactive => 'معطل';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get deactivateUser => 'تعطيل الحساب';

  @override
  String get reactivateUser => 'تفعيل الحساب';

  @override
  String get changeRole => 'تغيير الصلاحية';

  @override
  String get makeAdmin => 'ترقية إلى مدير';

  @override
  String get makeEmployee => 'تحويل إلى موظف';

  @override
  String get deleteUser => 'حذف الحساب نهائياً';

  @override
  String get deleteUserConfirmTitle => 'حذف المستخدم';

  @override
  String get deleteUserConfirmMessage =>
      'هل أنت متأكد من حذف هذا المستخدم؟ سيتم حذف حساب المستخدم وجميع بياناته المرتبطة به.';

  @override
  String get deactivateUserConfirmTitle => 'تعطيل المستخدم';

  @override
  String get deactivateUserConfirmMessage =>
      'هل أنت متأكد من تعطيل هذا المستخدم؟ لن يتمكن من تسجيل الدخول إلى التطبيق، مع الحفاظ الكامل على كافة المصروفات والتقارير التاريخية.';

  @override
  String get reactivateUserConfirmTitle => 'تفعيل المستخدم';

  @override
  String get reactivateUserConfirmMessage =>
      'هل تريد إعادة تفعيل حساب هذا المستخدم وتمكينه من استخدام التطبيق؟';

  @override
  String get cannotDeactivateSelf => 'لا يمكنك تعطيل حسابك الحالي.';

  @override
  String get cannotDeleteSelf => 'لا يمكنك حذف حسابك الحالي.';

  @override
  String get cannotDemoteLastAdmin =>
      'لا يمكنك تحويل آخر مسؤول متبقي إلى موظف.';

  @override
  String get cannotDeactivateLastAdmin =>
      'لا يمكنك تعطيل آخر مسؤول نشط في النظام.';

  @override
  String get userCreatedSuccess => 'تم إنشاء المستخدم بنجاح';

  @override
  String get userDeletedSuccess => 'تم حذف المستخدم بنجاح';

  @override
  String get userRoleUpdatedSuccess => 'تم تحديث الصلاحية بنجاح';

  @override
  String get userStatusUpdatedSuccess => 'تم تحديث حالة الحساب بنجاح';

  @override
  String get accountInactiveError =>
      'هذا الحساب غير مفعل. يرجى التواصل مع المسؤول.';

  @override
  String get allRoles => 'كل الصلاحيات';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get teamAndExpenses => 'فريق العمل والمصروفات';

  @override
  String get registeredUsersCount => 'مستخدم مسجل';

  @override
  String get teamTotalSpent => 'إجمالي منصرفات الفريق';

  @override
  String get totalOperations => 'إجمالي العمليات';

  @override
  String get searchEmployeeHint => 'البحث عن موظف بالاسم أو البريد...';

  @override
  String get noUsersFound => 'لا يوجد مستخدمون مسجلون';

  @override
  String get employeeDetailsTitle => 'تفاصيل الموظف';

  @override
  String get employeeExpensesTitle => 'مصروفات الموظف';

  @override
  String get totalExpensesLabel => 'إجمالي المصروفات';

  @override
  String get expensesCountLabel => 'عدد المصروفات';

  @override
  String get thisMonthExpensesLabel => 'مصروفات هذا الشهر';

  @override
  String get todayExpensesLabel => 'مصروفات اليوم';

  @override
  String get viewExpenses => 'عرض المصروفات';

  @override
  String get noExpensesForEmployee => 'لا توجد مصروفات مسجلة لهذا الموظف';

  @override
  String get filterAllPaymentMethods => 'كل طرق الدفع';

  @override
  String get resetFilters => 'إعادة تعيين';

  @override
  String get filterByDate => 'نطاق التاريخ';

  @override
  String get allTime => 'كل الفترات';

  @override
  String get requireAdminApproval => 'طلب موافقة المسؤول على المستخدمين الجدد';

  @override
  String get requireAdminApprovalDesc =>
      'عند التفعيل، تتطلب الحسابات الجديدة موافقة المشرف قبل التمكن من الدخول إلى التطبيق.';

  @override
  String get adminApprovalSettingUpdated => 'تم تحديث إعدادات الموافقة بنجاح';

  @override
  String get adminSettingsSection => 'إعدادات المسؤول';

  @override
  String get pendingApprovalTitle => 'الحساب قيد المراجعة';

  @override
  String get pendingApprovalMessage =>
      'حسابك قيد انتظار موافقة المسؤول. سيتم تفعيل حسابك وإتاحة الوصول لك فور اعتماد الطلب من قبل مدير النظام.';

  @override
  String get rejectedAccountTitle => 'تم رفض طلب التسجيل';

  @override
  String get rejectedAccountMessage =>
      'نعتذر، لقد تم رفض طلب تسجيل حسابك من قبل مدير النظام. يرجى التواصل مع المسؤول إذا كنت تعتقد أن هذا حدث بالخطأ.';

  @override
  String get checkStatusButton => 'التحقق من حالة الحساب';

  @override
  String get statusStillPending => 'حسابك لا يزال بانتظار موافقة المسؤول.';

  @override
  String get pendingRequestsTitle => 'طلبات التسجيل المعلقة';

  @override
  String get pendingRequestsBadge => 'طلبات معلقة';

  @override
  String get approveUser => 'موافقة واعتماد';

  @override
  String get rejectUser => 'رفض الطلب';

  @override
  String get approveUserConfirmTitle => 'اعتماد المستخدم';

  @override
  String get approveUserConfirmMessage =>
      'هل أنت متأكد من رغبتك في اعتماد حساب هذا المستخدم وتفعيله؟';

  @override
  String get rejectUserConfirmTitle => 'رفض طلب المستخدم';

  @override
  String get rejectUserConfirmMessage =>
      'هل أنت متأكد من رغبتك في رفض طلب انضمام هذا المستخدم؟';

  @override
  String get userApprovedSuccess => 'تم اعتماد وتفعيل حساب المستخدم بنجاح';

  @override
  String get userRejectedSuccess => 'تم رفض طلب المستخدم';

  @override
  String get noPendingRequests => 'لا توجد طلبات تسجيل معلقة حالياً';

  @override
  String get notificationsTitle => 'إشعارات المسؤول';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get noNotifications => 'لا توجد إشعارات جديدة';

  @override
  String get newRegistrationNotification => 'طلب تسجيل جديد';

  @override
  String get syncStatusSynced => 'مكتمل المزامنة';

  @override
  String get syncStatusPending => 'محفوظ محلياً';

  @override
  String get syncStatusSyncing => 'جارٍ المزامنة...';

  @override
  String get syncStatusFailed => 'فشلت المزامنة - اضغط لإعادة المحاولة';

  @override
  String get expenseSavedOffline =>
      'تم حفظ المصروف محلياً. ستتم المزامنة تلقائياً عند توفر الإنترنت.';

  @override
  String get expenseSyncRetrying => 'جارٍ إعادة مزامنة المصروفات...';

  @override
  String get expenseSyncSuccess => 'تمت مزامنة جميع المصروفات المحلية بنجاح.';

  @override
  String get retrySync => 'إعادة المزامنة';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodThisWeek => 'هذا الأسبوع';

  @override
  String get periodThisMonth => 'هذا الشهر';

  @override
  String get totalMonthlyExpenses => 'إجمالي المصروفات';

  @override
  String get companyTotalExpenses => 'إجمالي مصروفات الشركة';

  @override
  String get employeeTotalExpenses => 'إجمالي مصروفاتي';

  @override
  String get distributionByCategory => 'توزيع المصروفات حسب الفئة';

  @override
  String get distributionByEmployee => 'توزيع المصروفات حسب الموظفين';

  @override
  String get recentExpenses => 'أحدث المصروفات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get viewReports => 'عرض التقارير';

  @override
  String get noExpensesThisPeriod => 'لا توجد مصروفات مسجلة لهذه الفترة';

  @override
  String get availableBalance => 'الرصيد المتاح';

  @override
  String get totalReceived => 'إجمالي المستلم';

  @override
  String get totalSpent => 'إجمالي المصروف';

  @override
  String get addBalance => 'إضافة رصيد';

  @override
  String get addBalanceTitle => 'إضافة رصيد للموظف';

  @override
  String get addBalanceSubtitle => 'إضافة مبلغ إلى الرصيد المتاح للموظف';

  @override
  String get amountMustBeGreaterThanZero => 'يجب إدخال مبلغ أكبر من صفر.';

  @override
  String get balanceAddedSuccess => 'تمت إضافة الرصيد بنجاح';

  @override
  String get insufficientBalance => 'الرصيد المتاح غير كافٍ لهذا المصروف.';

  @override
  String get noAvailableBalance => 'لا يوجد رصيد متاح.';

  @override
  String get transactionHistory => 'سجل المعاملات والبدلات';

  @override
  String get employeeBalances => 'أرصدة الموظفين';

  @override
  String get remainingBalance => 'المتبقي';

  @override
  String get givenAmount => 'المستلم';

  @override
  String get spentAmount => 'المصروف';

  @override
  String get allowanceDate => 'تاريخ الإضافة';

  @override
  String get allowanceNote => 'ملاحظة (اختياري)';

  @override
  String get allowanceNoteHint => 'مثال: بدلات الأسبوع / مصروفات مكتبية';

  @override
  String get creditTransaction => 'إضافة رصيد';

  @override
  String get expenseTransaction => 'مصروف';

  @override
  String get adjustmentAddTransaction => 'تسوية (إضافة)';

  @override
  String get adjustmentSubTransaction => 'تسوية (خصم)';

  @override
  String get confirmAddBalance => 'تأكيد إضافة الرصيد';

  @override
  String get noTransactionsYet => 'لا توجد معاملات مسجلة بعد';

  @override
  String get expenseUpdatedSuccess => 'تم تعديل المصروف بنجاح';

  @override
  String get expenseAddedSuccess => 'تم حفظ المصروف بنجاح';

  @override
  String get receiptPhotoLabel => 'صورة الإيصال / الفاتورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get saveChanges => 'حفظ التعديلات';

  @override
  String get notesLabel => 'الملاحظات';

  @override
  String get notesHint => 'ملاحظات إضافية...';

  @override
  String get filterDateRange => 'تحديد فترة';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get currencyEgp => 'جنيه مصري (EGP)';

  @override
  String get currencyUsd => 'دولار أمريكي (USD)';

  @override
  String get currencyEgpShort => 'ج.م';

  @override
  String get currencyUsdShort => '\$';

  @override
  String get availableBalanceEgp => 'الرصيد المتاح (EGP)';

  @override
  String get availableBalanceUsd => 'الرصيد المتاح (USD)';

  @override
  String get totalReceivedEgp => 'المستلم (EGP)';

  @override
  String get totalReceivedUsd => 'المستلم (USD)';

  @override
  String get totalSpentEgp => 'المصروف (EGP)';

  @override
  String get totalSpentUsd => 'المصروف (USD)';

  @override
  String get tripLocationLabel => 'موقع المشوار';

  @override
  String get insideCairo => 'داخل القاهرة';

  @override
  String get outsideCairo => 'خارج القاهرة';

  @override
  String get governorateLabel => 'المحافظة';

  @override
  String get selectGovernorate => 'اختر المحافظة';

  @override
  String get governorateRequired =>
      'يجب اختيار المحافظة للمشاوير خارج القاهرة.';

  @override
  String get travelStatistics => 'إحصائيات المشاوير والسفر';

  @override
  String get totalTrips => 'إجمالي المشاوير';

  @override
  String get insideCairoTrips => 'مشاوير داخل القاهرة';

  @override
  String get outsideCairoTrips => 'مشاوير خارج القاهرة';

  @override
  String get governorateBreakdown => 'توزيع المحافظات';

  @override
  String get travelBonus => 'بدل السفر والمشاوير';

  @override
  String get travelBonusSettings => 'إعدادات بدل السفر';

  @override
  String get travelBonusSettingsDesc =>
      'ضبط مكافأة وبدل المشاوير خارج القاهرة للموظفين';

  @override
  String get bonusPerTrip => 'المكافأة لكل مشوار';

  @override
  String get potentialBonus => 'المكافأة المستحقة التقديرية';

  @override
  String get travelActivity => 'نشاط المشاوير والسفر';

  @override
  String get topTraveler => 'الأكثر سفراً خارج القاهرة';

  @override
  String get tripsCountUnit => 'مشاوير';

  @override
  String get noTravelActivity => 'لا يوجد نشاط مشاوير مسجل لهذه الفترة';

  @override
  String get salary => 'المرتب';

  @override
  String get monthlySalary => 'المرتب الشهري';

  @override
  String get salaryAdvance => 'السلفة';

  @override
  String get salaryAdvances => 'السلف';

  @override
  String get totalAdvances => 'إجمالي السلف';

  @override
  String get remainingSalary => 'المتبقي من المرتب';

  @override
  String get addSalaryAdvance => 'إضافة سلفة';

  @override
  String get editSalaryAdvance => 'تعديل السلفة';

  @override
  String get deleteSalaryAdvance => 'حذف السلفة';

  @override
  String get deleteSalaryAdvanceConfirm =>
      'هل أنت متأكد من رغبتك في حذف هذه السلفة؟';

  @override
  String get advanceDate => 'تاريخ السلفة';

  @override
  String get advanceReason => 'سبب السلفة';

  @override
  String get advanceReasonHint => 'مثال: مصاريف طارئة، شخصية...';

  @override
  String get editSalary => 'تعديل المرتب';

  @override
  String get salaryAmount => 'قيمة المرتب';

  @override
  String get salaryUpdatedSuccess => 'تم تحديث راتب الموظف بنجاح';

  @override
  String get advanceAddedSuccess => 'تمت إضافة السلفة بنجاح';

  @override
  String get advanceUpdatedSuccess => 'تم تعديل السلفة بنجاح';

  @override
  String get advanceDeletedSuccess => 'تم حذف السلفة بنجاح';

  @override
  String get salariesOverview => 'نظرة عامة على المرتبات والسلف';

  @override
  String get totalSalaries => 'إجمالي المرتبات';

  @override
  String get totalRemainingSalaries => 'إجمالي المتبقي';

  @override
  String get noSalaryAdvancesYet => 'لا توجد سلف مسجلة حتى الآن';

  @override
  String get advanceCreatedBy => 'سجلت بواسطة';

  @override
  String get weeklyWorkBudget => 'ميزانية العمل الأسبوعية';

  @override
  String get weeklyAllowance => 'العهدة الأسبوعية';

  @override
  String get workAllowance => 'بدل العمل';

  @override
  String get receivedThisWeek => 'المستلم هذا الأسبوع';

  @override
  String get spentThisWeek => 'المصروف هذا الأسبوع';

  @override
  String get remainingThisWeek => 'المتبقي هذا الأسبوع';

  @override
  String get addAllowance => 'إضافة عهدة';

  @override
  String get editAllowance => 'تعديل العهدة';

  @override
  String get deleteAllowance => 'حذف العهدة';

  @override
  String get deleteAllowanceConfirm =>
      'هل أنت متأكد من رغبتك في حذف حركة العهدة هذه؟';

  @override
  String get allowanceDateLabel => 'تاريخ العهدة';

  @override
  String get allowanceReasonLabel => 'سبب العهدة';

  @override
  String get allowanceReasonHint => 'مثال: عهدة أسبوعية، مصروفات عمل...';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get previousWeek => 'الأسبوع السابق';

  @override
  String get nextWeek => 'الأسبوع القادم';

  @override
  String get totalReceivedWeekly => 'إجمالي المستلم';

  @override
  String get totalSpentWeekly => 'إجمالي المصروف';

  @override
  String get totalRemainingWeekly => 'إجمالي المتبقي';

  @override
  String get allowanceAddedSuccess => 'تم تسجيل العهدة بنجاح';

  @override
  String get allowanceUpdatedSuccess => 'تم تعديل العهدة بنجاح';

  @override
  String get allowanceDeletedSuccess => 'تم حذف العهدة بنجاح';

  @override
  String get noAllowanceTransactionsYet =>
      'لا توجد حركات عهد مسجلة لهذه الفترة';

  @override
  String get weeklyAllowanceTransactions => 'حركات العهد';
}
