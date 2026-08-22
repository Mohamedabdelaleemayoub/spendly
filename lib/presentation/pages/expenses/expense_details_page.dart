import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/expense.dart';
import '../../../injection/injection_container.dart';
import '../../../router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/expense/expense_cubit.dart';
import '../../cubits/expense/expense_state.dart';
import '../../../core/utils/responsive.dart';

class ExpenseDetailsPage extends StatelessWidget {
  const ExpenseDetailsPage({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ExpenseCubit>()..getExpenseDetails(expenseId),
      child: _ExpenseDetailsView(expenseId: expenseId),
    );
  }
}

class _ExpenseDetailsView extends StatelessWidget {
  const _ExpenseDetailsView({required this.expenseId});

  final String expenseId;

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return AppColors.primary;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    final cubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: Text('هل أنت متأكد من حذف "${expense.title}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await cubit.deleteExpense(expense.id);
              if (success && context.mounted) {
                context.pop();
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ', decimalDigits: 2);
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    final authState = sl<AuthCubit>().state;
    final bool isAdmin = (authState is Authenticated) && authState.isAdmin;
    final String? currentUserId = authState is Authenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المصروف'),
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Expense? expense;
          if (state is ExpenseSingleLoaded) {
            expense = state.expense;
          } else if (state is ExpenseLoaded) {
            expense = state.expenses.cast<Expense?>().firstWhere(
                  (e) => e?.id == expenseId,
                  orElse: () => null,
                );
          }

          if (expense == null) {
            return const Center(
              child: Text(
                'لم يتم العثور على بيانات المصروف',
                style: AppTextStyles.subtitle1,
              ),
            );
          }

          final catColor = _parseColor(expense.category?.color);
          final paymentLabel = AppConstants.paymentMethodLabels[expense.paymentMethod] ??
              expense.paymentMethod;
          final bool isOwner = currentUserId != null && expense.userId == currentUserId;

          return ResponsiveContentContainer(
            maxWidth: Breakpoints.maxFormWidth,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
              // Header Card with Amount
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        expense.title,
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormat.format(expense.amount),
                        style: AppTextStyles.amountLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          if (expense.category != null)
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: catColor,
                                radius: 6,
                              ),
                              label: Text(expense.category!.name),
                              backgroundColor: catColor.withValues(alpha: 0.12),
                            ),
                          Chip(
                            avatar: const Icon(Icons.payment, size: 16),
                            label: Text(paymentLabel),
                          ),
                          if (isAdmin && expense.profile != null)
                            Chip(
                              avatar: const Icon(Icons.person, size: 16),
                              label: Text('الموظف: ${expense.profile!.name}'),
                              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Details List Card
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (isAdmin && expense.profile != null) ...[
                      ListTile(
                        leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        title: const Text('الموظف صاحب المصروف', style: AppTextStyles.caption),
                        subtitle: Text(
                          '${expense.profile!.name} (${expense.profile!.email ?? "بدون بريد"})',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                      title: const Text('تاريخ الصرف', style: AppTextStyles.caption),
                      subtitle: Text(
                        dateFormat.format(expense.expenseDate),
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
                      title: const Text('طريقة الدفع', style: AppTextStyles.caption),
                      subtitle: Text(
                        paymentLabel,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notes_outlined, color: AppColors.primary),
                        title: const Text('ملاحظات', style: AppTextStyles.caption),
                        subtitle: Text(
                          expense.notes!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Image Preview
              if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty) ...[
                const Text('صورة الفاتورة / الإيصال', style: AppTextStyles.label),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    expense.receiptUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (ctx, _, _) => Container(
                      height: 120,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Text('تعذر تحميل صورة الفاتورة'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons (Edit / Delete) - ONLY shown for the expense owner
              if (isOwner) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('تعديل'),
                        onPressed: () async {
                          await context.push(
                            AppRoutes.addExpense,
                            extra: expense,
                          );
                          if (context.mounted) {
                            context.read<ExpenseCubit>().getExpenseDetails(expenseId);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('حذف'),
                        onPressed: () => _confirmDelete(context, expense!),
                      ),
                    ),
                  ],
                ),
              ] else if (isAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'عرض فقط: لا يمكن تعديل أو حذف مصروفات الموظفين',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
}
