import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/admin_notification.dart';
import '../../../domain/entities/profile.dart';
import '../../../injection/injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/notifications/admin_notification_cubit.dart';
import '../../cubits/notifications/admin_notification_state.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../cubits/settings/admin_settings_cubit.dart';
import '../../cubits/settings/admin_settings_state.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';
import '../../widgets/spendly_logo.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<ProfileCubit>()..loadProfile()),
        BlocProvider(create: (context) => sl<AdminSettingsCubit>()..loadSettings()),
        BlocProvider(create: (context) => sl<AdminNotificationCubit>()..loadNotifications()),
      ],
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  void _showNotificationsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationCubit = context.read<AdminNotificationCubit>();
    notificationCubit.loadNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: BlocBuilder<AdminNotificationCubit, AdminNotificationState>(
            bloc: notificationCubit,
            builder: (context, state) {
              final notifications = (state is AdminNotificationLoaded)
                  ? state.notifications
                  : <AdminNotification>[];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.notificationsTitle,
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            notificationCubit.markAllAsRead();
                          },
                          child: Text(l10n.markAllAsRead),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(l10n.noNotifications, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: item.isRead
                                  ? AppColors.surfaceVariant
                                  : AppColors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.person_add,
                                size: 20,
                                color: item.isRead ? AppColors.textSecondary : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(item.message, style: AppTextStyles.caption),
                            trailing: !item.isRead
                                ? const CircleAvatar(radius: 4, backgroundColor: AppColors.primary)
                                : null,
                            onTap: () {
                              notificationCubit.markAsRead(item.id);
                              Navigator.pop(sheetCtx);
                              context.push(AppRoutes.employees);
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProfileCubit>();
    final controller = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.editNameTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.fullNameLabel,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                cubit.updateName(newName);
              }
              Navigator.pop(dialogCtx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, Profile profile) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProfileCubit>();
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.profileImageTitle,
                style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text(l10n.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    cubit.uploadAvatar(File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text(l10n.takePhoto),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    cubit.uploadAvatar(File(picked.path));
                  }
                },
              ),
              if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    l10n.removePhoto,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    cubit.removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsCubit = context.read<SettingsCubit>();
    final currentCode = settingsCubit.state.locale.languageCode;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.languageArabic),
              trailing: currentCode == 'ar'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                settingsCubit.setLocale(const Locale('ar'));
                Navigator.pop(dialogCtx);
              },
            ),
            ListTile(
              title: Text(l10n.languageEnglish),
              trailing: currentCode == 'en'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                settingsCubit.setLocale(const Locale('en'));
                Navigator.pop(dialogCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsCubit = context.read<SettingsCubit>();
    final currentMode = settingsCubit.state.themeMode;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.themeLight),
              trailing: currentMode == ThemeMode.light
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                settingsCubit.setThemeMode(ThemeMode.light);
                Navigator.pop(dialogCtx);
              },
            ),
            ListTile(
              title: Text(l10n.themeDark),
              trailing: currentMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                settingsCubit.setThemeMode(ThemeMode.dark);
                Navigator.pop(dialogCtx);
              },
            ),
            ListTile(
              title: Text(l10n.themeSystem),
              trailing: currentMode == ThemeMode.system
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                settingsCubit.setThemeMode(ThemeMode.system);
                Navigator.pop(dialogCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
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
              sl<AuthCubit>().signOut();
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          BlocBuilder<AdminNotificationCubit, AdminNotificationState>(
            builder: (context, state) {
              final unreadCount = (state is AdminNotificationLoaded) ? state.unreadCount : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: l10n.notificationsTitle,
                    onPressed: () => _showNotificationsSheet(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            sl<AuthCubit>().reloadProfile();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.profileUpdateSuccess),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Profile? profile;
          final bool isUpdating = state is ProfileUpdating;

          if (state is ProfileLoaded) {
            profile = state.profile;
          } else if (state is ProfileUpdating) {
            profile = state.currentProfile;
          }

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.userLoadFailed),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final userProfile = profile;
          final isAdmin = userProfile.isAdmin;
          final hasAvatar = userProfile.avatarUrl != null && userProfile.avatarUrl!.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // User Avatar & Name Banner
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isAdmin ? AppColors.secondaryDark : AppColors.primary,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: hasAvatar
                                ? CachedNetworkImage(
                                    imageUrl: userProfile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => _buildInitialAvatar(userProfile, isAdmin),
                                  )
                                : _buildInitialAvatar(userProfile, isAdmin),
                          ),
                        ),
                        if (isUpdating)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: isUpdating ? null : () => _showAvatarOptions(context, userProfile),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      userProfile.name,
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile.email ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        isAdmin ? l10n.roleAdmin : l10n.roleEmployee,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? AppColors.secondaryDark : AppColors.primary,
                        ),
                      ),
                      backgroundColor: isAdmin
                          ? AppColors.secondary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Admin Settings Card (Visible ONLY for Administrators)
              if (isAdmin) ...[
                Text(
                  l10n.adminSettingsSection,
                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
                    builder: (context, adminSettingsState) {
                      final bool isRequireApproval = (adminSettingsState is AdminSettingsLoaded)
                          ? adminSettingsState.requireAdminApproval
                          : false;
                      final bool isUpdatingApproval = (adminSettingsState is AdminSettingsLoaded)
                          ? adminSettingsState.isUpdating
                          : false;

                      return SwitchListTile(
                        secondary: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
                        title: Text(
                          l10n.requireAdminApproval,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          l10n.requireAdminApprovalDesc,
                          style: AppTextStyles.caption,
                        ),
                        value: isRequireApproval,
                        onChanged: isUpdatingApproval
                            ? null
                            : (val) {
                                context.read<AdminSettingsCubit>().toggleRequireAdminApproval(val);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Profile Details Card
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AppColors.primary),
                      title: Text(l10n.fullNameLabel, style: AppTextStyles.caption),
                      subtitle: Text(
                        userProfile.name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditNameDialog(context, userProfile),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                      title: Text(l10n.emailLabel, style: AppTextStyles.caption),
                      subtitle: Text(
                        userProfile.email ?? l10n.unspecified,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    if (userProfile.createdAt != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                        title: Text(l10n.joinedDateLabel, style: AppTextStyles.caption),
                        subtitle: Text(
                          dateFormat.format(userProfile.createdAt!),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferences & Security Card
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        final langLabel = settingsState.isArabic
                            ? l10n.languageArabic
                            : l10n.languageEnglish;

                        return ListTile(
                          leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                          title: Text(
                            l10n.languageLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            langLabel,
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () => _showLanguageDialog(context),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        String themeLabel = l10n.themeLight;
                        if (settingsState.themeMode == ThemeMode.dark) {
                          themeLabel = l10n.themeDark;
                        } else if (settingsState.themeMode == ThemeMode.system) {
                          themeLabel = l10n.themeSystem;
                        }

                        return ListTile(
                          leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                          title: Text(
                            l10n.themeLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            themeLabel,
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () => _showThemeDialog(context),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                      title: Text(
                        l10n.changePasswordTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.changePasswordSubtitle,
                        style: AppTextStyles.caption,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push(AppRoutes.changePassword),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.logout),
                label: Text(l10n.logout),
                onPressed: () => _confirmSignOut(context),
              ),
              const SizedBox(height: 32),

              // App Version Info
              Center(
                child: Column(
                  children: [
                    const SpendlyLogo(size: 32, showText: false),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.appName} v1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitialAvatar(Profile profile, bool isAdmin) {
    return Container(
      color: isAdmin
          ? AppColors.secondary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name.characters.first.toUpperCase() : 'U',
          style: AppTextStyles.heading1.copyWith(
            color: isAdmin ? AppColors.secondaryDark : AppColors.primary,
            fontSize: 36,
          ),
        ),
      ),
    );
  }
}
