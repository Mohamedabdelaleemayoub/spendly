import 'package:equatable/equatable.dart';
import 'category.dart';
import 'profile.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    this.category,
    this.profile,
    required this.title,
    required this.amount,
    required this.paymentMethod,
    required this.expenseDate,
    this.notes,
    this.receiptUrl,
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
  final String paymentMethod;
  final DateTime expenseDate;
  final String? notes;
  final String? receiptUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    Category? category,
    Profile? profile,
    String? title,
    double? amount,
    String? paymentMethod,
    DateTime? expenseDate,
    String? notes,
    String? receiptUrl,
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
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
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
        paymentMethod,
        expenseDate,
        notes,
        receiptUrl,
        createdAt,
        updatedAt,
      ];
}
