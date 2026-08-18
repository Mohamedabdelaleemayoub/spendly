import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/employees/employees_cubit.dart';
import '../../cubits/employees/employees_state.dart';
import '../../cubits/expense/expense_cubit.dart';
import '../../cubits/expense/expense_state.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ExpenseCubit>()..loadExpenses(),
        ),
        BlocProvider(
          create: (context) => sl<CategoryCubit>()..loadCategories(),
        ),
        BlocProvider(
          create: (context) => sl<EmployeesCubit>()..loadEmployees(),
        ),
      ],
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatefulWidget {
  const _ExpensesView();

  @override
  State<_ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<_ExpensesView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedEmployeeId;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ExpenseCubit>().loadExpenses();
    }
  }

  void _refreshList() {
    context.read<ExpenseCubit>().loadExpenses(
          refresh: true,
          categoryId: _selectedCategory,
          userId: _selectedEmployeeId,
          searchQuery: _searchController.text.trim().isNotEmpty
              ? _searchController.text.trim()
              : null,
        );
  }

  String _formatPaymentMethod(String method) {
    return AppConstants.paymentMethodLabels[method] ?? method;
  }

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
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ExpenseCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteExpenseTitle),
        content: Text('${l10n.deleteExpenseConfirm} ("${expense.displayTitle}")'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.deleteExpense(expense.id);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(BuildContext context, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    if (expense.isSynced) return const SizedBox.shrink();

    Color bgColor;
    Color fgColor;
    IconData icon;
    String label;

    if (expense.isSyncing) {
      bgColor = Colors.blue.shade50;
      fgColor = Colors.blue.shade700;
      icon = Icons.sync;
      label = l10n.syncStatusSyncing;
    } else if (expense.isFailed) {
      bgColor = Colors.red.shade50;
      fgColor = Colors.red.shade700;
      icon = Icons.sync_problem;
      label = l10n.syncStatusFailed;
    } else {
      // Pending
      bgColor = Colors.amber.shade50;
      fgColor = Colors.amber.shade800;
      icon = Icons.cloud_queue_outlined;
      label = l10n.syncStatusPending;
    }

    return InkWell(
      onTap: () {
        context.read<ExpenseCubit>().retrySync();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fgColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy/MM/dd');

    final authState = sl<AuthCubit>().state;
    final bool isAdmin = (authState is Authenticated) && authState.isAdmin;
    final String? currentUserId = authState is Authenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? l10n.navAllExpenses : l10n.navExpenses),
        actions: [
          IconButton(
            tooltip: l10n.retrySync,
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<ExpenseCubit>().retrySync();
            },
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _refreshList();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.addExpense);
          if (context.mounted) {
            _refreshList();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpenseTitle),
      ),
      body: Column(
        children: [
          // Search Field (if enabled)
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _refreshList();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _refreshList(),
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),

          // Admin Employee Filter Chips
          if (isAdmin)
            BlocBuilder<EmployeesCubit, EmployeesState>(
              builder: (context, empState) {
                if (empState is! EmployeesLoaded || empState.employees.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        l10n.filterEmployee,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l10n.filterAll),
                        selected: _selectedEmployeeId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedEmployeeId = null);
                            _refreshList();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ...empState.employees.map((emp) {
                        final isSelected = _selectedEmployeeId == emp.profile.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(emp.profile.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedEmployeeId = selected ? emp.profile.id : null;
                              });
                              _refreshList();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

          // Category Filter Chips
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, catState) {
              final categories = context.read<CategoryCubit>().categories;
              if (categories.isEmpty) return const SizedBox.shrink();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.filterAllCategories),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = null);
                        _refreshList();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((Category cat) {
                      final isSelected = _selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? cat.id : null;
                            });
                            _refreshList();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // Expenses List
          Expanded(
            child: BlocConsumer<ExpenseCubit, ExpenseState>(
              listener: (context, state) {
                if (state is ExpenseActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else if (state is ExpenseError) {
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

                if (state is ExpenseLoaded) {
                  final expenses = state.expenses;

                  if (expenses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAdmin ? l10n.noExpensesAdmin : l10n.noExpensesFound,
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAdmin ? l10n.resetFilters : l10n.expenseSavedOffline,
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context.push(AppRoutes.addExpense);
                              if (context.mounted) {
                                _refreshList();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addExpenseTitle),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _refreshList();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 80,
                      ),
                      itemCount: expenses.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == expenses.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final expense = expenses[index];
                        final catColor = _parseColor(expense.category?.color);
                        final bool isOwner = currentUserId != null && expense.userId == currentUserId;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await context.push('/expenses/${expense.id}');
                              if (context.mounted) {
                                _refreshList();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Category color tag
                                  Container(
                                    width: 4,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                expense.displayTitle,
                                                style: AppTextStyles.subtitle1.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isAdmin && expense.profile != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                constraints: const BoxConstraints(maxWidth: 90),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  expense.profile!.name,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              if (expense.category != null) ...[
                                                TextSpan(
                                                  text: expense.category!.name,
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: catColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: ' • ',
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                              TextSpan(
                                                text: dateFormat.format(expense.expenseDate),
                                                style: AppTextStyles.caption,
                                              ),
                                              const TextSpan(
                                                text: ' • ',
                                                style: AppTextStyles.caption,
                                              ),
                                              TextSpan(
                                                text: _formatPaymentMethod(expense.paymentMethod),
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Sync status indicator
                                        _buildSyncStatusBadge(context, expense),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(expense.amount),
                                        style: AppTextStyles.amount.copyWith(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                      ),
                                      if (expense.receiptUrl != null) ...[
                                        const SizedBox(height: 2),
                                        const Icon(
                                          Icons.attachment,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Delete button ONLY for owner
                                  if (isOwner) ...[
                                    const SizedBox(width: 2),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () => _confirmDelete(context, expense),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
