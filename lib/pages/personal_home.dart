import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../firebase/auth_manager.dart';
import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/messaging_manager.dart';
import '../src/localization/app_localizations.dart';
import '../utility/app_context.dart';
import '../utility/user_schedule_service.dart';
import '../utility/web_notification_lifecycle.dart';
import '../utility/notification_subscription_service.dart';
import '../utility/notification_topics.dart';
import '../utility/dialog_manager.dart';
import '../widgets/user_avatar.dart';
import '../utility/pwa_install_service.dart';
import '../widgets/personal/add_to_home_screen_dialog.dart';
import 'events/post_templates/view_templates_page.dart';
import 'personal/guest_registration_page.dart';
import 'personal/edit_profile_picture_page.dart';
import 'personal/login_page.dart';
import 'personal/notification_management_page.dart';
import 'personal/share_web_app_page.dart';
import 'personal/view_all_users_page.dart';
import 'personal/view_my_posts_page.dart';
import 'personal/view_user_roles_page.dart';
import 'personal/manage_user_locations_page.dart';
import 'personal/manage_user_tags_page.dart';
import 'personal/manage_post_tags_page.dart';
import '../utility/responsive_layout.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  static const String _slideDeckUtilsUrl =
      'https://church-slidedeck-utils.streamlit.app/';
  static const String _stakeholderDocsUrl =
      'https://deigoc.github.io/ctrim_app/';
  // static const String _readmeUrl = 'https://www.craft.me/s/D1p8C4tzitcOwY';

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

    return Consumer<AppContext>(
      builder: (context, appContext, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth = constraints.maxWidth;
            final bool isWideScreen =
                ResponsiveLayout.isWideScreen(contentWidth);
            final double maxWidth =
                ResponsiveLayout.maxContentWidth(contentWidth);
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
                            ? _buildWideBody(
                                appContext, theme, colorScheme, contentWidth)
                            : _buildNarrowBody(appContext, theme, colorScheme),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNarrowBody(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!appContext.isCurrentUserGuest) ...[
          _buildUserProfileCard(appContext, theme, colorScheme, wide: false),
          const SizedBox(height: 24),
        ],
        _buildMainActionsSection(appContext, theme, colorScheme, wide: false),
        const SizedBox(height: 24),
        if (appContext.currentUser.canManagePostTemplates ||
            appContext.currentUser.canManageVolunteers) ...[
          _buildAdminSection(appContext, theme, colorScheme, wide: false),
          const SizedBox(height: 24),
        ],
        _buildAppLegalSection(appContext, theme, colorScheme, wide: false),
        const SizedBox(height: 24),
        _buildLogoutSection(theme, colorScheme),
      ],
    );
  }

  Widget _buildWideBody(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme,
    double contentWidth,
  ) {
    final showAdmin =
        appContext.currentUser.canManagePostTemplates ||
            appContext.currentUser.canManageVolunteers;
    final actionColumns = contentWidth >= ResponsiveLayout.desktop ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!appContext.isCurrentUserGuest) ...[
          _buildUserProfileCard(appContext, theme, colorScheme, wide: true),
          const SizedBox(height: 28),
        ],
        _buildMainActionsSection(
          appContext,
          theme,
          colorScheme,
          wide: true,
          gridColumns: actionColumns,
        ),
        const SizedBox(height: 28),
        if (showAdmin)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAdminSection(
                  appContext,
                  theme,
                  colorScheme,
                  wide: true,
                  gridColumns: 1,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildAppLegalSection(
                  appContext,
                  theme,
                  colorScheme,
                  wide: true,
                  gridColumns: 1,
                ),
              ),
            ],
          )
        else
          _buildAppLegalSection(
            appContext,
            theme,
            colorScheme,
            wide: true,
            gridColumns: actionColumns,
          ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildLogoutSection(theme, colorScheme),
          ),
        ),
      ],
    );
  }

  // * UI Components

  Widget _buildUserProfileCard(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool wide,
  }) {
    final double avatarRadius = wide ? 40 : 28;
    final EdgeInsets padding = wide
        ? const EdgeInsets.symmetric(horizontal: 28, vertical: 24)
        : const EdgeInsets.all(20);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Hero(
              tag: 'user_avatar_${appContext.currentUser.id}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MyUserAvatar(
                  appContext.currentUser,
                  radius: avatarRadius,
                ),
              ),
            ),
            SizedBox(width: wide ? 24 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${appContext.currentUser.forname}! 👋',
                    style: (wide
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.titleLarge)
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appContext.currentUser.location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (appContext.currentUser.isAreaAdmin) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PersonalAction> _quickActions(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <_PersonalAction>[];

    if (appContext.isCurrentUserGuest) {
      actions.add(
        _PersonalAction(
          icon: Icons.person_add_rounded,
          title: 'Create Account',
          subtitle: 'Sign up or sign in',
          onTap: _onRegisterAccountClick,
          iconColor: colorScheme.primary,
        ),
      );
    }

    if (!appContext.isCurrentUserGuest) {
      actions.add(
        _PersonalAction(
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
          _PersonalAction(
            icon: Icons.notifications_none_rounded,
            title: 'Enable Notifications',
            subtitle: 'Get updates from CTRIM',
            onTap: () => _onEnableNotificationsClick(appContext),
            iconColor: colorScheme.tertiary,
          ),
        );
      }
      actions.addAll([
        _PersonalAction(
          icon: Icons.checklist_rounded,
          title: l10n.mySchedule,
          subtitle: l10n.myScheduleSubtitle,
          trailing: _buildScheduleBadge(appContext, theme, colorScheme),
          onTap: _onViewTasksClick,
          iconColor: colorScheme.tertiary,
        ),
        _PersonalAction(
          icon: Icons.account_circle_outlined,
          title: 'Profile picture',
          subtitle: 'Update your photo URL',
          onTap: _onUserProfileClick,
          iconColor: colorScheme.primary,
        ),
        _PersonalAction(
          icon: Icons.article_rounded,
          title: 'My Posts',
          subtitle: 'View your created posts',
          onTap: _onOpenPostsClick,
          iconColor: colorScheme.primary,
        ),
        _PersonalAction(
          icon: Icons.people_rounded,
          title: l10n.volunteersMenuTitle,
          subtitle: l10n.volunteersMenuSubtitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ViewAllUsersPage())),
          iconColor: colorScheme.secondary,
        ),
        _PersonalAction(
          icon: Icons.menu_book_rounded,
          title: 'Product guide',
          subtitle: 'How the app works — for volunteers and leaders',
          onTap: () => launchUrlString(_stakeholderDocsUrl),
          iconColor: colorScheme.primary,
        ),
      ]);
    }

    if (kIsWeb) {
      actions.add(
        _PersonalAction(
          icon: Icons.no_accounts_rounded,
          title: 'Account Deletion Request',
          subtitle: 'Request account removal',
          onTap: () => launchUrlString('https://ctrim-account-removal.web.app'),
          iconColor: colorScheme.error,
        ),
      );
    }

    return actions;
  }

  Widget _buildMainActionsSection(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool wide,
    int gridColumns = 2,
  }) {
    final actions = _quickActions(appContext, theme, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (wide)
          _buildActionGrid(actions, theme, colorScheme, columns: gridColumns)
        else
          _buildActionListCard(actions, theme, colorScheme),
      ],
    );
  }

  List<_PersonalAction> _adminActions(
      AppContext appContext, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <_PersonalAction>[];
    if (appContext.currentUser.canManagePostTemplates) {
      actions.add(
        _PersonalAction(
          icon: Icons.newspaper_rounded,
          title: 'Post Templates',
          subtitle: 'Create and edit post templates',
          onTap: _openViewTemplatesClick,
          iconColor: colorScheme.primary,
        ),
      );
    }
    if (appContext.currentUser.canManageVolunteers) {
      actions.add(
        _PersonalAction(
          icon: Icons.label_rounded,
          title: l10n.manageUserTagsMenuTitle,
          subtitle: l10n.manageUserTagsMenuSubtitle,
          onTap: _openManageUserTagsClick,
          iconColor: colorScheme.primary,
        ),
      );
      actions.add(
        _PersonalAction(
          icon: Icons.style_rounded,
          title: l10n.managePostTagsMenuTitle,
          subtitle: l10n.managePostTagsMenuSubtitle,
          onTap: _openManagePostTagsClick,
          iconColor: colorScheme.primary,
        ),
      );
      actions.add(
        _PersonalAction(
          icon: Icons.location_on_rounded,
          title: l10n.manageUserLocationsMenuTitle,
          subtitle: l10n.manageUserLocationsMenuSubtitle,
          onTap: _openManageUserLocationsClick,
          iconColor: colorScheme.primary,
        ),
      );
    }
    return actions;
  }

  Widget _buildAdminSection(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool wide,
    int gridColumns = 1,
  }) {
    final showTemplates = appContext.currentUser.canManagePostTemplates;
    final showUserTags = appContext.currentUser.canManageVolunteers;
    final sectionTitle = showUserTags && !showTemplates
        ? 'Admin Tools'
        : showTemplates && !showUserTags
            ? 'Leader Tools'
            : 'Admin Tools';
    final actions = _adminActions(appContext, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (wide)
          _buildActionGrid(actions, theme, colorScheme, columns: gridColumns)
        else
          _buildActionListCard(actions, theme, colorScheme),
      ],
    );
  }

  List<_PersonalAction> _appLegalActions(
      AppContext appContext, ColorScheme colorScheme) {
    final actions = <_PersonalAction>[];

    if (!appContext.isCurrentUserGuest) {
      final currentTab = appContext.sharedPref.preferredStartupTab;
      final tabName = currentTab == 0
          ? 'Events'
          : currentTab == 2
              ? 'Cell Groups'
              : currentTab == 3
                  ? 'Personal'
                  : 'Information';
      actions.add(
        _PersonalAction(
          icon: Icons.home_rounded,
          title: 'Startup Tab',
          subtitle: 'Opens to: $tabName',
          onTap: () {
            HapticFeedback.lightImpact();
            _showStartupTabDialog(appContext, Theme.of(context), colorScheme);
          },
          iconColor: colorScheme.tertiary,
        ),
      );
    }

    actions.addAll([
      _PersonalAction(
        icon: Icons.share_rounded,
        title: 'Share Web App',
        subtitle: 'Share link or add to home screen',
        onTap: _openShareWebAppClick,
        iconColor: colorScheme.tertiary,
      ),
      _PersonalAction(
        icon: Icons.slideshow_rounded,
        title: 'Slide Deck Utils',
        subtitle: 'Create slides or extract text from PDF/PPTX',
        onTap: () => launchUrlString(_slideDeckUtilsUrl),
        iconColor: colorScheme.primary,
      ),
      _PersonalAction(
        icon: Icons.privacy_tip_rounded,
        title: 'Privacy Policy',
        subtitle: 'View our privacy policy',
        onTap: () => launchUrlString(
            'https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b'),
        iconColor: colorScheme.secondary,
      ),
      _PersonalAction(
        icon: Icons.contact_page_rounded,
        title: 'Terms and Conditions',
        subtitle: 'View terms and conditions',
        onTap: () =>
            launchUrlString('https://ctrim-terms-and-conditions.web.app'),
        iconColor: colorScheme.primary,
      ),
    ]);

    return actions;
  }

  Widget _buildAppLegalSection(
    AppContext appContext,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool wide,
    int gridColumns = 1,
  }) {
    final actions = _appLegalActions(appContext, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'App & Legal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (wide)
          _buildActionGrid(actions, theme, colorScheme, columns: gridColumns)
        else
          _buildActionListCard(actions, theme, colorScheme),
      ],
    );
  }

  Widget _buildActionListCard(
    List<_PersonalAction> actions,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            _buildModernListTile(
              icon: actions[i].icon,
              title: actions[i].title,
              subtitle: actions[i].subtitle,
              onTap: actions[i].onTap,
              theme: theme,
              colorScheme: colorScheme,
              iconColor: actions[i].iconColor,
              trailing: actions[i].trailing,
              isFirst: i == 0,
              isLast: i == actions.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionGrid(
    List<_PersonalAction> actions,
    ThemeData theme,
    ColorScheme colorScheme, {
    required int columns,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final itemWidth = columns <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _buildActionGridCard(action, theme, colorScheme),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionGridCard(
    _PersonalAction action,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: action.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.iconColor,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (action.trailing != null)
                    action.trailing!
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                action.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStartupTabDialog(
      AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    final currentTab = appContext.sharedPref.preferredStartupTab;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Startup Tab'),
          content: RadioGroup<int>(
            groupValue: currentTab,
            onChanged: (value) {
              if (value != null) {
                appContext.sharedPref.setPreferredStartupTab(value);
                appContext.rebuildPlease();
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: const Text('Events'),
                  subtitle: const Text('Open to the Posts/Bulletin tab'),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: const Text('Information'),
                  subtitle: const Text('Open to the CTRIM Information tab'),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: const Text('Cell Groups'),
                  subtitle: const Text('Open to the Cell Groups tab'),
                  value: 2,
                ),
                RadioListTile<int>(
                  title: const Text('Personal'),
                  subtitle: const Text('Open to the Personal tab'),
                  value: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.errorContainer,
          width: 1,
        ),
      ),
      child: _buildModernListTile(
        icon: Icons.logout_rounded,
        title: 'Sign Out',
        subtitle: 'Sign out of your account',
        onTap: _onLogoutClick,
        theme: theme,
        colorScheme: colorScheme,
        iconColor: colorScheme.error,
        isFirst: true,
        isLast: true,
      ),
    );
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

  Widget _buildModernListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color iconColor,
    Widget? trailing,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ] else ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
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
    widget.appContext.rebuildPlease();
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
    final MessagingManager messagingManager = MessagingManager();
    final authId = AuthManager().currentAuthUID;
    final pwa = PwaInstallService.instance;

    if (kIsWeb && pwa.isIosBrowser && !pwa.isInstalled) {
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Add to Home Screen first',
        content:
            'On iPhone and iPad, web push only works when CTRIM is opened from '
            'the Home Screen. Use Share → Add to Home Screen, open that icon, '
            'then enable notifications.',
        icon: Icons.install_mobile_outlined,
      );
      return;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Get notified about important updates, events, and announcements from CTRIM. You can manage your notification preferences anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    String? token;
    if (kIsWeb && authId.isNotEmpty && !appContext.isCurrentUserGuest) {
      token = await WebNotificationLifecycle().register(
        authId: authId,
        requestPermission: true,
        onTokenSaved: appContext.sharedPref.saveFCMToken,
        prefs: appContext.sharedPref,
        webAuthId: authId,
      );
    } else {
      token = await messagingManager.requestPermissionAndToken();
      if (token != null &&
          authId.isNotEmpty &&
          !appContext.isCurrentUserGuest) {
        final everyoneDBManager = EveryoneDBManager();
        await everyoneDBManager.addTokenForAuthID(
          authID: authId,
          token: token,
          platform: Platform.operatingSystem,
        );
      }
    }

    if (token != null) {
      if (appContext.isCurrentUserGuest) {
        appContext.sharedPref.saveGuestFCMToken(token);
      } else {
        appContext.sharedPref.saveFCMToken(token);
      }

      appContext.sharedPref.setSubscribedToBelfast(true);
      for (final topic in NotificationTopics.serviceTopics) {
        appContext.sharedPref.setSubscribedToTopic(topic, true);
      }

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
    } else if (mounted) {
      final hint = kIsWeb && pwa.isIosBrowser && !pwa.isInstalled
          ? 'On iPhone/iPad, open CTRIM from the Home Screen app and try again.'
          : 'Could not enable notifications. Check permission and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hint), duration: const Duration(seconds: 4)),
      );
    }
  }
}


class _PersonalAction {
  const _PersonalAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Widget? trailing;
}
