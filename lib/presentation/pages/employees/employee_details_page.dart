import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/financial_history_item.dart';
import '../../../domain/entities/profile.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/balance/admin_balance_cubit.dart';
import '../../cubits/balance/admin_balance_state.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/dashboard/dashboard_state.dart';
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
        BlocProvider(
          create: (context) => sl<AdminBalanceCubit>()..loadEmployeeFinancialDetails(employeeId),
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

class _EmployeeDetailsViewState extends State<_EmployeeDetailsView> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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

  void _showAddBalanceDialog(BuildContext context, String employeeName) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(modalCtx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_card, color: AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.addBalanceTitle, style: AppTextStyles.heading3),
                              Text(
                                '${l10n.addBalanceSubtitle} ($employeeName)',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Input Field
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '${l10n.expenseAmountLabel} *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Selector
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(l10n.allowanceDate, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                            Text(
                              DateFormat('yyyy/MM/dd').format(selectedDate),
                              style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note Input Field
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: l10n.allowanceNote,
                        hintText: l10n.allowanceNoteHint,
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                final amount = double.parse(amountController.text.trim());
                                final note = noteController.text.trim();
                                Navigator.pop(bottomSheetCtx);

                                context.read<AdminBalanceCubit>().addBalance(
                                      userId: widget.employeeId,
                                      amount: amount,
                                      transactionDate: selectedDate,
                                      note: note.isNotEmpty ? note : null,
                                    );
                              }
                            },
                            child: Text(l10n.confirmAddBalance),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      symbol: Localizations.localeOf(context).languageCode == 'ar' ? 'ر.س ' : 'SAR ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employeeDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              context.read<EmployeeDetailsCubit>().loadEmployeeDetails(widget.employeeId);
              context.read<AdminBalanceCubit>().loadEmployeeFinancialDetails(widget.employeeId);
            },
          ),
        ],
      ),
      body: BlocListener<AdminBalanceCubit, AdminBalanceState>(
        listener: (context, balanceState) {
          if (balanceState is AdminBalanceAddedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.balanceAddedSuccess),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (balanceState is AdminBalanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(balanceState.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocConsumer<EmployeeDetailsCubit, EmployeeDetailsState>(
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
                        onPressed: () {
                          context.read<EmployeeDetailsCubit>().loadEmployeeDetails(widget.employeeId);
                          context.read<AdminBalanceCubit>().loadEmployeeFinancialDetails(widget.employeeId);
                        },
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
              final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
              final isActive = profile.isActive;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Employee Profile Card
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
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
                                          Text(
                                            profile.name,
                                            style: AppTextStyles.heading3,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                    color: isActive ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

                            // 2. Allowance & Available Balance Card with "Add Balance" Action
                            BlocBuilder<AdminBalanceCubit, AdminBalanceState>(
                              builder: (context, balanceState) {
                                double available = 0.0;
                                double received = 0.0;
                                double spent = state.totalExpenses;

                                if (balanceState is AdminBalanceLoaded &&
                                    balanceState.selectedEmployeeSummary != null) {
                                  available = balanceState.selectedEmployeeSummary!.availableBalance;
                                  received = balanceState.selectedEmployeeSummary!.totalReceived;
                                  spent = balanceState.selectedEmployeeSummary!.totalSpent;
                                }

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: available > 0
                                          ? [const Color(0xFF00B894), const Color(0xFF00897B)]
                                          : [const Color(0xFF636E72), const Color(0xFF2D3436)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (available > 0 ? const Color(0xFF00B894) : Colors.grey)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.availableBalance,
                                                style: AppTextStyles.subtitle2.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => _showAddBalanceDialog(context, profile.name),
                                            icon: const Icon(Icons.add, size: 16),
                                            label: Text(
                                              l10n.addBalance,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: AppColors.primaryDark,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        currencyFormat.format(available),
                                        style: AppTextStyles.amountLarge.copyWith(
                                          color: Colors.white,
                                          fontSize: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(color: Colors.white24, height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.totalReceived,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currencyFormat.format(received),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                l10n.totalSpent,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currencyFormat.format(spent),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // TabBar for switching between Expenses and Full Financial History
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.textSecondary,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                tabs: [
                                  Tab(text: l10n.employeeExpensesTitle),
                                  Tab(text: l10n.transactionHistory),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Expenses List with filters
                    _buildExpensesTab(context, state, l10n, currencyFormat, dateFormat),

                    // Tab 2: Full Financial Transaction History (Credits + Expenses)
                    _buildFinancialHistoryTab(context, l10n, currencyFormat, dateFormat),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    EmployeeDetailsLoaded state,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Search and Filter Bar
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
                      context.read<EmployeeDetailsCubit>().searchExpenses('');
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
            final categories = catState is CategoryLoaded ? catState.categories : [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.allTime),
                    selected: state.selectedStartDate == null && state.selectedEndDate == null,
                    onSelected: (_) => context.read<EmployeeDetailsCubit>().filterByPeriod(null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text(l10n.periodToday),
                    selected: state.selectedStartDate != null &&
                        state.selectedEndDate != null &&
                        state.selectedStartDate == state.selectedEndDate,
                    onSelected: (_) =>
                        context.read<EmployeeDetailsCubit>().filterByPeriod(ExpenseSummaryPeriod.today),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text(l10n.periodThisWeek),
                    selected: false,
                    onSelected: (_) =>
                        context.read<EmployeeDetailsCubit>().filterByPeriod(ExpenseSummaryPeriod.week),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text(l10n.periodThisMonth),
                    selected: false,
                    onSelected: (_) =>
                        context.read<EmployeeDetailsCubit>().filterByPeriod(ExpenseSummaryPeriod.month),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(state.selectedStartDate != null
                        ? '${dateFormat.format(state.selectedStartDate!)} - ${dateFormat.format(state.selectedEndDate!)}'
                        : l10n.filterDateRange),
                    onPressed: () => _pickDateRange(context),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSelected = state.selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (sel) => context
                            .read<EmployeeDetailsCubit>()
                            .filterByCategory(sel ? cat.id : null),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Expenses List
        if (state.expenses.isEmpty) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noExpensesFound,
                      style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          ...state.expenses.map((Expense expense) {
            final catColor = _parseColor(expense.category?.color);
            final paymentLabel =
                AppConstants.paymentMethodLabels[expense.paymentMethod] ?? expense.paymentMethod;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: () => context.push('/expenses/${expense.id}'),
                leading: Container(
                  width: 10,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                title: Text(
                  expense.displayTitle,
                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${dateFormat.format(expense.expenseDate)} • $paymentLabel${expense.category != null ? " • ${expense.category!.name}" : ""}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFinancialHistoryTab(
    BuildContext context,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return BlocBuilder<AdminBalanceCubit, AdminBalanceState>(
      builder: (context, balanceState) {
        if (balanceState is AdminBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = (balanceState is AdminBalanceLoaded)
            ? balanceState.selectedEmployeeHistory
            : <FinancialHistoryItem>[];

        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noTransactionsYet,
                    style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final isCredit = item.isPositive;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isCredit
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.12),
                  child: Icon(
                    isCredit ? Icons.add : Icons.remove,
                    color: isCredit ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${isCredit ? "+" : "-"}${currencyFormat.format(item.amount)}',
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCredit ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(item.date),
                          style: AppTextStyles.caption,
                        ),
                        if (item.subtitle != null)
                          Text(
                            item.subtitle!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    if (item.note != null && item.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.note!,
                        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
