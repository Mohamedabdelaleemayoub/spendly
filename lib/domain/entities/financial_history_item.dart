import 'package:equatable/equatable.dart';
import 'balance_transaction.dart';
import 'expense.dart';
import 'expense_currency.dart';

enum FinancialItemType {
  credit,
  expense,
  adjustmentAdd,
  adjustmentSub,
}

class FinancialHistoryItem extends Equatable {
  const FinancialHistoryItem({
    required this.id,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.itemType,
    required this.date,
    required this.title,
    this.subtitle,
    this.note,
    this.balanceTransaction,
    this.expense,
  });

  final String id;
  final double amount;
  final ExpenseCurrency currency;
  final FinancialItemType itemType;
  final DateTime date;
  final String title;
  final String? subtitle;
  final String? note;
  final BalanceTransaction? balanceTransaction;
  final Expense? expense;

  bool get isPositive => itemType == FinancialItemType.credit || itemType == FinancialItemType.adjustmentAdd;

  factory FinancialHistoryItem.fromBalanceTransaction(BalanceTransaction tx) {
    String title = 'إضافة رصيد';
    FinancialItemType type = FinancialItemType.credit;
    if (tx.type == BalanceTransactionType.adjustmentAdd) {
      title = 'تسوية رصيد (إضافة)';
      type = FinancialItemType.adjustmentAdd;
    } else if (tx.type == BalanceTransactionType.adjustmentSub) {
      title = 'تسوية رصيد (خصم)';
      type = FinancialItemType.adjustmentSub;
    }

    return FinancialHistoryItem(
      id: tx.id,
      amount: tx.amount,
      currency: tx.currency,
      itemType: type,
      date: tx.transactionDate,
      title: title,
      subtitle: tx.creatorProfile?.name != null ? 'بواسطة ${tx.creatorProfile!.name}' : null,
      note: tx.note,
      balanceTransaction: tx,
    );
  }

  factory FinancialHistoryItem.fromExpense(Expense exp) {
    return FinancialHistoryItem(
      id: exp.id,
      amount: exp.amount,
      currency: exp.currency,
      itemType: FinancialItemType.expense,
      date: exp.expenseDate,
      title: exp.displayTitle,
      subtitle: exp.category?.name,
      note: exp.notes,
      expense: exp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        itemType,
        date,
        title,
        subtitle,
        note,
        balanceTransaction,
        expense,
      ];
}
