import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/governorate.dart';
import '../../../domain/entities/trip_location_type.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/balance/employee_balance_cubit.dart';
import '../../cubits/balance/employee_balance_state.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/expense/expense_cubit.dart';
import '../../cubits/expense/expense_state.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({
    super.key,
    this.initialExpense,
    this.expenseCubit,
    this.categoryCubit,
    this.balanceCubit,
  });

  final Expense? initialExpense;
  final ExpenseCubit? expenseCubit;
  final CategoryCubit? categoryCubit;
  final EmployeeBalanceCubit? balanceCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (expenseCubit != null)
          BlocProvider<ExpenseCubit>.value(value: expenseCubit!)
        else
          BlocProvider<ExpenseCubit>(
            create: (_) => sl<ExpenseCubit>(),
          ),
        if (categoryCubit != null)
          BlocProvider<CategoryCubit>.value(value: categoryCubit!)
        else
          BlocProvider<CategoryCubit>(
            create: (_) => sl<CategoryCubit>()..loadCategories(),
          ),
        if (balanceCubit != null)
          BlocProvider<EmployeeBalanceCubit>.value(value: balanceCubit!)
        else
          BlocProvider<EmployeeBalanceCubit>(
            create: (_) => sl<EmployeeBalanceCubit>()..loadBalance(),
          ),
      ],
      child: _AddExpenseForm(initialExpense: initialExpense),
    );
  }
}

class _AddExpenseForm extends StatefulWidget {
  const _AddExpenseForm({this.initialExpense});

  final Expense? initialExpense;

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  ExpenseCurrency _selectedCurrency = ExpenseCurrency.egp;
  TripLocationType _selectedTripLocation = TripLocationType.cairo;
  Governorate? _selectedGovernorate;
  String? _selectedCategoryId;
  String _selectedPaymentMethod = AppConstants.paymentCash;
  DateTime _selectedDate = DateTime.now();
  File? _receiptFile;
  String? _existingReceiptUrl;
  final ImagePicker _picker = ImagePicker();

