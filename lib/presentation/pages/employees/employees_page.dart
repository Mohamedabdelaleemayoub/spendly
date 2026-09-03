import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/employee_summary.dart';
import '../../../domain/entities/profile.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/employees/employees_cubit.dart';
import '../../cubits/balance/admin_balance_cubit.dart';
import '../../cubits/balance/admin_balance_state.dart';
import '../../cubits/employees/employees_state.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<EmployeesCubit>()..loadEmployees()..subscribeToRealtime()),
        BlocProvider(create: (context) => sl<AdminBalanceCubit>()..loadAllBalances()),
      ],
      child: const _EmployeesView(),
    );
  }
}

class _EmployeesView extends StatefulWidget {
  const _EmployeesView();

  @override
  State<_EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<_EmployeesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AddUserModal(
        onAddUser: (email, password, name, role) async {
          await cubit.createEmployee(
            email: email,
            password: password,
            fullName: name,
            role: role,
          );
        },
        l10n: l10n,
      ),
    );
  }

  void _confirmApproveUser(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.approveUserConfirmTitle),
        content: Text('${l10n.approveUserConfirmMessage}\n\n${profile.name} (${profile.email ?? ""})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.approveUser(profile.id);
            },
            child: Text(l10n.approveUser),
          ),
        ],
      ),
    );
  }

  void _confirmRejectUser(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.rejectUserConfirmTitle),
        content: Text('${l10n.rejectUserConfirmMessage}\n\n${profile.name} (${profile.email ?? ""})'),
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
              cubit.rejectUser(profile.id);
            },
            child: Text(l10n.rejectUser),
          ),
        ],
      ),
    );
  }

  void _confirmChangeRole(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();
    final newRole = profile.isAdmin ? 'employee' : 'admin';
    final roleTitle = profile.isAdmin ? l10n.makeEmployee : l10n.makeAdmin;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.changeRole),
        content: Text(
          profile.isAdmin
              ? '${l10n.makeEmployee}: ${profile.name}؟'
              : '${l10n.makeAdmin}: ${profile.name}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.updateEmployeeRole(profile.id, newRole);
            },
            child: Text(roleTitle),
          ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();
    final isCurrentlyActive = profile.isActive;
    final newStatus = isCurrentlyActive ? 'inactive' : 'active';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          isCurrentlyActive
              ? l10n.deactivateUserConfirmTitle
              : l10n.reactivateUserConfirmTitle,
        ),
        content: Text(
          isCurrentlyActive
              ? l10n.deactivateUserConfirmMessage
              : l10n.reactivateUserConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCurrentlyActive ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              cubit.toggleEmployeeStatus(profile.id, newStatus);
            },
            child: Text(
              isCurrentlyActive ? l10n.deactivateUser : l10n.reactivateUser,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EmployeesCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteUserConfirmTitle),
        content: Text(l10n.deleteUserConfirmMessage),
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
              cubit.deleteEmployee(profile.id);
            },
            child: Text(l10n.deleteUser),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    if (profile.isActive) {
      color = AppColors.success;
      label = l10n.statusActive;
    } else if (profile.isPending) {
      color = Colors.orange;
      label = l10n.statusPending;
    } else if (profile.isRejected) {
      color = AppColors.error;
      label = l10n.statusRejected;
    } else {
      color = AppColors.textSecondary;
      label = l10n.statusInactive;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ', decimalDigits: 2);
    final currentUserId = sl<AuthCubit>().authRepository.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employeesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              context.read<EmployeesCubit>().loadEmployees();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addUserButton),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: BlocConsumer<EmployeesCubit, EmployeesState>(
        listener: (context, state) {
          if (state is EmployeesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is EmployeesLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmployeesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmployeesLoaded) {
            final employees = state.filteredEmployees;
            final pendingEmployees = state.employees.where((e) => e.profile.isPending).toList();

            return RefreshIndicator(
              onRefresh: () async {
                _searchController.clear();
                await context.read<EmployeesCubit>().loadEmployees();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Metric Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.teamAndExpenses,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${state.employees.length} ${l10n.registeredUsersCount}',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.teamTotalSpent,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(state.totalCompanySpent),
                                  style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.totalOperations,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.totalCompanyTransactions}',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pending Registrations Banner (if any exist)
                  if (pendingEmployees.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pending_actions, color: Colors.amber, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.pendingRequestsTitle} (${pendingEmployees.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pendingEmployees.map((emp) {
                            final prof = emp.profile;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.amber.shade100,
                                    child: Text(
                                      prof.name.isNotEmpty ? prof.name[0].toUpperCase() : '?',
                                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prof.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          prof.email ?? '',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quick Action Buttons: Approve and Reject
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _confirmApproveUser(context, prof),
                                    child: Text(l10n.approveUser, style: const TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _confirmRejectUser(context, prof),
                                    child: Text(l10n.rejectUser, style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchEmployeeHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<EmployeesCubit>().searchEmployees('');
                              },
                            )
                          : null,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      context.read<EmployeesCubit>().searchEmployees(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(l10n.allRoles),
                          selected: state.roleFilter == null,
                          onSelected: (_) =>
                              context.read<EmployeesCubit>().filterByRole(null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.roleAdmin),
                          selected: state.roleFilter == 'admin',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByRole(selected ? 'admin' : null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.roleEmployee),
                          selected: state.roleFilter == 'employee',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByRole(selected ? 'employee' : null),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.divider,
                        ),
                        const SizedBox(width: 14),
                        FilterChip(
                          label: Text(l10n.statusActive),
                          selected: state.statusFilter == 'active',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByStatus(selected ? 'active' : null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.statusPending),
                          selected: state.statusFilter == 'pending',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByStatus(selected ? 'pending' : null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.statusInactive),
                          selected: state.statusFilter == 'inactive',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByStatus(selected ? 'inactive' : null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(l10n.statusRejected),
                          selected: state.statusFilter == 'rejected',
                          onSelected: (selected) => context
                              .read<EmployeesCubit>()
                              .filterByStatus(selected ? 'rejected' : null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Users List
                  if (employees.isEmpty) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.person_search_outlined,
                                size: 50,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.searchQuery.isNotEmpty
                                    ? '${l10n.noUsersFound}: "${state.searchQuery}"'
                                    : l10n.noUsersFound,
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...employees.map((EmployeeSummary emp) {
                      final profile = emp.profile;
                      final isAdmin = profile.isAdmin;
                      final isSelf = currentUserId != null && currentUserId == profile.id;
                      final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
                      final isActive = profile.isActive;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push('/employees/${profile.id}', extra: profile);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isAdmin
                                                    ? AppColors.secondaryDark
                                                    : AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  profile.name,
                                                  style: AppTextStyles.subtitle1.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Status Badge
                                              _buildStatusBadge(context, profile),
                                              const SizedBox(width: 4),
                                              // Role Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAdmin
                                                      ? AppColors.secondary.withValues(alpha: 0.15)
                                                      : AppColors.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isAdmin ? l10n.roleAdmin : l10n.roleEmployee,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAdmin
                                                        ? AppColors.secondaryDark
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile.email ?? '',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action Popup Menu
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) {
                                        if (val == 'approve') {
                                          _confirmApproveUser(context, profile);
                                        } else if (val == 'reject') {
                                          _confirmRejectUser(context, profile);
                                        } else if (val == 'role') {
                                          _confirmChangeRole(context, profile);
                                        } else if (val == 'status') {
                                          if (isSelf) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.cannotDeactivateSelf),
                                                backgroundColor: AppColors.warning,
                                              ),
                                            );
                                            return;
                                          }
                                          _confirmToggleStatus(context, profile);
                                        } else if (val == 'delete') {
                                          if (isSelf) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.cannotDeleteSelf),
                                                backgroundColor: AppColors.warning,
                                              ),
                                            );
                                            return;
                                          }
                                          _confirmDeleteUser(context, profile);
                                        }
                                      },
                                      itemBuilder: (popCtx) => [
                                        if (profile.isPending || profile.isRejected)
                                          PopupMenuItem(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                                                const SizedBox(width: 8),
                                                Text(l10n.approveUser, style: const TextStyle(color: AppColors.success)),
                                              ],
                                            ),
                                          ),
                                        if (profile.isPending)
                                          PopupMenuItem(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.cancel, size: 18, color: AppColors.error),
                                                const SizedBox(width: 8),
                                                Text(l10n.rejectUser, style: const TextStyle(color: AppColors.error)),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'role',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.shield_outlined, size: 18),
                                              const SizedBox(width: 8),
                                              Text(l10n.changeRole),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'status',
                                          child: Row(
                                            children: [
                                              Icon(
                                                isActive
                                                    ? Icons.block_outlined
                                                    : Icons.check_circle_outline,
                                                size: 18,
                                                color: isActive ? AppColors.warning : AppColors.success,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isActive ? l10n.deactivateUser : l10n.reactivateUser,
                                                style: TextStyle(
                                                  color: isActive ? AppColors.warning : AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete_forever_outlined,
                                                size: 18,
                                                color: AppColors.error,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.deleteUser,
                                                style: const TextStyle(color: AppColors.error),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.expenseAmountLabel,
                                          style: AppTextStyles.caption,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormat.format(emp.totalExpenses),
                                          style: AppTextStyles.subtitle1.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.totalOperations,
                                          style: AppTextStyles.caption,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${emp.expensesCount}',
                                          style: AppTextStyles.subtitle2.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () async {
                                        await context.push('/employees/${profile.id}', extra: profile);
                                        if (context.mounted) {
                                          context.read<EmployeesCubit>().loadEmployees();
                                        }
                                      },
                                      icon: const Icon(Icons.arrow_forward, size: 14),
                                      label: Text(l10n.viewExpenses, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                // Financial Allowance / Balance Rows (Multi-currency: EGP & USD)
                                BlocBuilder<AdminBalanceCubit, AdminBalanceState>(
                                  builder: (context, balanceState) {
                                    if (balanceState is AdminBalanceLoaded) {
                                      final summary = balanceState.employeeBalances
                                          .where((b) => b.userId == profile.id)
                                          .firstOrNull;
                                      if (summary != null) {
                                        return Container(
                                          margin: const EdgeInsets.only(top: 10),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              // EGP Row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'EGP: ${l10n.givenAmount}: ${summary.totalReceivedEgp.toStringAsFixed(0)}',
                                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.spentAmount}: ${summary.totalSpentEgp.toStringAsFixed(0)}',
                                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.remainingBalance}: ${summary.availableBalanceEgp.toStringAsFixed(0)} ج.م',
                                                    style: AppTextStyles.caption.copyWith(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: summary.availableBalanceEgp > 0
                                                          ? AppColors.success
                                                          : AppColors.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              // USD Row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'USD: ${l10n.givenAmount}: ${summary.totalReceivedUsd.toStringAsFixed(0)}',
                                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.spentAmount}: ${summary.totalSpentUsd.toStringAsFixed(0)}',
                                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                                  ),
                                                  Text(
                                                    '${l10n.remainingBalance}: \$${summary.availableBalanceUsd.toStringAsFixed(0)}',
                                                    style: AppTextStyles.caption.copyWith(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: summary.availableBalanceUsd > 0
                                                          ? AppColors.success
                                                          : AppColors.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                // Salary & Advances Row (Separated from expense allowance)
                                if (profile.salaryAmount > 0 || emp.totalAdvances > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${l10n.salary}: ${profile.salaryAmount.toStringAsFixed(0)} ${profile.salaryCurrency.code}',
                                          style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${l10n.salaryAdvances}: ${emp.totalAdvances.toStringAsFixed(0)} ${profile.salaryCurrency.code}',
                                          style: AppTextStyles.caption.copyWith(fontSize: 10, color: const Color(0xFFE17055), fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${l10n.remainingSalary}: ${emp.remainingSalary.toStringAsFixed(0)} ${profile.salaryCurrency.code}',
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF00B894),
                                          ),
                                        ),
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
                  const SizedBox(height: 80),
                ],
              ),
            );
          }

          if (state is EmployeesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.read<EmployeesCubit>().loadEmployees(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _AddUserModal extends StatefulWidget {
  const _AddUserModal({
    required this.onAddUser,
    required this.l10n,
  });

  final Future<void> Function(String email, String password, String name, String role)
      onAddUser;
  final AppLocalizations l10n;

  @override
  State<_AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<_AddUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'employee';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await widget.onAddUser(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      // Error handled by cubit / listener
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxSheetWidth),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.addUserTitle,
                    style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.fullNameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.fullNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.emailRequired;
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(val.trim())) {
                    return l10n.emailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (val.length < 6) {
                    return l10n.passwordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPasswordLabel,
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role selection
              Text(
                l10n.userRoleLabel,
                style: AppTextStyles.subtitle2,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'employee',
                    label: Text(l10n.roleEmployee),
                    icon: const Icon(Icons.person),
                  ),
                  ButtonSegment<String>(
                    value: 'admin',
                    label: Text(l10n.roleAdmin),
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: _isLoading
                    ? null
                    : (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.addUserButton),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
