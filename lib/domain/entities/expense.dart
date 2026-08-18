import 'package:equatable/equatable.dart';
import 'category.dart';
import 'expense_currency.dart';
import 'governorate.dart';
import 'profile.dart';
import 'trip_location_type.dart';

/// Represents synchronization status of an expense record.
enum SyncStatus {
  synced('synced'),
  pending('pending'),
  syncing('syncing'),
  failed('failed');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromString(String? val) {
    if (val == null) return SyncStatus.synced;
    final normalized = val.trim().toLowerCase();
    for (final s in SyncStatus.values) {
      if (s.value == normalized) return s;
    }
    return SyncStatus.synced;
  }

  bool get isSynced => this == SyncStatus.synced;
  bool get isPending => this == SyncStatus.pending;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isFailed => this == SyncStatus.failed;
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    this.category,
    this.profile,
    this.title = '',
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    this.tripLocationType = TripLocationType.cairo,
    this.governorate = Governorate.cairo,
    required this.paymentMethod,
    required this.expenseDate,
    this.notes,
    this.receiptUrl,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? categoryId;
  final Category? category;
  final Profile? profile;
  final String title;
  final double amount;
  final ExpenseCurrency currency;
  final TripLocationType tripLocationType;
  final Governorate governorate;
  final String paymentMethod;
  final DateTime expenseDate;
  final String? notes;
  final String? receiptUrl;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOutsideCairo => tripLocationType == TripLocationType.outsideCairo;

  /// Returns the title if non-empty, otherwise falls back to category name or generic label.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (category != null && category!.name.trim().isNotEmpty) return category!.name.trim();
    if (notes != null && notes!.trim().isNotEmpty) return notes!.trim();
    return 'مصروف';
  }

  bool get isSynced => syncStatus.isSynced;
  bool get isPending => syncStatus.isPending;
  bool get isSyncing => syncStatus.isSyncing;
  bool get isFailed => syncStatus.isFailed;

  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    Category? category,
    Profile? profile,
    String? title,
    double? amount,
    ExpenseCurrency? currency,
    TripLocationType? tripLocationType,
    Governorate? governorate,
    String? paymentMethod,
    DateTime? expenseDate,
    String? notes,
    String? receiptUrl,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      profile: profile ?? this.profile,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      tripLocationType: tripLocationType ?? this.tripLocationType,
      governorate: governorate ?? this.governorate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        category,
        profile,
        title,
        amount,
        currency,
        tripLocationType,
        governorate,
        paymentMethod,
        expenseDate,
        notes,
        receiptUrl,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
