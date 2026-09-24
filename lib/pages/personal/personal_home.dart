import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user_role_assignment.dart';
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
import '../../widgets/personal/personal_cell_groups_preview_card.dart';
import '../../widgets/personal/personal_schedule_preview_card.dart';
import '../../widgets/personal/personal_settings_section.dart';
import '../../widgets/two_column_masonry.dart';
import '../events/post_templates/view_templates_page.dart';
import 'guest_registration_page.dart';
import 'edit_profile_picture_page.dart';
import 'login_page.dart';
import 'notification_management_page.dart';
import 'share_web_app_page.dart';
import 'view_all_users_page.dart';
import 'view_my_posts_page.dart';
import 'view_team_rota_page.dart';
import 'manage_user_locations_page.dart';
import 'manage_user_tags_page.dart';
import 'manage_post_tags_page.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/schedule_heads.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({
    super.key,
    required this.appContext,
    this.onBrowseCellGroups,
  });
  final AppContext appContext;
  final VoidCallback? onBrowseCellGroups;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  final UserScheduleService _scheduleService = UserScheduleService();
  bool _loadingScheduleRoles = false;
  final Map<String, EventHead> _scheduleExtraHeads = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureCurrentUserScheduleRolesLoaded();
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
                        ? _buildWideBody(appContext, colorScheme)
                        : _buildNarrowBody(appContext, colorScheme),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowBody(AppContext appContext, ColorScheme colorScheme) {
    final showAdmin = appContext.currentUser.canManagePostTemplates ||
        appContext.currentUser.canManageVolunteers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalProfileCard(appContext: appContext, wide: false),
        if (!appContext.isCurrentUserGuest) ...[
          const SizedBox(height: 24),
          _buildDashboardCards(appContext, wide: false),
        ],
        const SizedBox(height: 24),
        PersonalActionSection(
          title: 'For you',
          actions: _forYouActions(appContext, colorScheme),
          wide: false,
        ),
        const SizedBox(height: 24),
        PersonalActionSection(
          title: AppLocalizations.of(context)!.peopleAndTeamsSectionTitle,
          actions: _peopleAndTeamsActions(appContext, colorScheme),
          wide: false,
        ),
        if (showAdmin) ...[
          const SizedBox(height: 24),
          PersonalAdminSection(
            appContext: appContext,
            wide: false,
            onViewTemplates: _openViewTemplatesClick,
            onManagePostTags: _openManagePostTagsClick,
            onManageUserLocations: _openManageUserLocationsClick,
          ),
        ],
        const SizedBox(height: 24),
        PersonalSettingsSection(
          appContext: appContext,
          wide: false,
          onPushNotifications: appContext.isCurrentUserGuest
              ? null
              : _onNotificationManagerClick,
          onEnableNotifications: _enableNotificationsAction(appContext),
        ),
        const SizedBox(height: 24),
        PersonalLogoutSection(onLogout: _onLogoutClick),
      ],
    );
  }

  Widget _buildWideBody(AppContext appContext, ColorScheme colorScheme) {
    final showAdmin = appContext.currentUser.canManagePostTemplates ||
        appContext.currentUser.canManageVolunteers;
    final actionColumns =
        MediaQuery.sizeOf(context).width >= ResponsiveLayout.desktop ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalProfileCard(appContext: appContext, wide: true),
        if (!appContext.isCurrentUserGuest) ...[
          const SizedBox(height: 28),
          _buildDashboardCards(appContext, wide: true),
        ],
        const SizedBox(height: 28),
        PersonalActionSection(
          title: 'For you',
          actions: _forYouActions(appContext, colorScheme),
          wide: true,
          gridColumns: actionColumns,
        ),
        const SizedBox(height: 28),
        PersonalActionSection(
          title: AppLocalizations.of(context)!.peopleAndTeamsSectionTitle,
          actions: _peopleAndTeamsActions(appContext, colorScheme),
          wide: true,
          gridColumns: actionColumns,
        ),
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
                  onPushNotifications: appContext.isCurrentUserGuest
                      ? null
                      : _onNotificationManagerClick,
                  onEnableNotifications: _enableNotificationsAction(appContext),
                ),
              ),
            ],
          )
        else
          PersonalSettingsSection(
            appContext: appContext,
            wide: true,
            gridColumns: actionColumns,
            onPushNotifications: appContext.isCurrentUserGuest
                ? null
                : _onNotificationManagerClick,
            onEnableNotifications: _enableNotificationsAction(appContext),
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

  Widget _buildDashboardCards(AppContext appContext, {required bool wide}) {
    final scheduleCard = PersonalSchedulePreviewCard(
      appContext: appContext,
      extraHeads: _scheduleExtraHeads,
    );
    final cellGroupsCard = PersonalCellGroupsPreviewCard(
      appContext: appContext,
      onBrowseCellGroups: widget.onBrowseCellGroups,
    );

    if (wide) {
      return TwoColumnMasonry(
        children: [scheduleCard, cellGroupsCard],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scheduleCard,
        const SizedBox(height: 16),
        cellGroupsCard,
      ],
    );
  }

  List<PersonalAction> _forYouActions(
      AppContext appContext, ColorScheme colorScheme) {
    final actions = <PersonalAction>[];
    final shareAndGuide = [
      PersonalAction(
        icon: Icons.share_rounded,
        title: 'Share Web App',
        subtitle: 'Share link or add to home screen',
        onTap: _openShareWebAppClick,
        iconColor: colorScheme.tertiary,
      ),
      PersonalAction(
        icon: Icons.menu_book_rounded,
        title: 'Product guide',
        subtitle: 'How the app works — open to everyone',
        onTap: () => launchUrlString(PersonalSettingsSection.productGuideUrl),
        iconColor: colorScheme.primary,
      ),
    ];

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
      actions.addAll(shareAndGuide);
      return actions;
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
      ...shareAndGuide,
    ]);

    return actions;
  }

  List<PersonalAction> _peopleAndTeamsActions(
      AppContext appContext, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <PersonalAction>[];

    if (!appContext.isCurrentUserGuest) {
      actions.add(
        PersonalAction(
          icon: Icons.people_rounded,
          title: l10n.volunteersMenuTitle,
          subtitle: l10n.volunteersMenuSubtitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ViewAllUsersPage())),
          iconColor: colorScheme.secondary,
        ),
      );
      actions.add(
        PersonalAction(
          icon: Icons.groups_rounded,
          title: l10n.teamRota,
          subtitle: l10n.teamRotaSubtitle,
          onTap: _onOpenTeamRotaClick,
          iconColor: colorScheme.tertiary,
        ),
      );
    }

    actions.add(
      PersonalAction(
        icon: Icons.label_rounded,
        title: l10n.manageUserTagsMenuTitle,
        subtitle: l10n.userTagsBrowseSubtitle,
        onTap: _openManageUserTagsClick,
        iconColor: colorScheme.primary,
      ),
    );

    return actions;
  }

  VoidCallback? _enableNotificationsAction(AppContext appContext) {
    if (appContext.isCurrentUserGuest) return null;
    if (appContext.sharedPref.isFirstOpen ||
        appContext.sharedPref.fcmToken.isNotEmpty) {
      return null;
    }
    return () => _onEnableNotificationsClick(appContext);
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

  Future<void> _ensureCurrentUserScheduleRolesLoaded() async {
    if (widget.appContext.isCurrentUserGuest) return;
    if (widget.appContext.currentUser.roles != null) return;
    if (_loadingScheduleRoles) return;

    setState(() => _loadingScheduleRoles = true);
    try {
      final user = widget.appContext.currentUser;
      final roles = await _scheduleService.fetchRoles(user.id);
      user.setRoles(roles);
      final extra = await ScheduleHeads.fetchMissing(
        postIDs: roles.map((role) => role.postID),
        knownHeads: [
          ...widget.appContext.eventHeads,
          ..._scheduleExtraHeads.values,
        ],
      );
      if (extra.isNotEmpty) {
        _scheduleExtraHeads.addAll(extra);
      }
      await _scheduleService.pruneStaleRoles(
        user: user,
        eventHeads: ScheduleHeads.merge(
          sessionHeads: widget.appContext.eventHeads,
          extraHeads: _scheduleExtraHeads,
        ),
      );
      if (!mounted) return;
      widget.appContext
          .setCurrentUserRoles(List<UserRoleAssignment>.from(user.roles!));
    } catch (e, st) {
      debugPrint('Could not preload schedule roles: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _loadingScheduleRoles = false);
      }
    }
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

  void _onOpenTeamRotaClick() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ViewTeamRotaPage()));
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
