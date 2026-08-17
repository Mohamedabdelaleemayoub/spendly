/// Application-wide constants.
///
/// Centralises magic strings so they are defined once and can be
/// refactored safely.
abstract final class AppConstants {
  // ── Supabase Table Names ───────────────────────────────────────────
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String expensesTable = 'expenses';

  // ── Supabase Storage ───────────────────────────────────────────────
  static const String receiptsBucket = 'expense-receipts';
  static const String profileImagesBucket = 'avatars';

  // ── Pagination ─────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ── Roles ──────────────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';

  // ── Payment Methods ────────────────────────────────────────────────
  static const String paymentCash = 'cash';
  static const String paymentBank = 'bank';
  static const String paymentWallet = 'wallet';
  static const String paymentTransfer = 'transfer';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentBank,
    paymentWallet,
    paymentTransfer,
  ];

  // ── Payment Method Labels (Arabic) ─────────────────────────────────
  static const Map<String, String> paymentMethodLabels = {
    paymentCash: 'نقدي',
    paymentBank: 'بنك',
    paymentWallet: 'محفظة',
    paymentTransfer: 'تحويل',
  };

  // ── Signed URL Duration ────────────────────────────────────────────
  static const int signedUrlDurationSeconds = 3600; // 1 hour
}
