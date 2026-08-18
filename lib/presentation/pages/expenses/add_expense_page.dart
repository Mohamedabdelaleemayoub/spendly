import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/balance/employee_balance_cubit.dart';
import '../../cubits/balance/employee_balance_state.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/category/category_state.dart';
import '../../cubits/expense/expense_cubit.dart';
import '../../cubits/expense/expense_state.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({this.initialExpense, super.key});

  final Expense? initialExpense;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<ExpenseCubit>()),
        BlocProvider(create: (context) => sl<CategoryCubit>()..loadCategories()),
        BlocProvider(create: (context) => sl<EmployeeBalanceCubit>()..loadBalance()),
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

  String? _selectedCategoryId;
  String _selectedPaymentMethod = AppConstants.paymentCash;
  DateTime _selectedDate = DateTime.now();
  File? _receiptFile;
  String? _existingReceiptUrl;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
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

    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (_isEditing) {
      context.read<ExpenseCubit>().updateExpense(
            id: widget.initialExpense!.id,
            title: title,
            amount: amount,
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
    final currencyFormat = NumberFormat.currency(
      symbol: Localizations.localeOf(context).languageCode == 'ar' ? 'ر.س ' : 'SAR ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExpenseTitle : l10n.addExpenseTitle),
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditing ? l10n.expenseUpdatedSuccess : l10n.expenseAddedSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(true);
          } else if (state is ExpenseError) {
            String errorMsg = state.message;
            if (errorMsg.contains('INSUFFICIENT_BALANCE') ||
                errorMsg.contains('exceeds available balance')) {
              errorMsg = l10n.insufficientBalance;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
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
                // 1. Available Balance Indicator Banner
                BlocBuilder<EmployeeBalanceCubit, EmployeeBalanceState>(
                  builder: (context, balanceState) {
                    if (balanceState is EmployeeBalanceLoaded) {
                      final summary = balanceState.summary;
                      final available = summary.availableBalance;
                      final isLow = available <= 0;

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
                                  l10n.availableBalance,
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormat.format(available),
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

                // 2. Amount (Required)
                BlocBuilder<EmployeeBalanceCubit, EmployeeBalanceState>(
                  builder: (context, balanceState) {
                    double? availableBalance;
                    if (balanceState is EmployeeBalanceLoaded) {
                      availableBalance = balanceState.summary.availableBalance;
                      if (_isEditing && widget.initialExpense != null) {
                        availableBalance += widget.initialExpense!.amount;
                      }
                    }

                    return TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: '${l10n.expenseAmountLabel} *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return l10n.amountMustBeGreaterThanZero;
                        }
                        if (availableBalance != null && parsed > availableBalance) {
                          return l10n.insufficientBalance;
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Category Dropdown (REQUIRED)
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    final categories = context.read<CategoryCubit>().categories;

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: l10n.expenseCategoryRequiredLabel,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      hint: Text(l10n.filterAllCategories),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.categoryRequired;
                        }
                        return null;
                      },
                      items: categories.map((Category cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. Title (OPTIONAL)
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.expenseTitleOptional,
                    hintText: 'مثلاً: غداء عمل، وقود، صيانة...',
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.expenseDateLabel,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      dateFormat.format(_selectedDate),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Payment Method Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethodLabel,
                    prefixIcon: const Icon(Icons.payment_outlined),
                  ),
                  items: AppConstants.paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(
                        AppConstants.paymentMethodLabels[method] ?? method,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPaymentMethod = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 7. Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.notesLabel,
                    hintText: l10n.notesHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Receipt Image Picker
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
                            _receiptFile != null ||
                                    (_existingReceiptUrl != null &&
                                        _existingReceiptUrl!.isNotEmpty)
                                ? l10n.changePhoto
                                : l10n.addPhoto,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 9. Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? l10n.saveChanges : l10n.addExpenseTitle,
                          style: AppTextStyles.button,
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
