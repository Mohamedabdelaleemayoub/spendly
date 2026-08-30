// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Spendly';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navExpenses => 'My Expenses';

  @override
  String get navAllExpenses => 'All Expenses';

  @override
  String get navReports => 'Reports';

  @override
  String get navCategories => 'Categories';

  @override
  String get navEmployees => 'Employees';

  @override
  String get navProfile => 'Account';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Sign in to track and manage your business expenses seamlessly';

  @override
  String get loginButton => 'Sign In';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'OR';

  @override
  String get signupTitle => 'Join Spendly';

  @override
  String get signupSubtitle =>
      'Create an account to manage expenses and track receipts';

  @override
  String get signupButton => 'Create Account';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get createAccountLink => 'Create new account';

  @override
  String get signInLink => 'Sign in';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'name@company.com';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get fullNameRequired => 'Please enter your name';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editNameTitle => 'Edit Name';

  @override
  String get joinedDateLabel => 'Joined Date';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get userLoadFailed => 'Could not load user data';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirmTitle => 'Log Out';

  @override
  String get logoutConfirmMessage =>
      'Are you sure you want to log out from the application?';

  @override
  String get settingsHeader => 'Preferences & Security';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageArabic => 'العربية (Arabic)';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get themeLabel => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System Default';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update your account password securely';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get currentPasswordRequired => 'Please enter your current password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get newPasswordRequired => 'Please enter a new password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get confirmNewPasswordRequired => 'Please confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordMustBeDifferent =>
      'New password must be different from current password';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get changePasswordButton => 'Change Password';

  @override
  String get changePasswordHeaderInfo =>
      'Enter your current password and choose a strong new password with at least 6 characters.';

  @override
  String get profileImageTitle => 'Profile Picture';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take a Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get photoUploadedSuccess => 'Profile picture updated successfully';

  @override
  String get photoRemovedSuccess => 'Profile picture removed';

  @override
  String get photoUploadError => 'Failed to upload profile picture';

  @override
  String get addExpenseTitle => 'Add Expense';

  @override
  String get editExpenseTitle => 'Edit Expense';

  @override
  String get expenseDetailsTitle => 'Expense Details';

  @override
  String get deleteExpenseTitle => 'Delete Expense';

  @override
  String get deleteExpenseConfirm =>
      'Are you sure you want to delete this expense?';

  @override
  String get expenseTitleLabel => 'Expense Title';

  @override
  String get expenseTitleOptional => 'Expense Title (Optional)';

  @override
  String get expenseAmountLabel => 'Amount';

  @override
  String get expenseCategoryLabel => 'Category';

  @override
  String get expenseCategoryRequiredLabel => 'Category *';

  @override
  String get categoryRequired => 'Please select an expense category';

  @override
  String get defaultExpenseTitle => 'Expense';

  @override
  String get expenseDateLabel => 'Date';

  @override
  String get expenseNotesLabel => 'Notes';

  @override
  String get paymentMethodLabel => 'Payment Method';

  @override
  String get cashPayment => 'Cash';

  @override
  String get creditCardPayment => 'Credit Card';

  @override
  String get bankTransferPayment => 'Bank Transfer';

  @override
  String get filterAll => 'All';

  @override
  String get filterAllCategories => 'All Categories';

  @override
  String get filterEmployee => 'Employee:';

  @override
  String get noExpensesFound => 'No expenses recorded';

  @override
  String get noExpensesAdmin => 'No expenses match the filter';

  @override
  String get searchHint => 'Search in expenses...';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get employeesTitle => 'Employee Management';

  @override
  String get addUserButton => 'Add User';

  @override
  String get addUserTitle => 'Add New User';

  @override
  String get userRoleLabel => 'Role';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Deactivated';

  @override
  String get statusPending => 'Pending Approval';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get deactivateUser => 'Deactivate Account';

  @override
  String get reactivateUser => 'Activate Account';

  @override
  String get changeRole => 'Change Role';

  @override
  String get makeAdmin => 'Promote to Admin';

  @override
  String get makeEmployee => 'Demote to Employee';

  @override
  String get deleteUser => 'Delete Account';

  @override
  String get deleteUserConfirmTitle => 'Delete User';

  @override
  String get deleteUserConfirmMessage =>
      'Are you sure you want to permanently delete this user? This will remove their user account and associated profile.';

  @override
  String get deactivateUserConfirmTitle => 'Deactivate User';

  @override
  String get deactivateUserConfirmMessage =>
      'Are you sure you want to deactivate this user? They will not be able to log in, but all historical expenses will be preserved.';

  @override
  String get reactivateUserConfirmTitle => 'Activate User';

  @override
  String get reactivateUserConfirmMessage =>
      'Do you want to reactivate this user\'s access to the application?';

  @override
  String get cannotDeactivateSelf => 'You cannot deactivate your own account.';

  @override
  String get cannotDeleteSelf => 'You cannot delete your own account.';

  @override
  String get cannotDemoteLastAdmin =>
      'You cannot demote the last remaining administrator.';

  @override
  String get cannotDeactivateLastAdmin =>
      'You cannot deactivate the last active administrator.';

  @override
  String get userCreatedSuccess => 'User created successfully';

  @override
  String get userDeletedSuccess => 'User deleted successfully';

  @override
  String get userRoleUpdatedSuccess => 'Role updated successfully';

  @override
  String get userStatusUpdatedSuccess => 'Account status updated successfully';

  @override
  String get accountInactiveError =>
      'This account is deactivated. Please contact an administrator.';

  @override
  String get allRoles => 'All Roles';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get teamAndExpenses => 'Team & Expenses';

  @override
  String get registeredUsersCount => 'registered users';

  @override
  String get teamTotalSpent => 'Team Total Spent';

  @override
  String get totalOperations => 'Total Operations';

  @override
  String get searchEmployeeHint => 'Search users by name or email...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get employeeDetailsTitle => 'Employee Details';

  @override
  String get employeeExpensesTitle => 'Employee Expenses';

  @override
  String get totalExpensesLabel => 'Total Expenses';

  @override
  String get expensesCountLabel => 'Number of Expenses';

  @override
  String get thisMonthExpensesLabel => 'This Month';

  @override
  String get todayExpensesLabel => 'Today\'s Expenses';

  @override
  String get viewExpenses => 'View Expenses';

  @override
  String get noExpensesForEmployee => 'No expenses recorded for this employee';

  @override
  String get filterAllPaymentMethods => 'All Payment Methods';

  @override
  String get resetFilters => 'Reset Filters';

  @override
  String get filterByDate => 'Date Range';

  @override
  String get allTime => 'All Time';

  @override
  String get requireAdminApproval => 'Require admin approval for new users';

  @override
  String get requireAdminApprovalDesc =>
      'When enabled, newly registered users cannot access the app until approved by an administrator.';

  @override
  String get adminApprovalSettingUpdated =>
      'Approval setting updated successfully';

  @override
  String get adminSettingsSection => 'Admin Settings';

  @override
  String get pendingApprovalTitle => 'Account Pending Approval';

  @override
  String get pendingApprovalMessage =>
      'Your account is waiting for administrator approval. You will be able to access Spendly once an administrator approves your registration request.';

  @override
  String get rejectedAccountTitle => 'Registration Request Rejected';

  @override
  String get rejectedAccountMessage =>
      'Your registration request was not approved by an administrator. Please contact your organization administrator if you think this is a mistake.';

  @override
  String get checkStatusButton => 'Check Status';

  @override
  String get statusStillPending =>
      'Your account is still waiting for administrator approval.';

  @override
  String get pendingRequestsTitle => 'Pending Registrations';

  @override
  String get pendingRequestsBadge => 'Pending Requests';

  @override
  String get approveUser => 'Approve';

  @override
  String get rejectUser => 'Reject';

  @override
  String get approveUserConfirmTitle => 'Approve User';

  @override
  String get approveUserConfirmMessage =>
      'Are you sure you want to approve this user and grant them access to the application?';

  @override
  String get rejectUserConfirmTitle => 'Reject Registration Request';

  @override
  String get rejectUserConfirmMessage =>
      'Are you sure you want to reject this registration request?';

  @override
  String get userApprovedSuccess => 'User approved successfully';

  @override
  String get userRejectedSuccess => 'User registration request rejected';

  @override
  String get noPendingRequests => 'No pending registration requests';

  @override
  String get notificationsTitle => 'Admin Notifications';

  @override
  String get markAllAsRead => 'Mark All as Read';

  @override
  String get noNotifications => 'No new notifications';

  @override
  String get newRegistrationNotification => 'New Registration Request';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusPending => 'Saved locally';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String get syncStatusFailed => 'Sync failed - Tap to retry';

  @override
  String get expenseSavedOffline =>
      'Expense saved locally. It will sync automatically when internet is available.';

  @override
  String get expenseSyncRetrying => 'Retrying expense sync...';

  @override
  String get expenseSyncSuccess =>
      'All local expenses have been synchronized successfully.';

  @override
  String get retrySync => 'Retry Sync';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get periodToday => 'Today';

  @override
  String get periodThisWeek => 'This Week';

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get totalMonthlyExpenses => 'Total Expenses';

  @override
  String get companyTotalExpenses => 'Total Company Expenses';

  @override
  String get employeeTotalExpenses => 'My Total Expenses';

  @override
  String get distributionByCategory => 'Spending by Category';

  @override
  String get distributionByEmployee => 'Spending by Employee';

  @override
  String get recentExpenses => 'Recent Expenses';

  @override
  String get viewAll => 'View All';

  @override
  String get viewReports => 'View Reports';

  @override
  String get noExpensesThisPeriod => 'No expenses recorded for this period';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get totalReceived => 'Total Received';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get addBalance => 'Add Balance';

  @override
  String get addBalanceTitle => 'Add Employee Balance';

  @override
  String get addBalanceSubtitle => 'Add funds to employee\'s available balance';

  @override
  String get amountMustBeGreaterThanZero => 'Amount must be greater than zero.';

  @override
  String get balanceAddedSuccess => 'Balance added successfully';

  @override
  String get insufficientBalance =>
      'Insufficient available balance for this expense.';

  @override
  String get expenseExceededBalanceWarning =>
      'Expense recorded successfully, but it exceeded the available balance.';

  @override
  String availableBalanceBefore(String balance) {
    return 'Available balance: $balance';
  }

  @override
  String expenseAmountLabelValue(String amount) {
    return 'Expense: $amount';
  }

  @override
  String balanceAfterExpense(String remaining) {
    return 'Balance after expense: $remaining';
  }

  @override
  String get noAvailableBalance => 'No available balance.';

  @override
  String get transactionHistory => 'Transaction & Allowance History';

  @override
  String get employeeBalances => 'Employee Balances';

  @override
  String get remainingBalance => 'Remaining';

  @override
  String get givenAmount => 'Given';

  @override
  String get spentAmount => 'Spent';

  @override
  String get allowanceDate => 'Allowance Date';

  @override
  String get allowanceNote => 'Note (optional)';

  @override
  String get allowanceNoteHint => 'e.g., Weekly allowance / Office expenses';

  @override
  String get creditTransaction => 'Credit (Add)';

  @override
  String get expenseTransaction => 'Expense';

  @override
  String get adjustmentAddTransaction => 'Adjustment (Add)';

  @override
  String get adjustmentSubTransaction => 'Adjustment (Deduct)';

  @override
  String get confirmAddBalance => 'Confirm Add Balance';

  @override
  String get noTransactionsYet => 'No transactions recorded yet';

  @override
  String get expenseUpdatedSuccess => 'Expense updated successfully';

  @override
  String get expenseAddedSuccess => 'Expense added successfully';

  @override
  String get receiptPhotoLabel => 'Receipt / Invoice Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Additional notes...';

  @override
  String get filterDateRange => 'Custom Date Range';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get currencyEgp => 'Egyptian Pound (EGP)';

  @override
  String get currencyUsd => 'US Dollar (USD)';

  @override
  String get currencyEgpShort => 'EGP';

  @override
  String get currencyUsdShort => 'USD';

  @override
  String get availableBalanceEgp => 'Available Balance (EGP)';

  @override
  String get availableBalanceUsd => 'Available Balance (USD)';

  @override
  String get totalReceivedEgp => 'Received (EGP)';

  @override
  String get totalReceivedUsd => 'Received (USD)';

  @override
  String get totalSpentEgp => 'Spent (EGP)';

  @override
  String get totalSpentUsd => 'Spent (USD)';

  @override
  String get tripLocationLabel => 'Trip Location';

  @override
  String get insideCairo => 'Inside Cairo';

  @override
  String get outsideCairo => 'Outside Cairo';

  @override
  String get governorateLabel => 'Governorate';

  @override
  String get selectGovernorate => 'Select Governorate';

  @override
  String get governorateRequired =>
      'Governorate is required for trips outside Cairo.';

  @override
  String get travelStatistics => 'Travel & Trip Statistics';

  @override
  String get totalTrips => 'Total Trips';

  @override
  String get insideCairoTrips => 'Inside Cairo Trips';

  @override
  String get outsideCairoTrips => 'Outside Cairo Trips';

  @override
  String get governorateBreakdown => 'Governorate Breakdown';

  @override
  String get travelBonus => 'Travel Bonus';

  @override
  String get travelBonusSettings => 'Travel Bonus Settings';

  @override
  String get travelBonusSettingsDesc =>
      'Configure bonus for employee trips outside Cairo';

  @override
  String get bonusPerTrip => 'Bonus per Trip';

  @override
  String get potentialBonus => 'Potential Bonus';

  @override
  String get travelActivity => 'Travel Activity';

  @override
  String get topTraveler => 'Top Outside-Cairo Traveler';

  @override
  String get tripsCountUnit => 'trips';

  @override
  String get noTravelActivity => 'No travel activity recorded for this period';

  @override
  String get salary => 'Salary';

  @override
  String get monthlySalary => 'Monthly Salary';

  @override
  String get salaryAdvance => 'Salary Advance';

  @override
  String get salaryAdvances => 'Salary Advances';

  @override
  String get totalAdvances => 'Total Advances';

  @override
  String get remainingSalary => 'Remaining Salary';

  @override
  String get addSalaryAdvance => 'Add Advance';

  @override
  String get editSalaryAdvance => 'Edit Advance';

  @override
  String get deleteSalaryAdvance => 'Delete Advance';

  @override
  String get deleteSalaryAdvanceConfirm =>
      'Are you sure you want to delete this salary advance?';

  @override
  String get advanceDate => 'Advance Date';

  @override
  String get advanceReason => 'Reason';

  @override
  String get advanceReasonHint => 'e.g., Emergency, Personal expense...';

  @override
  String get editSalary => 'Edit Salary';

  @override
  String get salaryAmount => 'Salary Amount';

  @override
  String get salaryUpdatedSuccess => 'Employee salary updated successfully';

  @override
  String get advanceAddedSuccess => 'Salary advance recorded successfully';

  @override
  String get advanceUpdatedSuccess => 'Salary advance updated successfully';

  @override
  String get advanceDeletedSuccess => 'Salary advance deleted successfully';

  @override
  String get salariesOverview => 'Salaries & Advances Overview';

  @override
  String get totalSalaries => 'Total Salaries';

  @override
  String get totalRemainingSalaries => 'Total Remaining';

  @override
  String get noSalaryAdvancesYet => 'No salary advances recorded yet';

  @override
  String get advanceCreatedBy => 'Recorded by';

  @override
  String get weeklyWorkBudget => 'Weekly Work Budget';

  @override
  String get weeklyAllowance => 'Weekly Allowance';

  @override
  String get workAllowance => 'Work Allowance';

  @override
  String get receivedThisWeek => 'Received This Week';

  @override
  String get spentThisWeek => 'Spent This Week';

  @override
  String get remainingThisWeek => 'Remaining This Week';

  @override
  String get addAllowance => 'Add Allowance';

  @override
  String get editAllowance => 'Edit Allowance';

  @override
  String get deleteAllowance => 'Delete Allowance';

  @override
  String get deleteAllowanceConfirm =>
      'Are you sure you want to delete this allowance transaction?';

  @override
  String get allowanceDateLabel => 'Allowance Date';

  @override
  String get allowanceReasonLabel => 'Reason';

  @override
  String get allowanceReasonHint =>
      'e.g., Weekly work budget, Project expenses...';

  @override
  String get thisWeek => 'This Week';

  @override
  String get previousWeek => 'Previous Week';

  @override
  String get nextWeek => 'Next Week';

  @override
  String get totalReceivedWeekly => 'Total Received';

  @override
  String get totalSpentWeekly => 'Total Spent';

  @override
  String get totalRemainingWeekly => 'Total Remaining';

  @override
  String get allowanceAddedSuccess => 'Work allowance recorded successfully';

  @override
  String get allowanceUpdatedSuccess => 'Work allowance updated successfully';

  @override
  String get allowanceDeletedSuccess => 'Work allowance deleted successfully';

  @override
  String get noAllowanceTransactionsYet =>
      'No allowance transactions recorded for this period';

  @override
  String get weeklyAllowanceTransactions => 'Allowance Transactions';
}
