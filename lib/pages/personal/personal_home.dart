import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/user_schedule_service.dart';
import '../../utility/notifications/notification_permission_prompt.dart';
import '../../utility/notifications/notification_subscription_service.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/notifications/web_notification_lifecycle.dart';
import '../../utility/pwa_install_service.dart';
import '../../widgets/personal/add_to_home_screen_dialog.dart';
import '../../widgets/personal/personal_action_section.dart';
import '../../widgets/personal/personal_admin_section.dart';
import '../../widgets/personal/personal_logout_section.dart';
import '../../widgets/personal/personal_profile_card.dart';
import '../../widgets/personal/personal_settings_section.dart';
import '../events/post_templates/view_templates_page.dart';
import 'guest_registration_page.dart';
import 'edit_profile_picture_page.dart';
import 'login_page.dart';
import 'notification_management_page.dart';
import 'share_web_app_page.dart';
import 'view_all_users_page.dart';
import 'view_my_posts_page.dart';
import 'view_user_roles_page.dart';
import 'manage_user_locations_page.dart';
import 'manage_user_tags_page.dart';
import 'manage_post_tags_page.dart';
import '../../utility/responsive_layout.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  @override
  void initState() {
    super.initState();
    // Web-only: suggest adding the PWA to the home screen once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) return;
      if (PwaInstallService.instance.isInstalled) return;
      if (widget.appContext.sharedPref.hasSeenPwaHomeScreenPrompt) return;
      _showAddToHomeScreenDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    context.select((AppContext c) => (c.sessionEpoch, c.headsEpoch));
    final appContext = widget.appContext;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final bool isWideScreen = ResponsiveLayout.isWideScreenOf(context);
        final double maxWidth = ResponsiveLayout.maxContentWidth(contentWidth);
        final double horizontalPadding = isWideScreen
            ? ((contentWidth - maxWidth) / 2).clamp(16.0, double.infinity)
            : 16.0;

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(
                'Personal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _ctrimLogo,
                    fit: BoxFit.contain,
                    height: kToolbarHeight,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.church_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 8, horizontalPadding, 32),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: isWideScreen
                        ? _buildWideBody(appContext, theme, colorScheme)
                        : _buildNarrowBody(appContext, theme, colorScheme),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowBody(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    final showAdmin = appContext.currentUser.canManagePostTemplates ||
        appContext.currentUser.canManageVolunteers;
    final peopleActions = _peopleActions(appContext, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalProfileCard(appContext: appContext, wide: false),
        const SizedBox(height: 24),
        PersonalActionSection(
          title: 'For you',
          actions: _forYouActions(appContext, theme, colorScheme),
          wide: false,
        ),
        if (peopleActions.isNotEmpty) ...[
          const SizedBox(height: 24),
          PersonalActionSection(
            title: 'People',
            actions: peopleActions,
            wide: false,
          ),
        ],
        if (showAdmin) ...[
          const SizedBox(height: 24),
          PersonalAdminSection(
            appContext: appContext,
            wide: false,
            onViewTemplates: _openViewTemplatesClick,
            onManageUserTags: _openManageUserTagsClick,
            onManagePostTags: _openManagePostTagsClick,
            onManageUserLocations: _openManageUserLocationsClick,
          ),
        ],
        const SizedBox(height: 24),
        PersonalSettingsSection(
          appContext: appContext,
          wide: false,
          onShareWebApp: _openShareWebAppClick,
        ),
        const SizedBox(height: 24),
        PersonalLogoutSection(onLogout: _onLogoutClick),
      ],
    );
  }

  Widget _buildWideBody(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final showAdmin = appContext.currentUser.canManagePostTemplates ||
        appContext.currentUser.canManageVolunteers;
    final actionColumns =
        MediaQuery.sizeOf(context).width >= ResponsiveLayout.desktop ? 3 : 2;
    final peopleActions = _peopleActions(appContext, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalProfileCard(appContext: appContext, wide: true),
        const SizedBox(height: 28),
        PersonalActionSection(
          title: 'For you',
          actions: _forYouActions(appContext, theme, colorScheme),
          wide: true,
          gridColumns: actionColumns,
        ),
        if (peopleActions.isNotEmpty) ...[
          const SizedBox(height: 28),
          PersonalActionSection(
            title: 'People',
            actions: peopleActions,
            wide: true,
            gridColumns: actionColumns,
          ),
        ],
        const SizedBox(height: 28),
        if (showAdmin)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PersonalAdminSection(
                  appContext: appContext,
                  wide: true,
                  gridColumns: 1,
                  onViewTemplates: _openViewTemplatesClick,
                  onManageUserTags: _openManageUserTagsClick,
                  onManagePostTags: _openManagePostTagsClick,
                  onManageUserLocations: _openManageUserLocationsClick,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: PersonalSettingsSection(
                  appContext: appContext,
                  wide: true,
                  gridColumns: 1,
                  onShareWebApp: _openShareWebAppClick,
                ),
              ),
            ],
          )
        else
          PersonalSettingsSection(
            appContext: appContext,
            wide: true,
            gridColumns: actionColumns,
            onShareWebApp: _openShareWebAppClick,
          ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PersonalLogoutSection(onLogout: _onLogoutClick),
          ),
        ),
      ],
    );
  }

  List<PersonalAction> _forYouActions(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <PersonalAction>[];

    if (appContext.isCurrentUserGuest) {
      actions.add(
        PersonalAction(
          icon: Icons.login_rounded,
          title: 'Sign In or Create Account',
          subtitle: 'Access your account or register',
          onTap: _onRegisterAccountClick,
          iconColor: colorScheme.primary,
        ),
      );
      return actions;
    }

    actions.add(
      PersonalAction(
        icon: Icons.checklist_rounded,
        title: l10n.mySchedule,
        subtitle: l10n.myScheduleSubtitle,
        trailing: _buildScheduleBadge(appContext, theme, colorScheme),
        onTap: _onViewTasksClick,
        iconColor: colorScheme.tertiary,
      ),
    );
    actions.add(
      PersonalAction(
        icon: Icons.notifications_active_rounded,
        title: 'Push Notifications',
        subtitle: 'Manage notification settings',
        onTap: _onNotificationManagerClick,
        iconColor: colorScheme.secondary,
      ),
    );
    if (!appContext.sharedPref.isFirstOpen &&
        appContext.sharedPref.fcmToken.isEmpty) {
      actions.add(
        PersonalAction(
          icon: Icons.notifications_none_rounded,
          title: 'Enable Notifications',
          subtitle: 'Get updates from CTRIM',
          onTap: () => _onEnableNotificationsClick(appContext),
          iconColor: colorScheme.tertiary,
        ),
      );
    }
    actions.addAll([
      PersonalAction(
        icon: Icons.article_rounded,
        title: 'My Posts',
        subtitle: 'View your created posts',
        onTap: _onOpenPostsClick,
        iconColor: colorScheme.primary,
      ),
      PersonalAction(
        icon: Icons.account_circle_outlined,
        title: 'Profile picture',
        subtitle: 'Update your photo URL',
        onTap: _onUserProfileClick,
        iconColor: colorScheme.primary,
      ),
    ]);

    return actions;
  }

  List<PersonalAction> _peopleActions(
      AppContext appContext, ColorScheme colorScheme) {
    if (appContext.isCurrentUserGuest) return const [];

    final l10n = AppLocalizations.of(context)!;
    return [
      PersonalAction(
        icon: Icons.people_rounded,
        title: l10n.volunteersMenuTitle,
        subtitle: l10n.volunteersMenuSubtitle,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ViewAllUsersPage())),
        iconColor: colorScheme.secondary,
      ),
    ];
  }

  Widget? _buildScheduleBadge(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    if (appContext.currentUser.roles == null) return null;

    final upcomingCount = UserScheduleService.upcomingPostCount(
      user: appContext.currentUser,
      eventHeads: appContext.eventHeads,
    );
    if (upcomingCount == 0) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$upcomingCount',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // * Logic
  void _showAddToHomeScreenDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddToHomeScreenDialog(),
    ).then((_) {
      widget.appContext.sharedPref.setHasSeenPwaHomeScreenPrompt();
    });
  }

  void _onLogoutClick() async {
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out of your account?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );

    if (confirmed) {
      if (!mounted) return;

      final signedOut = await DialogManager.runWithSteppedProgressDialog(
        context: context,
        title: 'Signing Out',
        initialMessage: 'Removing notification token…',
        errorTitle: 'Could not sign out',
        action: (onProgress) async {
          widget.appContext.analytics.logEvent(name: 'logout');
          await _logout(onProgress);
        },
      );
      if (!mounted || !signedOut) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginPage()))
          .then((_) {
        setState(() {});
      });
    }
  }

  Future<void> _logout(LoadProgressReporter onProgress) async {
    const total = 3;
    final AuthManager authManager = AuthManager();
    final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
    final token = widget.appContext.sharedPref.fcmToken;
    debugPrint('token to remove is $token');

    onProgress(
        completed: 0, total: total, message: 'Removing notification token…');
    if (kIsWeb && token.isNotEmpty) {
      await WebNotificationLifecycle()
          .unregister(authId: authManager.currentAuthUID, token: token);
    } else if (token.isNotEmpty) {
      await everyoneDBManager.removeTokenForAuthID(
          authManager.currentAuthUID, token);
    }

    onProgress(completed: 1, total: total, message: 'Clearing local session…');
    widget.appContext.sharedPref.clearCreds();
    widget.appContext.setUserToGuest();
    widget.appContext.sharedPref.setLoggedOut(true);

    onProgress(completed: 2, total: total, message: 'Signing out…');
    await authManager.signOut();
  }

  void _onViewTasksClick() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewUserRolesPage(
                  selectedUser: widget.appContext.currentUser,
                )));
  }

  void _onNotificationManagerClick() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationManagementPage()));
  }

  void _onUserProfileClick() {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EditProfilePicturePage()))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onOpenPostsClick() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ViewMyPostsPage()));
  }

  void _openShareWebAppClick() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ShareWebAppPage()));
  }

  void _openViewTemplatesClick() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ViewTemplatesPage()));
  }

  void _openManageUserTagsClick() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ManageUserTagsPage()));
  }

  void _openManageUserLocationsClick() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ManageUserLocationsPage()));
  }

  void _openManagePostTagsClick() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ManagePostTagsPage()));
  }

  void _onRegisterAccountClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GuestRegistrationPage(),
      ),
    ).then((_) {
      // Refresh the page in case user registered
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _onEnableNotificationsClick(AppContext appContext) async {
    final authId = AuthManager().currentAuthUID;
    final pwa = PwaInstallService.instance;

    final result = await NotificationPermissionPrompt.promptAndRegister(
      context: context,
      prefs: appContext.sharedPref,
      authId: authId,
      isGuest: appContext.isCurrentUserGuest,
    );

    if (result.isEnabled) {
      appContext.sharedPref.setSubscribedToBelfast(true);

      final webAuthId =
          kIsWeb && !appContext.isCurrentUserGuest ? authId : null;
      final reconcile = await NotificationSubscriptionService().reconcile(
        prefs: appContext.sharedPref,
        webAuthId: webAuthId,
      );

      if (!mounted) return;
      final ok = reconcile.failed == 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '✓ Notifications enabled (${reconcile.succeeded} topics).'
                : 'Token saved, but ${reconcile.failed} topic(s) failed. '
                    'Open Push Notifications → This device to repair.',
          ),
          backgroundColor: ok ? Colors.green : Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {});
      return;
    }

    if (!mounted) return;
    if (result.outcome == NotificationPromptOutcome.declined ||
        result.outcome == NotificationPromptOutcome.blockedByPwa) {
      return;
    }

    final hint = kIsWeb && pwa.isIosBrowser && !pwa.isInstalled
        ? 'On iPhone/iPad, open CTRIM from the Home Screen app and try again.'
        : 'Could not enable notifications. Check permission and try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(hint), duration: const Duration(seconds: 4)),
    );
  }
}
