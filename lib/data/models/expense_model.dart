import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/trip_location_type.dart';
import 'category_model.dart';
import 'profile_model.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.userId,
    super.categoryId,
    super.category,
    super.profile,
    super.title = '',
    required super.amount,
    super.currency = ExpenseCurrency.egp,
    super.tripLocationType = TripLocationType.cairo,
    super.governorate = Governorate.cairo,
    required super.paymentMethod,
    required super.expenseDate,
    super.notes,
    super.receiptUrl,
    super.syncStatus = SyncStatus.synced,
    super.createdAt,
    super.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    if (json['categories'] != null && json['categories'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['categories'] as Map<String, dynamic>);
    }

    ProfileModel? prof;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      prof = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    final rawAmount = json['amount'];
    final double parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    final rawSync = json['sync_status'] as String?;
    final syncStatus = SyncStatus.fromString(rawSync);

    final rawCurrency = json['currency'] as String?;
    final currency = ExpenseCurrency.fromString(rawCurrency);

    final rawTripLocation = json['trip_location_type'] as String?;
    final tripLocationType = TripLocationType.fromString(rawTripLocation);

    final rawGovernorate = json['governorate'] as String?;
    final governorate = Governorate.fromString(rawGovernorate);

    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      category: cat,
      profile: prof,
      title: json['title'] as String? ?? json['description'] as String? ?? '',
      amount: parsedAmount,
      currency: currency,
      tripLocationType: tripLocationType,
      governorate: tripLocationType == TripLocationType.cairo ? Governorate.cairo : governorate,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? json['description'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      syncStatus: syncStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
    );
  }

  /// JSON payload for Supabase INSERT / UPSERT
  Map<String, dynamic> toJson({bool includeId = true}) {
    final effectiveGov = tripLocationType == TripLocationType.cairo
        ? Governorate.cairo
        : governorate;

    return {
      if (includeId) 'id': id,
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      'description': (notes != null && notes!.isNotEmpty) ? notes : title,
      'amount': amount,
      'currency': currency.toDbString(),
      'trip_location_type': tripLocationType.toDbString(),
      'governorate': effectiveGov.toDbString(),
      'payment_method': paymentMethod,
      'expense_date':
          '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      if (notes != null) 'notes': notes,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
    };
  }

  /// Full JSON serialization for local persistent queue
  Map<String, dynamic> toLocalJson() {
    final effectiveGov = tripLocationType == TripLocationType.cairo
        ? Governorate.cairo
        : governorate;

    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      if (category != null)
        'categories': (category is CategoryModel)
            ? (category as CategoryModel).toJson()
            : {
                'id': category!.id,
                'name': category!.name,
                'icon': category!.icon,
                'color': category!.color,
              },
      if (profile != null)
        'profiles': (profile is ProfileModel)
            ? (profile as ProfileModel).toJson()
            : {
                'id': profile!.id,
                'full_name': profile!.name,
                'email': profile!.email,
                'role': profile!.role,
                'status': profile!.status,
              },
      'title': title,
      'amount': amount,
      'currency': currency.toDbString(),
      'trip_location_type': tripLocationType.toDbString(),
      'governorate': effectiveGov.toDbString(),
      'payment_method': paymentMethod,
      'expense_date':
          '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      'notes': notes,
      'receipt_url': receiptUrl,
      'sync_status': syncStatus.value,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      categoryId: expense.categoryId,
      category: expense.category,
      profile: expense.profile,
      title: expense.title,
      amount: expense.amount,
      currency: expense.currency,
      tripLocationType: expense.tripLocationType,
      governorate: expense.governorate,
      paymentMethod: expense.paymentMethod,
      expenseDate: expense.expenseDate,
      notes: expense.notes,
      receiptUrl: expense.receiptUrl,
      syncStatus: expense.syncStatus,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
