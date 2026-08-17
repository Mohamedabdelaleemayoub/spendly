/// Represents user roles in Spendly.
///
/// Exactly two roles exist:
/// - [admin]: Company administrator with company-wide visibility and category/employee management.
/// - [employee]: Regular employee with access limited strictly to their own expenses and reports.
enum UserRole {
  admin('admin', 'مدير النظام'),
  employee('employee', 'موظف');

  const UserRole(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.employee;
    final normalized = role.trim().toLowerCase();
    if (normalized == 'admin') return UserRole.admin;
    return UserRole.employee;
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isEmployee => this == UserRole.employee;
}
