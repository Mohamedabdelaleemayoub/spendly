import '../../domain/entities/expense.dart';
import 'category_model.dart';
import 'profile_model.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.userId,
    super.categoryId,
    super.category,
    super.profile,
    required super.title,
    required super.amount,
    required super.paymentMethod,
    required super.expenseDate,
    super.notes,
    super.receiptUrl,
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

    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      category: cat,
      profile: prof,
      title: json['title'] as String? ?? json['description'] as String? ?? '',
      amount: parsedAmount,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? json['description'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      'description': notes ?? title,
      'amount': amount,
      'payment_method': paymentMethod,
      'expense_date':
          '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      if (notes != null) 'notes': notes,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
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
      paymentMethod: expense.paymentMethod,
      expenseDate: expense.expenseDate,
      notes: expense.notes,
      receiptUrl: expense.receiptUrl,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
