import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Spendly'**
  String get appName;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'My Expenses'**
  String get navExpenses;

  /// No description provided for @navAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'All Expenses'**
  String get navAllExpenses;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get navEmployees;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navProfile;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track and manage your business expenses seamlessly'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Spendly'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to manage expenses and track receipts'**
  String get signupSubtitle;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupButton;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @createAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createAccountLink;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@company.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get fullNameRequired;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editNameTitle;

  /// No description provided for @joinedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDateLabel;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @userLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load user data'**
  String get userLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from the application?'**
  String get logoutConfirmMessage;

  /// No description provided for @settingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Security'**
  String get settingsHeader;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password securely'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get newPasswordRequired;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @confirmNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmNewPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordMustBeDifferent;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangeSuccess;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

  /// No description provided for @changePasswordHeaderInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a strong new password with at least 6 characters.'**
  String get changePasswordHeaderInfo;

  /// No description provided for @profileImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profileImageTitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @photoUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get photoUploadedSuccess;

  /// No description provided for @photoRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed'**
  String get photoRemovedSuccess;

  /// No description provided for @photoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile picture'**
  String get photoUploadError;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpenseTitle;

  /// No description provided for @editExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpenseTitle;

  /// No description provided for @expenseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetailsTitle;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get deleteExpenseConfirm;

  /// No description provided for @expenseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense Title'**
  String get expenseTitleLabel;

  /// No description provided for @expenseTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Expense Title (Optional)'**
  String get expenseTitleOptional;

  /// No description provided for @expenseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmountLabel;

  /// No description provided for @expenseCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategoryLabel;

  /// No description provided for @expenseCategoryRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get expenseCategoryRequiredLabel;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an expense category'**
  String get categoryRequired;

  /// No description provided for @defaultExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get defaultExpenseTitle;

  /// No description provided for @expenseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDateLabel;

  /// No description provided for @expenseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get expenseNotesLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// No description provided for @creditCardPayment.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCardPayment;

  /// No description provided for @bankTransferPayment.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransferPayment;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get filterAllCategories;

  /// No description provided for @filterEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee:'**
  String get filterEmployee;

  /// No description provided for @noExpensesFound.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded'**
  String get noExpensesFound;

  /// No description provided for @noExpensesAdmin.
  ///
  /// In en, this message translates to:
  /// **'No expenses match the filter'**
  String get noExpensesAdmin;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in expenses...'**
  String get searchHint;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @employeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get employeesTitle;

  /// No description provided for @addUserButton.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUserButton;

  /// No description provided for @addUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addUserTitle;

  /// No description provided for @userRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userRoleLabel;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get statusInactive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateUser;

  /// No description provided for @reactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get reactivateUser;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Promote to Admin'**
  String get makeAdmin;

  /// No description provided for @makeEmployee.
  ///
  /// In en, this message translates to:
  /// **'Demote to Employee'**
  String get makeEmployee;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUserConfirmTitle;

  /// No description provided for @deleteUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this user? This will remove their user account and associated profile.'**
  String get deleteUserConfirmMessage;

  /// No description provided for @deactivateUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User'**
  String get deactivateUserConfirmTitle;

  /// No description provided for @deactivateUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this user? They will not be able to log in, but all historical expenses will be preserved.'**
  String get deactivateUserConfirmMessage;

  /// No description provided for @reactivateUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get reactivateUserConfirmTitle;

  /// No description provided for @reactivateUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reactivate this user\'s access to the application?'**
  String get reactivateUserConfirmMessage;

  /// No description provided for @cannotDeactivateSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot deactivate your own account.'**
  String get cannotDeactivateSelf;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your own account.'**
  String get cannotDeleteSelf;

  /// No description provided for @cannotDemoteLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot demote the last remaining administrator.'**
  String get cannotDemoteLastAdmin;

  /// No description provided for @cannotDeactivateLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'You cannot deactivate the last active administrator.'**
  String get cannotDeactivateLastAdmin;

  /// No description provided for @userCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccess;

  /// No description provided for @userDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeletedSuccess;

  /// No description provided for @userRoleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get userRoleUpdatedSuccess;

  /// No description provided for @userStatusUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account status updated successfully'**
  String get userStatusUpdatedSuccess;

  /// No description provided for @accountInactiveError.
  ///
  /// In en, this message translates to:
  /// **'This account is deactivated. Please contact an administrator.'**
  String get accountInactiveError;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @teamAndExpenses.
  ///
  /// In en, this message translates to:
  /// **'Team & Expenses'**
  String get teamAndExpenses;

  /// No description provided for @registeredUsersCount.
  ///
  /// In en, this message translates to:
  /// **'registered users'**
  String get registeredUsersCount;

  /// No description provided for @teamTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Team Total Spent'**
  String get teamTotalSpent;

  /// No description provided for @totalOperations.
  ///
  /// In en, this message translates to:
  /// **'Total Operations'**
  String get totalOperations;

  /// No description provided for @searchEmployeeHint.
  ///
  /// In en, this message translates to:
  /// **'Search users by name or email...'**
  String get searchEmployeeHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @employeeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get employeeDetailsTitle;

  /// No description provided for @employeeExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Expenses'**
  String get employeeExpensesTitle;

  /// No description provided for @totalExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpensesLabel;

  /// No description provided for @expensesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Expenses'**
  String get expensesCountLabel;

  /// No description provided for @thisMonthExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthExpensesLabel;

  /// No description provided for @todayExpensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Expenses'**
  String get todayExpensesLabel;

  /// No description provided for @viewExpenses.
  ///
  /// In en, this message translates to:
  /// **'View Expenses'**
  String get viewExpenses;

  /// No description provided for @noExpensesForEmployee.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this employee'**
  String get noExpensesForEmployee;

  /// No description provided for @filterAllPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'All Payment Methods'**
  String get filterAllPaymentMethods;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get filterByDate;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @requireAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Require admin approval for new users'**
  String get requireAdminApproval;

  /// No description provided for @requireAdminApprovalDesc.
  ///
  /// In en, this message translates to:
  /// **'When enabled, newly registered users cannot access the app until approved by an administrator.'**
  String get requireAdminApprovalDesc;

  /// No description provided for @adminApprovalSettingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Approval setting updated successfully'**
  String get adminApprovalSettingUpdated;

  /// No description provided for @adminSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettingsSection;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for administrator approval. You will be able to access Spendly once an administrator approves your registration request.'**
  String get pendingApprovalMessage;

  /// No description provided for @rejectedAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Request Rejected'**
  String get rejectedAccountTitle;

  /// No description provided for @rejectedAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Your registration request was not approved by an administrator. Please contact your organization administrator if you think this is a mistake.'**
  String get rejectedAccountMessage;

  /// No description provided for @checkStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatusButton;

  /// No description provided for @statusStillPending.
  ///
  /// In en, this message translates to:
  /// **'Your account is still waiting for administrator approval.'**
  String get statusStillPending;

  /// No description provided for @pendingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Registrations'**
  String get pendingRequestsTitle;

  /// No description provided for @pendingRequestsBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequestsBadge;

  /// No description provided for @approveUser.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveUser;

  /// No description provided for @rejectUser.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectUser;

  /// No description provided for @approveUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve User'**
  String get approveUserConfirmTitle;

  /// No description provided for @approveUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this user and grant them access to the application?'**
  String get approveUserConfirmMessage;

  /// No description provided for @rejectUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Registration Request'**
  String get rejectUserConfirmTitle;

  /// No description provided for @rejectUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this registration request?'**
  String get rejectUserConfirmMessage;

  /// No description provided for @userApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User approved successfully'**
  String get userApprovedSuccess;

  /// No description provided for @userRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User registration request rejected'**
  String get userRejectedSuccess;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending registration requests'**
  String get noPendingRequests;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @newRegistrationNotification.
  ///
  /// In en, this message translates to:
  /// **'New Registration Request'**
  String get newRegistrationNotification;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed - Tap to retry'**
  String get syncStatusFailed;

  /// No description provided for @expenseSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Expense saved locally. It will sync automatically when internet is available.'**
  String get expenseSavedOffline;

  /// No description provided for @expenseSyncRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying expense sync...'**
  String get expenseSyncRetrying;

  /// No description provided for @expenseSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'All local expenses have been synchronized successfully.'**
  String get expenseSyncSuccess;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySync;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodThisMonth;

  /// No description provided for @totalMonthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalMonthlyExpenses;

  /// No description provided for @companyTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Company Expenses'**
  String get companyTotalExpenses;

  /// No description provided for @employeeTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'My Total Expenses'**
  String get employeeTotalExpenses;

  /// No description provided for @distributionByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get distributionByCategory;

  /// No description provided for @distributionByEmployee.
  ///
  /// In en, this message translates to:
  /// **'Spending by Employee'**
  String get distributionByEmployee;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @noExpensesThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this period'**
  String get noExpensesThisPeriod;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total Received'**
  String get totalReceived;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @addBalance.
  ///
  /// In en, this message translates to:
  /// **'Add Balance'**
  String get addBalance;

  /// No description provided for @addBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Employee Balance'**
  String get addBalanceTitle;

  /// No description provided for @addBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add funds to employee\'s available balance'**
  String get addBalanceSubtitle;

  /// No description provided for @amountMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get amountMustBeGreaterThanZero;

  /// No description provided for @balanceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Balance added successfully'**
  String get balanceAddedSuccess;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient available balance for this expense.'**
  String get insufficientBalance;

  /// No description provided for @noAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'No available balance.'**
  String get noAvailableBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction & Allowance History'**
  String get transactionHistory;

  /// No description provided for @employeeBalances.
  ///
  /// In en, this message translates to:
  /// **'Employee Balances'**
  String get employeeBalances;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingBalance;

  /// No description provided for @givenAmount.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get givenAmount;

  /// No description provided for @spentAmount.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentAmount;

  /// No description provided for @allowanceDate.
  ///
  /// In en, this message translates to:
  /// **'Allowance Date'**
  String get allowanceDate;

  /// No description provided for @allowanceNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get allowanceNote;

  /// No description provided for @allowanceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Weekly allowance / Office expenses'**
  String get allowanceNoteHint;

  /// No description provided for @creditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Credit (Add)'**
  String get creditTransaction;

  /// No description provided for @expenseTransaction.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseTransaction;

  /// No description provided for @adjustmentAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Adjustment (Add)'**
  String get adjustmentAddTransaction;

  /// No description provided for @adjustmentSubTransaction.
  ///
  /// In en, this message translates to:
  /// **'Adjustment (Deduct)'**
  String get adjustmentSubTransaction;

  /// No description provided for @confirmAddBalance.
  ///
  /// In en, this message translates to:
  /// **'Confirm Add Balance'**
  String get confirmAddBalance;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet'**
  String get noTransactionsYet;

  /// No description provided for @expenseUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully'**
  String get expenseUpdatedSuccess;

  /// No description provided for @expenseAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get expenseAddedSuccess;

  /// No description provided for @receiptPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt / Invoice Photo'**
  String get receiptPhotoLabel;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes...'**
  String get notesHint;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get filterDateRange;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Pound (EGP)'**
  String get currencyEgp;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US Dollar (USD)'**
  String get currencyUsd;

  /// No description provided for @currencyEgpShort.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currencyEgpShort;

  /// No description provided for @currencyUsdShort.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get currencyUsdShort;

  /// No description provided for @availableBalanceEgp.
  ///
  /// In en, this message translates to:
  /// **'Available Balance (EGP)'**
  String get availableBalanceEgp;

  /// No description provided for @availableBalanceUsd.
  ///
  /// In en, this message translates to:
  /// **'Available Balance (USD)'**
  String get availableBalanceUsd;

  /// No description provided for @totalReceivedEgp.
  ///
  /// In en, this message translates to:
  /// **'Received (EGP)'**
  String get totalReceivedEgp;

  /// No description provided for @totalReceivedUsd.
  ///
  /// In en, this message translates to:
  /// **'Received (USD)'**
  String get totalReceivedUsd;

  /// No description provided for @totalSpentEgp.
  ///
  /// In en, this message translates to:
  /// **'Spent (EGP)'**
  String get totalSpentEgp;

  /// No description provided for @totalSpentUsd.
  ///
  /// In en, this message translates to:
  /// **'Spent (USD)'**
  String get totalSpentUsd;

  /// No description provided for @tripLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip Location'**
  String get tripLocationLabel;

  /// No description provided for @insideCairo.
  ///
  /// In en, this message translates to:
  /// **'Inside Cairo'**
  String get insideCairo;

  /// No description provided for @outsideCairo.
  ///
  /// In en, this message translates to:
  /// **'Outside Cairo'**
  String get outsideCairo;

  /// No description provided for @governorateLabel.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorateLabel;

  /// No description provided for @selectGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Select Governorate'**
  String get selectGovernorate;

  /// No description provided for @governorateRequired.
  ///
  /// In en, this message translates to:
  /// **'Governorate is required for trips outside Cairo.'**
  String get governorateRequired;

  /// No description provided for @travelStatistics.
  ///
  /// In en, this message translates to:
  /// **'Travel & Trip Statistics'**
  String get travelStatistics;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// No description provided for @insideCairoTrips.
  ///
  /// In en, this message translates to:
  /// **'Inside Cairo Trips'**
  String get insideCairoTrips;

  /// No description provided for @outsideCairoTrips.
  ///
  /// In en, this message translates to:
  /// **'Outside Cairo Trips'**
  String get outsideCairoTrips;

  /// No description provided for @governorateBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Governorate Breakdown'**
  String get governorateBreakdown;

  /// No description provided for @travelBonus.
  ///
  /// In en, this message translates to:
  /// **'Travel Bonus'**
  String get travelBonus;

  /// No description provided for @travelBonusSettings.
  ///
  /// In en, this message translates to:
  /// **'Travel Bonus Settings'**
  String get travelBonusSettings;

  /// No description provided for @travelBonusSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure bonus for employee trips outside Cairo'**
  String get travelBonusSettingsDesc;

  /// No description provided for @bonusPerTrip.
  ///
  /// In en, this message translates to:
  /// **'Bonus per Trip'**
  String get bonusPerTrip;

  /// No description provided for @potentialBonus.
  ///
  /// In en, this message translates to:
  /// **'Potential Bonus'**
  String get potentialBonus;

  /// No description provided for @travelActivity.
  ///
  /// In en, this message translates to:
  /// **'Travel Activity'**
  String get travelActivity;

  /// No description provided for @topTraveler.
  ///
  /// In en, this message translates to:
  /// **'Top Outside-Cairo Traveler'**
  String get topTraveler;

  /// No description provided for @tripsCountUnit.
  ///
  /// In en, this message translates to:
  /// **'trips'**
  String get tripsCountUnit;

  /// No description provided for @noTravelActivity.
  ///
  /// In en, this message translates to:
  /// **'No travel activity recorded for this period'**
  String get noTravelActivity;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @monthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary'**
  String get monthlySalary;

  /// No description provided for @salaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Salary Advance'**
  String get salaryAdvance;

  /// No description provided for @salaryAdvances.
  ///
  /// In en, this message translates to:
  /// **'Salary Advances'**
  String get salaryAdvances;

  /// No description provided for @totalAdvances.
  ///
  /// In en, this message translates to:
  /// **'Total Advances'**
  String get totalAdvances;

  /// No description provided for @remainingSalary.
  ///
  /// In en, this message translates to:
  /// **'Remaining Salary'**
  String get remainingSalary;

  /// No description provided for @addSalaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Add Advance'**
  String get addSalaryAdvance;

  /// No description provided for @editSalaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Edit Advance'**
  String get editSalaryAdvance;

  /// No description provided for @deleteSalaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Delete Advance'**
  String get deleteSalaryAdvance;

  /// No description provided for @deleteSalaryAdvanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this salary advance?'**
  String get deleteSalaryAdvanceConfirm;

  /// No description provided for @advanceDate.
  ///
  /// In en, this message translates to:
  /// **'Advance Date'**
  String get advanceDate;

  /// No description provided for @advanceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get advanceReason;

  /// No description provided for @advanceReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Emergency, Personal expense...'**
  String get advanceReasonHint;

  /// No description provided for @editSalary.
  ///
  /// In en, this message translates to:
  /// **'Edit Salary'**
  String get editSalary;

  /// No description provided for @salaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Salary Amount'**
  String get salaryAmount;

  /// No description provided for @salaryUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee salary updated successfully'**
  String get salaryUpdatedSuccess;

  /// No description provided for @advanceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Salary advance recorded successfully'**
  String get advanceAddedSuccess;

  /// No description provided for @advanceUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Salary advance updated successfully'**
  String get advanceUpdatedSuccess;

  /// No description provided for @advanceDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Salary advance deleted successfully'**
  String get advanceDeletedSuccess;

  /// No description provided for @salariesOverview.
  ///
  /// In en, this message translates to:
  /// **'Salaries & Advances Overview'**
  String get salariesOverview;

  /// No description provided for @totalSalaries.
  ///
  /// In en, this message translates to:
  /// **'Total Salaries'**
  String get totalSalaries;

  /// No description provided for @totalRemainingSalaries.
  ///
  /// In en, this message translates to:
  /// **'Total Remaining'**
  String get totalRemainingSalaries;

  /// No description provided for @noSalaryAdvancesYet.
  ///
  /// In en, this message translates to:
  /// **'No salary advances recorded yet'**
  String get noSalaryAdvancesYet;

  /// No description provided for @advanceCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by'**
  String get advanceCreatedBy;

  /// No description provided for @weeklyWorkBudget.
  ///
  /// In en, this message translates to:
  /// **'Weekly Work Budget'**
  String get weeklyWorkBudget;

  /// No description provided for @weeklyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Weekly Allowance'**
  String get weeklyAllowance;

  /// No description provided for @workAllowance.
  ///
  /// In en, this message translates to:
  /// **'Work Allowance'**
  String get workAllowance;

  /// No description provided for @receivedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Received This Week'**
  String get receivedThisWeek;

  /// No description provided for @spentThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Spent This Week'**
  String get spentThisWeek;

  /// No description provided for @remainingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Remaining This Week'**
  String get remainingThisWeek;

  /// No description provided for @addAllowance.
  ///
  /// In en, this message translates to:
  /// **'Add Allowance'**
  String get addAllowance;

  /// No description provided for @editAllowance.
  ///
  /// In en, this message translates to:
  /// **'Edit Allowance'**
  String get editAllowance;

  /// No description provided for @deleteAllowance.
  ///
  /// In en, this message translates to:
  /// **'Delete Allowance'**
  String get deleteAllowance;

  /// No description provided for @deleteAllowanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this allowance transaction?'**
  String get deleteAllowanceConfirm;

  /// No description provided for @allowanceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowance Date'**
  String get allowanceDateLabel;

  /// No description provided for @allowanceReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get allowanceReasonLabel;

  /// No description provided for @allowanceReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Weekly work budget, Project expenses...'**
  String get allowanceReasonHint;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous Week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// No description provided for @totalReceivedWeekly.
  ///
  /// In en, this message translates to:
  /// **'Total Received'**
  String get totalReceivedWeekly;

  /// No description provided for @totalSpentWeekly.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpentWeekly;

  /// No description provided for @totalRemainingWeekly.
  ///
  /// In en, this message translates to:
  /// **'Total Remaining'**
  String get totalRemainingWeekly;

  /// No description provided for @allowanceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work allowance recorded successfully'**
  String get allowanceAddedSuccess;

  /// No description provided for @allowanceUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work allowance updated successfully'**
  String get allowanceUpdatedSuccess;

  /// No description provided for @allowanceDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work allowance deleted successfully'**
  String get allowanceDeletedSuccess;

  /// No description provided for @noAllowanceTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No allowance transactions recorded for this period'**
  String get noAllowanceTransactionsYet;

  /// No description provided for @weeklyAllowanceTransactions.
  ///
  /// In en, this message translates to:
  /// **'Allowance Transactions'**
  String get weeklyAllowanceTransactions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
