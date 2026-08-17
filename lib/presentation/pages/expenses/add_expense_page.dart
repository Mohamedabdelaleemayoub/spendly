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
            content: Text('فشل اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
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
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح أكبر من الصفر'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cubit = context.read<ExpenseCubit>();
    bool success;

    if (_isEditing) {
      success = await cubit.updateExpense(
        id: widget.initialExpense!.id,
        title: _titleController.text.trim(),
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        expenseDate: _selectedDate,
        categoryId: _selectedCategoryId,
        notes: _notesController.text.trim(),
        receiptFile: _receiptFile,
        existingReceiptUrl: _existingReceiptUrl,
      );
    } else {
      success = await cubit.createExpense(
        title: _titleController.text.trim(),
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        expenseDate: _selectedDate,
        categoryId: _selectedCategoryId,
        notes: _notesController.text.trim(),
        receiptFile: _receiptFile,
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد'),
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
          final isLoading = state is ExpenseActionInProgress;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المصروف *',
                    hintText: 'مثلاً: غداء عمل، وقود، اشتراك شهري',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عنوان المصروف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'المبلغ (ر.س) *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال المبلغ';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'يرجى إدخال مبلغ صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    final categories = context.read<CategoryCubit>().categories;

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'الفئة',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: const Text('اختر فئة'),
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

                // Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ المصروف *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      dateFormat.format(_selectedDate),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method Picker
                const Text('طريقة الدفع *', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.paymentMethods.map((methodKey) {
                    final isSelected = _selectedPaymentMethod == methodKey;
                    final label = AppConstants.paymentMethodLabels[methodKey] ?? methodKey;

                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPaymentMethod = methodKey);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية',
                    hintText: 'تفاصيل أخرى أو مرجع الفاتورة...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Receipt Attachment
                const Text('صورة الفاتورة / الإيصال', style: AppTextStyles.label),
                const SizedBox(height: 8),
                if (_receiptFile != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _receiptFile!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _receiptFile = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_existingReceiptUrl != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingReceiptUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _existingReceiptUrl = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('إرفاق صورة الفاتورة'),
                  ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      : Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المصروف'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
