import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/profile.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/employee_details/employee_details_cubit.dart';
import '../../cubits/employee_details/employee_details_state.dart';

class EmployeeDetailsPage extends StatelessWidget {
  const EmployeeDetailsPage({
    super.key,
    required this.employeeId,
    this.initialProfile,
  });

  final String employeeId;
  final Profile? initialProfile;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<EmployeeDetailsCubit>()
            ..loadEmployeeDetails(employeeId, initialProfile: initialProfile),
        ),
        BlocProvider(
          create: (context) => sl<CategoryCubit>()..loadCategories(),
        ),
      ],
      child: _EmployeeDetailsView(employeeId: employeeId),
    );
  }
}

class _EmployeeDetailsView extends StatefulWidget {
  const _EmployeeDetailsView({required this.employeeId});

  final String employeeId;

  @override
  State<_EmployeeDetailsView> createState() => _EmployeeDetailsViewState();
}

class _EmployeeDetailsViewState extends State<_EmployeeDetailsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final cubit = context.read<EmployeeDetailsCubit>();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );

    if (picked != null) {
      cubit.filterByDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employeeDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              context
                  .read<EmployeeDetailsCubit>()
                  .loadEmployeeDetails(widget.employeeId);
            },
          ),
        ],
      ),
      body: BlocConsumer<EmployeeDetailsCubit, EmployeeDetailsState>(
        listener: (context, state) {
          if (state is EmployeeDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmployeeDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmployeeDetailsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: AppTextStyles.subtitle1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<EmployeeDetailsCubit>()
                          .loadEmployeeDetails(widget.employeeId),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is EmployeeDetailsLoaded) {
            final profile = state.profile;
            final isAdmin = profile.isAdmin;
            final isActive = profile.isActive;
            final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
            final expenses = state.expenses;

            return RefreshIndicator(
              onRefresh: () async {
                _searchController.clear();
                await context
                    .read<EmployeeDetailsCubit>()
                    .loadEmployeeDetails(widget.employeeId);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Employee Header Card
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isAdmin
                                ? AppColors.secondary.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: hasAvatar
                                ? CachedNetworkImageProvider(profile.avatarUrl!)
                                : null,
                            child: !hasAvatar
                                ? Text(
                                    profile.name.isNotEmpty
                                        ? profile.name.characters.first.toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                          ? AppColors.secondaryDark
                                          : AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.name,
                                        style: AppTextStyles.heading3,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (profile.email != null && profile.email!.isNotEmpty)
                                  Text(
                                    profile.email!,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.success.withValues(alpha: 0.15)
                                            : AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isActive ? l10n.statusActive : l10n.statusInactive,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Role Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? AppColors.secondary.withValues(alpha: 0.15)
                                            : AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAdmin ? l10n.roleAdmin : l10n.roleEmployee,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? AppColors.secondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (profile.createdAt != null)
                                      Text(
                                        '${l10n.joinedDateLabel}: ${dateFormat.format(profile.createdAt!)}',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Statistics Grid (4 Cards)
                  Row(
                    children: [
                      // Total Expenses
                      Expanded(
                        child: _StatCard(
                          title: l10n.totalExpensesLabel,
                          value: currencyFormat.format(state.totalExpenses),
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Number of Expenses
                      Expanded(
                        child: _StatCard(
                          title: l10n.expensesCountLabel,
                          value: '${state.expensesCount}',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF6C5CE7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // This Month
                      Expanded(
                        child: _StatCard(
                          title: l10n.thisMonthExpensesLabel,
                          value: currencyFormat.format(state.thisMonthExpenses),
                          icon: Icons.calendar_month_outlined,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Today's Expenses
                      Expanded(
                        child: _StatCard(
                          title: l10n.todayExpensesLabel,
                          value: currencyFormat.format(state.todayExpenses),
                          icon: Icons.today_outlined,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.employeeExpensesTitle,
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                      if (state.hasActiveFilters)
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            context.read<EmployeeDetailsCubit>().resetFilters();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(l10n.resetFilters),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Search and Filter Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<EmployeeDetailsCubit>()
                                    .searchExpenses('');
                              },
                            )
                          : null,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      context.read<EmployeeDetailsCubit>().searchExpenses(val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips (Categories & Payment Methods & Date)
                  BlocBuilder<CategoryCubit, CategoryState>(
                    builder: (catContext, catState) {
                      final categories = catState is CategoryLoaded
                          ? catState.categories
                          : [];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Date Range Filter Chip
                            ActionChip(
                              avatar: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                state.selectedStartDate != null
                                    ? '${dateFormat.format(state.selectedStartDate!)} - ${dateFormat.format(state.selectedEndDate!)}'
                                    : l10n.filterByDate,
                              ),
                              onPressed: () => _pickDateRange(context),
                            ),
                            const SizedBox(width: 8),

                            // Payment Method Filter Chips
                            FilterChip(
                              label: Text(l10n.filterAllPaymentMethods),
                              selected: state.selectedPaymentMethod == null,
                              onSelected: (_) => context
                                  .read<EmployeeDetailsCubit>()
                                  .filterByPaymentMethod(null),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: Text(l10n.cashPayment),
                              selected: state.selectedPaymentMethod == 'cash',
                              onSelected: (selected) => context
                                  .read<EmployeeDetailsCubit>()
                                  .filterByPaymentMethod(selected ? 'cash' : null),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: Text(l10n.creditCardPayment),
                              selected: state.selectedPaymentMethod == 'credit_card',
                              onSelected: (selected) => context
                                  .read<EmployeeDetailsCubit>()
                                  .filterByPaymentMethod(
                                      selected ? 'credit_card' : null),
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: Text(l10n.bankTransferPayment),
                              selected:
                                  state.selectedPaymentMethod == 'bank_transfer',
                              onSelected: (selected) => context
                                  .read<EmployeeDetailsCubit>()
                                  .filterByPaymentMethod(
                                      selected ? 'bank_transfer' : null),
                            ),
                            const SizedBox(width: 12),
                            Container(width: 1, height: 24, color: AppColors.divider),
                            const SizedBox(width: 12),

                            // Category Chips
                            FilterChip(
                              label: Text(l10n.filterAllCategories),
                              selected: state.selectedCategoryId == null,
                              onSelected: (_) => context
                                  .read<EmployeeDetailsCubit>()
                                  .filterByCategory(null),
                            ),
                            const SizedBox(width: 6),
                            ...categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(cat.name),
                                  selected: state.selectedCategoryId == cat.id,
                                  onSelected: (selected) => context
                                      .read<EmployeeDetailsCubit>()
                                      .filterByCategory(selected ? cat.id : null),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. Expense Items List
                  if (expenses.isEmpty) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(36),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 52,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.hasActiveFilters
                                    ? l10n.noExpensesAdmin
                                    : l10n.noExpensesForEmployee,
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...expenses.map((Expense exp) {
                      final catColor = _parseColor(exp.category?.color);
                      final paymentLabel = AppConstants
                              .paymentMethodLabels[exp.paymentMethod] ??
                          exp.paymentMethod;
                      final hasReceipt =
                          exp.receiptUrl != null && exp.receiptUrl!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push('/expenses/${exp.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Color Bar
                                Container(
                                  width: 6,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Main Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              exp.title,
                                              style: AppTextStyles.subtitle2.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currencyFormat.format(exp.amount),
                                            style: AppTextStyles.subtitle1.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (exp.category != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                exp.category!.name,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: catColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            dateFormat.format(exp.expenseDate),
                                            style: AppTextStyles.caption,
                                          ),
                                          const SizedBox(width: 6),
                                          Text('•', style: AppTextStyles.caption),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              paymentLabel,
                                              style: AppTextStyles.caption,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasReceipt) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.receipt_outlined,
                                              size: 14,
                                              color: AppColors.secondaryDark,
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (exp.notes != null &&
                                          exp.notes!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          exp.notes!,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textHint,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
