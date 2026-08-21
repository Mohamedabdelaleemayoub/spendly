import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection/injection_container.dart';
import '../../cubits/audit/audit_cubit.dart';
import '../../cubits/audit/audit_state.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuditCubit>()..loadAuditLogs(),
      child: const _AuditLogsView(),
    );
  }
}

class _AuditLogsView extends StatefulWidget {
  const _AuditLogsView();

  @override
  State<_AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<_AuditLogsView> {
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _entityLabels = {
    'all': 'الكل',
    'expense': 'المصروفات',
    'allowance_transaction': 'العهد الأسبوعية',
    'salary_advance': 'السلف',
    'balance_transaction': 'شحن الرصيد',
    'profile': 'الموظفون',
    'settings': 'الإعدادات',
  };

  final Map<String, String> _actionLabels = {
    'expense_created': 'إضافة مصروف',
    'expense_updated': 'تعديل مصروف',
    'expense_deleted': 'حذف مصروف',
    'allowance_created': 'تسليم عهدة',
    'allowance_deleted': 'حذف عهدة',
    'salary_advance_created': 'صرف سلفة',
    'salary_advance_deleted': 'حذف سلفة',
    'salary_updated': 'تعديل الراتب',
    'balance_credited': 'شحن رصيد نقدي',
    'balance_adjusted': 'تسوية رصيد',
    'role_updated': 'تغيير صلاحية المستخدم',
    'status_updated': 'تغيير حالة المستخدم',
    'setting_updated': 'تعديل إعدادات النظام',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAction(String action) {
    return _actionLabels[action] ?? action;
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'expense':
        return Icons.receipt_long;
      case 'allowance_transaction':
        return Icons.account_balance_wallet;
      case 'salary_advance':
        return Icons.payments;
      case 'balance_transaction':
        return Icons.add_card;
      case 'profile':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('deleted')) return AppColors.error;
    if (action.contains('created') || action.contains('credited')) return AppColors.secondary;
    if (action.contains('updated')) return AppColors.primary;
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات والرقابة (Audit Trail)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AuditCubit>().loadAuditLogs(),
          ),
        ],
      ),
      body: BlocBuilder<AuditCubit, AuditState>(
        builder: (context, state) {
          if (state is AuditLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuditError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AuditCubit>().loadAuditLogs(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AuditLoaded) {
            final filtered = state.filteredLogs;

            return Column(
              children: [
                // Search and Filter Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث في السجلات باسم المستخدم أو العملية...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<AuditCubit>().search('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => context.read<AuditCubit>().search(val),
                  ),
                ),

                // Entity Type Chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _entityLabels.entries.map((entry) {
                      final isSelected = entry.key == 'all'
                          ? state.selectedEntityType == null
                          : state.selectedEntityType == entry.key;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            context.read<AuditCubit>().filterByEntityType(
                                  entry.key == 'all' ? null : entry.key,
                                );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 16),

                // Logs List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('لا توجد سجلات مطابقة', style: AppTextStyles.subtitle1.copyWith(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<AuditCubit>().loadAuditLogs(entityType: state.selectedEntityType),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (context, i) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final log = filtered[i];
                              final color = _getActionColor(log.action);
                              final icon = _getEntityIcon(log.entityType);

                              return Card(
                                margin: EdgeInsets.zero,
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  title: Text(
                                    _formatAction(log.action),
                                    style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'بواسطة: ${log.userName ?? "مستخدم"} • ${dateFormat.format(log.createdAt)}',
                                    style: AppTextStyles.caption,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (log.entityId != null) ...[
                                            Text('معرف العنصر: ${log.entityId}', style: AppTextStyles.caption),
                                            const SizedBox(height: 8),
                                          ],
                                          if (log.oldValue != null) ...[
                                            const Text('القيمة السابقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                            Text(log.oldValue.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                                            const SizedBox(height: 8),
                                          ],
                                          if (log.newValue != null) ...[
                                            const Text('القيمة الجديدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                            Text(log.newValue.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