  double? _submittedAvailableBefore;
  double? _submittedAmount;
  ExpenseCurrency? _submittedCurrency;

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _selectedCurrency = e?.currency ?? ExpenseCurrency.egp;
    _selectedTripLocation = e?.tripLocationType ?? TripLocationType.cairo;
    _selectedGovernorate = (e != null && e.tripLocationType == TripLocationType.outsideCairo)
        ? e.governorate
        : null;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _selectedCategoryId = e?.categoryId;
    _selectedPaymentMethod = e?.paymentMethod ?? AppConstants.paymentCash;
    _selectedDate = e?.expenseDate ?? DateTime.now();
    _existingReceiptUrl = e?.receiptUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _receiptFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.photoUploadError}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.amountMustBeGreaterThanZero),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.categoryRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTripLocation == TripLocationType.outsideCairo && _selectedGovernorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.governorateRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final effectiveGov = _selectedTripLocation == TripLocationType.cairo
        ? Governorate.cairo
        : _selectedGovernorate!;

    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    final balanceState = context.read<EmployeeBalanceCubit>().state;
    double? availableBefore;
    if (balanceState is EmployeeBalanceLoaded) {
      availableBefore = balanceState.summary.availableBalanceFor(_selectedCurrency);
      if (_isEditing && widget.initialExpense != null && widget.initialExpense!.currency == _selectedCurrency) {
        availableBefore += widget.initialExpense!.amount;
      }
    }
    _submittedAvailableBefore = availableBefore;
    _submittedAmount = amount;
    _submittedCurrency = _selectedCurrency;

    if (_isEditing) {
      context.read<ExpenseCubit>().updateExpense(
            id: widget.initialExpense!.id,
            title: title,
            amount: amount,
            currency: _selectedCurrency,
            tripLocationType: _selectedTripLocation,
            governorate: effectiveGov,
            categoryId: _selectedCategoryId,
            paymentMethod: _selectedPaymentMethod,
            expenseDate: _selectedDate,
            notes: notes.isNotEmpty ? notes : null,
            receiptFile: _receiptFile,
            existingReceiptUrl: _existingReceiptUrl,
          );
    } else {
      context.read<ExpenseCubit>().createExpense(
            amount: amount,
            currency: _selectedCurrency,
            tripLocationType: _selectedTripLocation,
            governorate: effectiveGov,
            categoryId: _selectedCategoryId,
            expenseDate: _selectedDate,
            paymentMethod: _selectedPaymentMethod,
            title: title,
            notes: notes.isNotEmpty ? notes : null,
            receiptFile: _receiptFile,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExpenseTitle : l10n.addExpenseTitle),
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseActionSuccess) {
            final isArabic = Localizations.localeOf(context).languageCode == 'ar';
            final symbol = _submittedCurrency?.symbolForLocale(isArabic ? 'ar' : 'en') ?? _selectedCurrency.symbolForLocale(isArabic ? 'ar' : 'en');
            final availableBefore = _submittedAvailableBefore;
            final submittedAmount = _submittedAmount;

            if (availableBefore != null && submittedAmount != null && (availableBefore - submittedAmount) < 0) {
              final remainingAfter = availableBefore - submittedAmount;
              final beforeStr = '${availableBefore.toStringAsFixed(availableBefore.truncateToDouble() == availableBefore ? 0 : 2)} $symbol';
              final amountStr = '${submittedAmount.toStringAsFixed(submittedAmount.truncateToDouble() == submittedAmount ? 0 : 2)} $symbol';
              final remainingStr = '${remainingAfter.toStringAsFixed(remainingAfter.truncateToDouble() == remainingAfter ? 0 : 2)} $symbol';

              final warningMsg = '${l10n.expenseExceededBalanceWarning}\n'
                  '${l10n.availableBalanceBefore(beforeStr)}\n'
                  '${l10n.expenseAmountLabelValue(amountStr)}\n'
                  '${l10n.balanceAfterExpense(remainingStr)}';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    warningMsg,
                    style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFD97706),
                  duration: const Duration(seconds: 6),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isEditing ? l10n.expenseUpdatedSuccess : l10n.expenseAddedSuccess),
                  backgroundColor: AppColors.success,
                ),
              );
            }
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
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
          final isLoading = state is ExpenseActionInProgress;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Currency Selector (EGP / USD)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.currency_exchange, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.currencyLabel,
                              style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<ExpenseCurrency>(
                          segments: [
                            ButtonSegment(
                              value: ExpenseCurrency.egp,
                              label: Text(
                                l10n.currencyEgp,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.money),
                            ),
                            ButtonSegment(
                              value: ExpenseCurrency.usd,
                              label: Text(
                                l10n.currencyUsd,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.attach_money),
                            ),
                          ],
                          selected: {_selectedCurrency},
                          onSelectionChanged: (Set<ExpenseCurrency> newSelection) {
                            setState(() {
                              _selectedCurrency = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Available Balance Indicator Banner for Selected Currency
                BlocBuilder<EmployeeBalanceCubit, EmployeeBalanceState>(
                  builder: (context, balanceState) {
                    if (balanceState is EmployeeBalanceLoaded) {
                      final summary = balanceState.summary;
                      final available = summary.availableBalanceFor(_selectedCurrency);
                      final isLow = available <= 0;
                      final symbol = _selectedCurrency.symbolForLocale(isArabic ? 'ar' : 'en');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isLow
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLow ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: isLow ? AppColors.error : AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.availableBalance} (${_selectedCurrency.code})',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${available.toStringAsFixed(2)} $symbol',
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isLow ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 3. Trip Location Section (Inside Cairo / Outside Cairo)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.tripLocationLabel,
                              style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<TripLocationType>(
                          segments: [
                            ButtonSegment(
                              value: TripLocationType.cairo,
                              label: Text(
                                l10n.insideCairo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.location_city),
                            ),
                            ButtonSegment(
                              value: TripLocationType.outsideCairo,
                              label: Text(
                                l10n.outsideCairo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.commute),
                            ),
                          ],
                          selected: {_selectedTripLocation},
                          onSelectionChanged: (Set<TripLocationType> newSelection) {
                            setState(() {
                              _selectedTripLocation = newSelection.first;
                              if (_selectedTripLocation == TripLocationType.cairo) {
                                _selectedGovernorate = null;
                              }
                            });
                          },
                        ),
                        if (_selectedTripLocation == TripLocationType.outsideCairo) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Governorate>(
                            initialValue: _selectedGovernorate,
                            decoration: InputDecoration(
                              labelText: l10n.governorateLabel,
                              hintText: l10n.selectGovernorate,
                              prefixIcon: const Icon(Icons.map_outlined),
                            ),
                            items: Governorate.outsideCairoGovernorates.map((gov) {
                              return DropdownMenuItem<Governorate>(
                                value: gov,
                                child: Text(gov.localizedName(isArabic ? 'ar' : 'en')),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGovernorate = val;
                              });
                            },
                            validator: (val) {
                              if (_selectedTripLocation == TripLocationType.outsideCairo && val == null) {
                                return l10n.governorateRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 4. Amount (Required)
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.expenseAmountLabel,
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: _selectedCurrency.code,
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
                const SizedBox(height: 16),

                // 5. Title (Optional)
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.expenseTitleOptional,
                    hintText: l10n.defaultExpenseTitle,
                    prefixIcon: const Icon(Icons.title_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Category (Required)
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    List<Category> categories = [];
                    if (state is CategoryLoaded) {
                      categories = state.categories;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: l10n.expenseCategoryRequiredLabel,
                        hintText: l10n.categoryRequired,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return l10n.categoryRequired;
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 7. Payment Method & Date
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: l10n.paymentMethodLabel,
                          prefixIcon: const Icon(Icons.payment_outlined),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: AppConstants.paymentCash,
                            child: Text(l10n.cashPayment),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.paymentBank,
                            child: Text(l10n.creditCardPayment),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.paymentTransfer,
                            child: Text(l10n.bankTransferPayment),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaymentMethod = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.expenseDateLabel,
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            dateFormat.format(_selectedDate),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. Notes (Optional)
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.expenseNotesLabel,
                    hintText: l10n.notesHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // 9. Receipt Image Picker
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.receiptPhotoLabel,
                          style: AppTextStyles.subtitle2,
                        ),
                        const SizedBox(height: 12),
                        if (_receiptFile != null) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _receiptFile!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              IconButton.filled(
                                icon: const Icon(Icons.close, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() => _receiptFile = null);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ] else if (_existingReceiptUrl != null &&
                            _existingReceiptUrl!.isNotEmpty) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _existingReceiptUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                ),
                              ),
                              IconButton.filled(
                                icon: const Icon(Icons.close, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() => _existingReceiptUrl = null);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            _receiptFile != null || _existingReceiptUrl != null
                                ? l10n.changePhoto
                                : l10n.addPhoto,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 10. Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? l10n.saveChanges : l10n.addExpenseTitle,
                          style: AppTextStyles.button,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
