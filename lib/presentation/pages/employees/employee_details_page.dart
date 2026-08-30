import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/financial_history_item.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/salary_advance.dart';
import '../../../domain/entities/trip_location_type.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/balance/admin_balance_cubit.dart';
import '../../cubits/balance/admin_balance_state.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/dashboard/dashboard_state.dart';
import '../../cubits/employee_details/employee_details_cubit.dart';
import '../../cubits/employee_details/employee_details_state.dart';
import '../../cubits/salary_advances/salary_advances_cubit.dart';
import '../../cubits/salary_advances/salary_advances_state.dart';

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
        BlocProvider<EmployeeDetailsCubit>(
          create: (_) => sl<EmployeeDetailsCubit>()
            ..loadEmployeeDetails(employeeId, initialProfile: initialProfile),
        ),
        BlocProvider<AdminBalanceCubit>(
          create: (_) => sl<AdminBalanceCubit>()
            ..loadEmployeeFinancialDetails(employeeId),
        ),
        BlocProvider<CategoryCubit>(
          create: (_) => sl<CategoryCubit>()..loadCategories(),
        ),
        BlocProvider<SalaryAdvancesCubit>(
          create: (_) => sl<SalaryAdvancesCubit>()
            ..loadSalaryAdvances(
              employeeId,
              initialSalary: initialProfile?.salaryAmount,
              initialCurrency: initialProfile?.salaryCurrency,
            ),
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
    _tabController = TabController(length: 3, vsync: this);
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

  String _formatAmount(double amount, ExpenseCurrency currency, bool isArabic) {
    final symbol = currency.symbolForLocale(isArabic ? 'ar' : 'en');
    return '${amount.toStringAsFixed(2)} $symbol';
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

  // ── Add Lifetime Balance Dialog ─────────────────────────────────────────────
  void _showAddBalanceDialog(BuildContext context, String employeeName) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    ExpenseCurrency selectedCurrency = ExpenseCurrency.egp;
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
                child: SingleChildScrollView(
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

                    // Currency Selector
                    Text(
                      l10n.currencyLabel,
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ExpenseCurrency>(
                      segments: [
                        ButtonSegment(
                          value: ExpenseCurrency.egp,
                          label: Text(l10n.currencyEgp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          icon: const Icon(Icons.money, size: 16),
                        ),
                        ButtonSegment(
                          value: ExpenseCurrency.usd,
                          label: Text(l10n.currencyUsd, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          icon: const Icon(Icons.attach_money, size: 16),
                        ),
                      ],
                      selected: {selectedCurrency},
                      onSelectionChanged: (Set<ExpenseCurrency> newSelection) {
                        setModalState(() {
                          selectedCurrency = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.expenseAmountLabel,
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: selectedCurrency.code,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        final amount = double.tryParse(val.trim());
                        if (amount == null || amount <= 0) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Picker Tile
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
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
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 10),
                                Text(l10n.allowanceDate, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                            Text(
                              DateFormat('yyyy/MM/dd').format(selectedDate),
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Note Input
                    TextFormField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.allowanceNote,
                        hintText: l10n.allowanceNoteHint,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.notes_outlined),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final amount = double.parse(amountController.text.trim());
                                final note = noteController.text.trim();
                                context.read<AdminBalanceCubit>().addBalance(
                                      userId: widget.employeeId,
                                      amount: amount,
                                      currency: selectedCurrency,
                                      transactionDate: selectedDate,
                                      note: note.isNotEmpty ? note : null,
                                    );
                                Navigator.pop(modalCtx);
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
            ),
          );
          },
        );
      },
    );
  }

  // ── Salary Dialogs ─────────────────────────────────────────────────────────
  void _showEditSalaryDialog(
    BuildContext context,
    Profile profile,
    SalaryAdvancesLoaded salaryState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final salaryController = TextEditingController(
      text: salaryState.salaryAmount > 0 ? salaryState.salaryAmount.toStringAsFixed(0) : '',
    );
    ExpenseCurrency selectedCurrency = salaryState.salaryCurrency;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.editSalary, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.fullNameLabel}: ${profile.name}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.currencyLabel,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<ExpenseCurrency>(
                    segments: [
                      ButtonSegment(
                        value: ExpenseCurrency.egp,
                        label: Text(l10n.currencyEgpShort, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: ExpenseCurrency.usd,
                        label: Text(l10n.currencyUsdShort, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                    selected: {selectedCurrency},
                    onSelectionChanged: (newSel) {
                      setDialogState(() => selectedCurrency = newSel.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: salaryController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.salaryAmount,
                      hintText: '8000',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: selectedCurrency.code,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.amountMustBeGreaterThanZero;
                      }
                      final amt = double.tryParse(val.trim());
                      if (amt == null || amt < 0) {
                        return l10n.amountMustBeGreaterThanZero;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(salaryController.text.trim());
                  final salaryCubit = context.read<SalaryAdvancesCubit>();
                  final detailsCubit = context.read<EmployeeDetailsCubit>();
                  salaryCubit.updateEmployeeSalary(
                        userId: widget.employeeId,
                        salaryAmount: amount,
                        salaryCurrency: selectedCurrency,
                      );
                  detailsCubit.updateProfileSalary(amount, selectedCurrency);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.salaryUpdatedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSalaryAdvanceDialog(
    BuildContext context,
    String employeeName,
    SalaryAdvancesLoaded salaryState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    ExpenseCurrency selectedCurrency = salaryState.salaryCurrency;
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
                child: SingleChildScrollView(
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
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Color(0xFF6C5CE7)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.addSalaryAdvance, style: AppTextStyles.heading3),
                                Text(
                                  '${l10n.fullNameLabel}: $employeeName',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Amount Input
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.expenseAmountLabel,
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: selectedCurrency.code,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.amountMustBeGreaterThanZero;
                          }
                          final amount = double.tryParse(val.trim());
                          if (amount == null || amount <= 0) {
                            return l10n.amountMustBeGreaterThanZero;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date Picker Tile
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: modalCtx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
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
                                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Text(l10n.advanceDate, style: AppTextStyles.bodyMedium),
                                ],
                              ),
                              Text(
                                DateFormat('yyyy/MM/dd').format(selectedDate),
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reason / Note Input
                      TextFormField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.advanceReason,
                          hintText: l10n.advanceReasonHint,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 30),
                            child: Icon(Icons.notes_outlined),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(modalCtx),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  final amount = double.parse(amountController.text.trim());
                                  final note = noteController.text.trim();
                                  context.read<SalaryAdvancesCubit>().addSalaryAdvance(
                                        userId: widget.employeeId,
                                        amount: amount,
                                        currency: selectedCurrency,
                                        advanceDate: selectedDate,
                                        note: note.isNotEmpty ? note : null,
                                      );
                                  Navigator.pop(modalCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.advanceAddedSuccess),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              child: Text(l10n.addSalaryAdvance),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSalaryAdvanceDialog(
    BuildContext context,
    SalaryAdvance advance,
    SalaryAdvancesLoaded salaryState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: advance.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: advance.note ?? '');
    ExpenseCurrency selectedCurrency = advance.currency;
    DateTime selectedDate = advance.advanceDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.editSalaryAdvance, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.expenseAmountLabel,
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: selectedCurrency.code,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.amountMustBeGreaterThanZero;
                      }
                      final amount = double.tryParse(val.trim());
                      if (amount == null || amount <= 0) {
                        return l10n.amountMustBeGreaterThanZero;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
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
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Text(l10n.advanceDate, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                          Text(
                            DateFormat('yyyy/MM/dd').format(selectedDate),
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.advanceReason,
                      hintText: l10n.advanceReasonHint,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Icon(Icons.notes_outlined),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text.trim());
                  final note = noteController.text.trim();
                  context.read<SalaryAdvancesCubit>().updateSalaryAdvance(
                        id: advance.id,
                        userId: widget.employeeId,
                        amount: amount,
                        currency: selectedCurrency,
                        advanceDate: selectedDate,
                        note: note.isNotEmpty ? note : null,
                      );
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.advanceUpdatedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSalaryAdvance(BuildContext context, SalaryAdvance advance) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SalaryAdvancesCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteSalaryAdvance),
        content: Text(l10n.deleteSalaryAdvanceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.deleteSalaryAdvance(advance.id, widget.employeeId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.advanceDeletedSuccess),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(l10n.deleteSalaryAdvance),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
              context.read<SalaryAdvancesCubit>().loadSalaryAdvances(widget.employeeId);
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
                          context.read<SalaryAdvancesCubit>().loadSalaryAdvances(widget.employeeId);
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

              return ResponsiveContentContainer(
                maxWidth: Breakpoints.maxContentWidth,
                child: NestedScrollView(
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



                            // 3. Salary & Advances Summary Card (Separated from Allowance/Spending Balance)
                            BlocBuilder<SalaryAdvancesCubit, SalaryAdvancesState>(
                              builder: (context, salaryState) {
                                final salaryLoaded = salaryState is SalaryAdvancesLoaded ? salaryState : null;
                                final salaryAmount = salaryLoaded?.salaryAmount ?? profile.salaryAmount;
                                final salaryCurrency = salaryLoaded?.salaryCurrency ?? profile.salaryCurrency;
                                final totalAdv = salaryLoaded?.totalAdvances ?? 0.0;
                                final remaining = salaryLoaded?.remainingSalary ?? salaryAmount;

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6C5CE7), Color(0xFF5352ED)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
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
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.account_balance, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    l10n.monthlySalary,
                                                    style: AppTextStyles.subtitle2.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (salaryLoaded != null)
                                            ElevatedButton.icon(
                                              onPressed: () => _showEditSalaryDialog(context, profile, salaryLoaded),
                                              icon: const Icon(Icons.edit, size: 14),
                                              label: Text(
                                                l10n.editSalary,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: const Color(0xFF6C5CE7),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          // Monthly Salary
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.salary,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatAmount(salaryAmount, salaryCurrency, isArabic),
                                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Total Advances
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.totalAdvances,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatAmount(totalAdv, salaryCurrency, isArabic),
                                                    style: const TextStyle(color: Color(0xFFFF7675), fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Remaining Salary
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.remainingSalary,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatAmount(remaining, salaryCurrency, isArabic),
                                                    style: const TextStyle(color: Color(0xFF55EFC4), fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // 4. Dual Allowance & Available Balance Card with "Add Balance" Action
                            BlocBuilder<AdminBalanceCubit, AdminBalanceState>(
                              builder: (context, balanceState) {
                                double availableEgp = -state.totalExpensesEgp;
                                double receivedEgp = 0.0;
                                double spentEgp = state.totalExpensesEgp;

                                double availableUsd = -state.totalExpensesUsd;
                                double receivedUsd = 0.0;
                                double spentUsd = state.totalExpensesUsd;

                                if (balanceState is AdminBalanceLoaded &&
                                    balanceState.selectedEmployeeSummary != null) {
                                  final s = balanceState.selectedEmployeeSummary!;
                                  availableEgp = s.availableBalanceEgp;
                                  receivedEgp = s.totalReceivedEgp;
                                  spentEgp = s.totalSpentEgp;

                                  availableUsd = s.availableBalanceUsd;
                                  receivedUsd = s.totalReceivedUsd;
                                  spentUsd = s.totalSpentUsd;
                                }

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00B894), Color(0xFF00897B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00B894).withValues(alpha: 0.3),
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
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    l10n.availableBalance,
                                                    style: AppTextStyles.subtitle2.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                      const SizedBox(height: 14),

                                      // Dual Columns for EGP and USD Balances
                                      Row(
                                        children: [
                                          // EGP Box
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'EGP (جنيه مصري)',
                                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatAmount(availableEgp, ExpenseCurrency.egp, isArabic),
                                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${l10n.totalReceived}: ${receivedEgp.toStringAsFixed(0)}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.totalSpent}: ${spentEgp.toStringAsFixed(0)}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // USD Box
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'USD (دولار أمريكي)',
                                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatAmount(availableUsd, ExpenseCurrency.usd, isArabic),
                                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${l10n.totalReceived}: ${receivedUsd.toStringAsFixed(0)}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.totalSpent}: ${spentUsd.toStringAsFixed(0)}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // 5. Travel Statistics Card
                            _buildTravelStatsCard(context, state, l10n, isArabic),
                            const SizedBox(height: 16),

                            // TabBar for switching between 4 distinct views
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
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                tabs: [
                                  Tab(text: l10n.employeeExpensesTitle),
                                  Tab(text: l10n.transactionHistory),
                                  Tab(text: l10n.salaryAdvances),
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
                    _buildExpensesTab(context, state, l10n, isArabic, dateFormat),

                    // Tab 2: Full Financial Transaction History (Credits + Expenses)
                    _buildFinancialHistoryTab(context, l10n, isArabic, dateFormat),

                    // Tab 3: Salary Advances (Advances history + Add/Edit/Delete)
                    _buildSalaryAdvancesTab(context, profile, l10n, isArabic, dateFormat),
                  ],
                ),
              ),
            );
          }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildTravelStatsCard(
    BuildContext context,
    EmployeeDetailsLoaded state,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final stats = state.travelStats;
    final bonusSettings = state.travelBonusSettings;
    final potentialBonus = stats.calculatePotentialBonus(bonusSettings);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.travelStatistics,
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTravelMetricTile(
                    title: l10n.totalTrips,
                    count: stats.totalTrips,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTravelMetricTile(
                    title: l10n.insideCairoTrips,
                    count: stats.insideCairoTrips,
                    color: const Color(0xFF0984E3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTravelMetricTile(
                    title: l10n.outsideCairoTrips,
                    count: stats.outsideCairoTrips,
                    color: const Color(0xFFE17055),
                  ),
                ),
              ],
            ),
            if (stats.outsideCairoTrips > 0 && stats.governorateBreakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.governorateBreakdown,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: stats.governorateBreakdown.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE17055).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE17055).withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '${entry.key.localizedName(isArabic ? 'ar' : 'en')}: ${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD63031),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (bonusSettings.enabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard, size: 18, color: AppColors.secondaryDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${l10n.potentialBonus} (${bonusSettings.bonusPerTrip.toStringAsFixed(0)} ${bonusSettings.currency.code}/${l10n.outsideCairo})',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${potentialBonus.toStringAsFixed(0)} ${bonusSettings.currency.code}',
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTravelMetricTile({
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    EmployeeDetailsLoaded state,
    AppLocalizations l10n,
    bool isArabic,
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

        // Filter Chips (Currency, Trip Location, Categories & Dates)
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (catContext, catState) {
            final categories = catState is CategoryLoaded ? catState.categories : [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Currency Filter
                  FilterChip(
                    label: Text(l10n.currencyLabel),
                    selected: state.selectedCurrency == null,
                    onSelected: (_) => context.read<EmployeeDetailsCubit>().filterByCurrency(null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('EGP'),
                    selected: state.selectedCurrency == ExpenseCurrency.egp,
                    onSelected: (sel) => context
                        .read<EmployeeDetailsCubit>()
                        .filterByCurrency(sel ? ExpenseCurrency.egp : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('USD'),
                    selected: state.selectedCurrency == ExpenseCurrency.usd,
                    onSelected: (sel) => context
                        .read<EmployeeDetailsCubit>()
                        .filterByCurrency(sel ? ExpenseCurrency.usd : null),
                  ),
                  const SizedBox(width: 10),

                  // Location Filters
                  FilterChip(
                    label: Text(l10n.insideCairo),
                    selected: state.selectedTripLocationType == TripLocationType.cairo,
                    onSelected: (sel) => context
                        .read<EmployeeDetailsCubit>()
                        .filterByTripLocation(sel ? TripLocationType.cairo : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text(l10n.outsideCairo),
                    selected: state.selectedTripLocationType == TripLocationType.outsideCairo,
                    onSelected: (sel) => context
                        .read<EmployeeDetailsCubit>()
                        .filterByTripLocation(sel ? TripLocationType.outsideCairo : null),
                  ),
                  const SizedBox(width: 10),

                  // Period / Date Filters
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

            final locationLabel = expense.tripLocationType == TripLocationType.outsideCairo
                ? '${l10n.outsideCairo} (${expense.governorate.localizedName(isArabic ? 'ar' : 'en')})'
                : l10n.insideCairo;

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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateFormat.format(expense.expenseDate)} • $paymentLabel${expense.category != null ? " • ${expense.category!.name}" : ""}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: expense.tripLocationType == TripLocationType.outsideCairo
                              ? const Color(0xFFE17055)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locationLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: expense.tripLocationType == TripLocationType.outsideCairo
                                ? const Color(0xFFE17055)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(expense.amount, expense.currency, isArabic),
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: expense.currency == ExpenseCurrency.usd
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.currency.code,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: expense.currency == ExpenseCurrency.usd
                              ? AppColors.secondaryDark
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFinancialHistoryTab(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    DateFormat dateFormat,
  ) {
    return BlocBuilder<AdminBalanceCubit, AdminBalanceState>(
      builder: (context, balanceState) {
        if (balanceState is AdminBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<FinancialHistoryItem> items = (balanceState is AdminBalanceLoaded)
            ? balanceState.selectedEmployeeHistory
            : [];

        if (items.isEmpty) {
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
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isCredit = item.isPositive;
            final color = isCredit ? AppColors.success : AppColors.error;
            final symbol = item.currency.symbolForLocale(isArabic ? 'ar' : 'en');
            final formattedAmount = '${isCredit ? "+" : "-"}${item.amount.toStringAsFixed(2)} $symbol';

            String typeLabel = item.title;
            if (item.itemType == FinancialItemType.credit) {
              typeLabel = l10n.creditTransaction;
            } else if (item.itemType == FinancialItemType.expense) {
              typeLabel = l10n.expenseTransaction;
            } else if (item.itemType == FinancialItemType.adjustmentAdd) {
              typeLabel = l10n.adjustmentAddTransaction;
            } else if (item.itemType == FinancialItemType.adjustmentSub) {
              typeLabel = l10n.adjustmentSubTransaction;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title.isNotEmpty ? item.title : typeLabel,
                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${dateFormat.format(item.date)} • $typeLabel${item.note != null ? " • ${item.note}" : ""}',
                  style: AppTextStyles.caption,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedAmount,
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: item.currency == ExpenseCurrency.usd
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.currency.code,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item.currency == ExpenseCurrency.usd
                              ? AppColors.secondaryDark
                              : AppColors.primaryDark,
                        ),
                      ),
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

  Widget _buildSalaryAdvancesTab(
    BuildContext context,
    Profile profile,
    AppLocalizations l10n,
    bool isArabic,
    DateFormat dateFormat,
  ) {
    return BlocBuilder<SalaryAdvancesCubit, SalaryAdvancesState>(
      builder: (context, salaryState) {
        if (salaryState is SalaryAdvancesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final loadedState = salaryState is SalaryAdvancesLoaded ? salaryState : null;
        final advances = loadedState?.advances ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add Salary Advance Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.salaryAdvances} (${advances.length})',
                  style: AppTextStyles.heading3,
                ),
                ElevatedButton.icon(
                  onPressed: loadedState != null
                      ? () => _showAddSalaryAdvanceDialog(context, profile.name, loadedState)
                      : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addSalaryAdvance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (advances.isEmpty) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.payments_outlined, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noSalaryAdvancesYet,
                          style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...advances.map((advance) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF6C5CE7),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      _formatAmount(advance.amount, advance.currency, isArabic),
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE17055),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.advanceDate}: ${dateFormat.format(advance.advanceDate)}${advance.note != null && advance.note!.isNotEmpty ? " • ${advance.note}" : ""}',
                          style: AppTextStyles.caption,
                        ),
                        if (advance.creatorName != null && advance.creatorName!.isNotEmpty)
                          Text(
                            '${l10n.advanceCreatedBy}: ${advance.creatorName}',
                            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (action) {
                        if (action == 'edit' && loadedState != null) {
                          _showEditSalaryAdvanceDialog(context, advance, loadedState);
                        } else if (action == 'delete') {
                          _confirmDeleteSalaryAdvance(context, advance);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(l10n.editSalaryAdvance),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(l10n.deleteSalaryAdvance, style: const TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
