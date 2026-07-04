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
import '../utility/dialog_manager.dart';
import '../widgets/user_avatar.dart';
import '../widgets/personal/personal_first_time_dialog.dart';
import 'events/post_templates/view_templates_page.dart';
import 'personal/guest_registration_page.dart';
import 'personal/current_user_page.dart';
import 'personal/login_page.dart';
import 'personal/notification_management_page.dart';
import 'personal/share_open_beta_page.dart';
import 'personal/view_all_users_page.dart';
import 'personal/view_my_posts_page.dart';
import 'personal/view_user_roles_page.dart';
import '../../utility/responsive_layout.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  static const String _powerpointGeneratorUrl = 'https://ctrim-powerpoint-generator.streamlit.app';
  // static const String _readmeUrl = 'https://www.craft.me/s/D1p8C4tzitcOwY';

  @override
  void initState() {
    super.initState();
    // Show first-time dialog if user hasn't seen it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.appContext.sharedPref.hasSeenPersonalDialog) {
        _showPersonalFirstTimeDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Responsive padding
    final double horizontalPadding = ResponsiveLayout.horizontalGutter(size.width, style: GutterStyle.medium, narrowPadding: 16.0);

    return Consumer<AppContext>(
      builder: (context, appContext, _) {
        return CustomScrollView(
          slivers: [
            // Modern App Bar
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

            // Content
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // User Profile Section (if not guest)
                  if (!appContext.isCurrentUserGuest) ...[
                    _buildUserProfileCard(appContext, theme, colorScheme),
                    const SizedBox(height: 24),
                  ],

                  // Main Actions Section
                  _buildMainActionsSection(appContext, theme, colorScheme),

                  const SizedBox(height: 24),

                  // Admin Section (if admin)
                  if (appContext.currentUser.isAreaAdmin) ...[
                    _buildAdminSection(appContext, theme, colorScheme),
                    const SizedBox(height: 24),
                  ],

                  // App & Legal Section
                  _buildAppLegalSection(theme, colorScheme),

                  const SizedBox(height: 24),

                  // Logout Section
                  _buildLogoutSection(theme, colorScheme),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // * UI Components

  Widget _buildUserProfileCard(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: kIsWeb ? null : _onUserProfileClick,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // User Avatar
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
                    radius: 28,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${appContext.currentUser.forname}! 👋',
                      style: theme.textTheme.titleLarge?.copyWith(
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

              if (!kIsWeb)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionsSection(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
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
        Card(
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
              // Register Account (guests only)
              if (appContext.isCurrentUserGuest) ...[
                _buildModernListTile(
                  icon: Icons.person_add_rounded,
                  title: 'Create Account',
                  subtitle: 'Sign up or sign in',
                  onTap: _onRegisterAccountClick,
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.primary,
                  isFirst: true,
                ),
                const Divider(height: 1, indent: 72),
              ],

              // Push Notifications (authenticated users; web uses Firestore topic fan-out)
              if (!appContext.isCurrentUserGuest) ...[
                if (appContext.isCurrentUserGuest) const Divider(height: 1, indent: 72),
                _buildModernListTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Manage notification settings',
                  onTap: _onNotificationManagerClick,
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.secondary,
                  isFirst: !appContext.isCurrentUserGuest,
                ),
                // Show enable notifications option if not yet enabled
                if (!appContext.sharedPref.isFirstOpen && appContext.sharedPref.fcmToken.isEmpty) ...[
                  const Divider(height: 1, indent: 72),
                  _buildModernListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Enable Notifications',
                    subtitle: 'Get updates from CTRIM',
                    onTap: () => _onEnableNotificationsClick(appContext),
                    theme: theme,
                    colorScheme: colorScheme,
                    iconColor: colorScheme.tertiary,
                  ),
                ],
              ],

              // User-specific actions
              if (!appContext.isCurrentUserGuest) ...[
                if (!kIsWeb) const Divider(height: 1, indent: 72),
                _buildModernListTile(
                  icon: Icons.checklist_rounded,
                  title: AppLocalizations.of(context)!.mySchedule,
                  subtitle: AppLocalizations.of(context)!.myScheduleSubtitle,
                  trailing: _buildScheduleBadge(appContext, theme, colorScheme),
                  onTap: _onViewTasksClick,
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.tertiary,
                  isFirst: kIsWeb,
                ),
                const Divider(height: 1, indent: 72),
                _buildModernListTile(
                  icon: Icons.article_rounded,
                  title: 'My Posts',
                  subtitle: 'View your created posts',
                  onTap: _onOpenPostsClick,
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.primary,
                ),
                const Divider(height: 1, indent: 72),
                _buildModernListTile(
                  icon: Icons.people_rounded,
                  title: AppLocalizations.of(context)!.volunteersMenuTitle,
                  subtitle: AppLocalizations.of(context)!.volunteersMenuSubtitle,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllUsersPage())),
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.secondary,
                  isLast: !kIsWeb,
                ),
              ],

              // Web-specific actions
              if (kIsWeb) ...[
                const Divider(height: 1, indent: 72),
                _buildModernListTile(
                  icon: Icons.no_accounts_rounded,
                  title: 'Account Deletion Request',
                  subtitle: 'Request account removal',
                  onTap: () => launchUrlString('https://ctrim-account-removal.web.app'),
                  theme: theme,
                  colorScheme: colorScheme,
                  iconColor: colorScheme.error,
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
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
                'Admin Tools',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: _buildModernListTile(
            icon: Icons.newspaper_rounded,
            title: 'Post Templates',
            subtitle: 'Manage post templates',
            onTap: _openViewTemplatesClick,
            theme: theme,
            colorScheme: colorScheme,
            iconColor: colorScheme.primary,
            isFirst: true,
            isLast: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAppLegalSection(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<AppContext>(
      builder: (context, appContext, _) {
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
            Card(
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
                  // Startup Tab Preference (authenticated users only)
                  if (!appContext.isCurrentUserGuest) ...[
                    _buildStartupTabPreference(appContext, theme, colorScheme),
                    const Divider(height: 1, indent: 72),
                  ],
                  _buildModernListTile(
                    icon: Icons.share_rounded,
                    title: 'Share CTRIM App',
                    subtitle: 'Invite others to join',
                    onTap: () => _openShareOpenBetaClick(),
                    theme: theme,
                    colorScheme: colorScheme,
                    iconColor: colorScheme.tertiary,
                    isFirst: appContext.isCurrentUserGuest,
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildModernListTile(
                    icon: Icons.build_rounded,
                    title: 'PowerPoint Generator',
                    subtitle: 'Create service slides easily',
                    onTap: () => launchUrlString(_powerpointGeneratorUrl),
                    theme: theme,
                    colorScheme: colorScheme,
                    iconColor: colorScheme.primary,
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildModernListTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    onTap: () =>
                        launchUrlString('https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b'),
                    theme: theme,
                    colorScheme: colorScheme,
                    iconColor: colorScheme.secondary,
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildModernListTile(
                    icon: Icons.contact_page_rounded,
                    title: 'Terms and Conditions',
                    subtitle: 'View terms and conditions',
                    onTap: () => launchUrlString('https://ctrim-terms-and-conditions.web.app'),
                    theme: theme,
                    colorScheme: colorScheme,
                    iconColor: colorScheme.primary,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartupTabPreference(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
    final currentTab = appContext.sharedPref.preferredStartupTab;
    final tabName = currentTab == 0 ? 'Events' : 'Information';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showStartupTabDialog(appContext, theme, colorScheme);
        },
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: colorScheme.tertiary,
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
                      'Startup Tab',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opens to: $tabName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStartupTabDialog(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
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

  Widget? _buildScheduleBadge(AppContext appContext, ThemeData theme, ColorScheme colorScheme) {
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
  void _showPersonalFirstTimeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PersonalFirstTimeDialog(),
    ).then((_) {
      widget.appContext.sharedPref.setHasSeenPersonalDialog();
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
      // Show loading while signing out
      DialogManager.showProgressDialog(
        context: context,
        title: 'Signing Out',
        subtitle: 'Please wait...',
      );

      try {
        widget.appContext.analytics.logEvent(name: 'logout');
        await _logout();

        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())).then((_) {
            setState(() {});
          });
        }
      } catch (e) {
        debugPrint('Error signing out: $e');
        if (mounted) {
          Navigator.of(context).pop(); // dismiss progress dialog
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to sign out: $e'), behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  Future<void> _logout() async {
    final AuthManager authManager = AuthManager();
    final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
    final token = widget.appContext.sharedPref.fcmToken;
    debugPrint('token to remove is $token');

    if (kIsWeb && token.isNotEmpty) {
      await WebNotificationLifecycle().unregister(authId: authManager.currentAuthUID, token: token);
    } else if (token.isNotEmpty) {
      await everyoneDBManager.removeTokenForAuthID(authManager.currentAuthUID, token);
    }

    widget.appContext.sharedPref.clearCreds();
    widget.appContext.setUserToGuest();
    widget.appContext.rebuildPlease();
    widget.appContext.sharedPref.setLoggedOut(true);
    await authManager.signOut();
  }

  void _onViewTasksClick() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewUserRolesPage(
                  selectedUser: widget.appContext.currentUser,
                  allowPostView: true,
                )));
  }

  void _onNotificationManagerClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationManagementPage()));
  }

  void _onUserProfileClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentUserPage())).then((_) {
      setState(() {
        // update incase user has changed their image
      });
    });
  }

  void _onOpenPostsClick() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewMyPostsPage()));
  }

  void _openShareOpenBetaClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareOpenBetaPage()));
  }

  void _openViewTemplatesClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewTemplatesPage()));
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

  void _onEnableNotificationsClick(AppContext appContext) async {
    final MessagingManager messagingManager = MessagingManager();
    final authId = AuthManager().currentAuthUID;

    // Show explanation dialog
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
      );
    } else {
      token = await messagingManager.requestPermissionAndToken();
    }

    if (token != null) {
      debugPrint('Token to save is $token');

      if (appContext.isCurrentUserGuest) {
        appContext.sharedPref.saveGuestFCMToken(token);
      } else {
        appContext.sharedPref.saveFCMToken(token);
      }

      appContext.sharedPref.setSubscribedToBelfast(true);
      appContext.sharedPref.setSubscribedToTopic('belfast-sunday-service', true);
      appContext.sharedPref.setSubscribedToTopic('belfast-midweek-service', true);
      appContext.sharedPref.setSubscribedToTopic('belfast-growth-mentoring', true);
      appContext.sharedPref.setSubscribedToTopic('belfast-dawn-watch', true);
      appContext.sharedPref.setSubscribedToTopic('belfast-overnight-prayer', true);
      appContext.sharedPref.setSubscribedToTopic('belfast-youth-cg', true);

      final webAuthId = kIsWeb && !appContext.isCurrentUserGuest ? authId : null;
      messagingManager.subscribeToTopic('belfast-sunday-service', authId: webAuthId);
      messagingManager.subscribeToTopic('belfast-midweek-service', authId: webAuthId);
      messagingManager.subscribeToTopic('belfast-growth-mentoring', authId: webAuthId);
      messagingManager.subscribeToTopic('belfast-dawn-watch', authId: webAuthId);
      messagingManager.subscribeToTopic('belfast-overnight-prayer', authId: webAuthId);
      messagingManager.subscribeToTopic('belfast-youth-cg', authId: webAuthId);
      messagingManager.subscribeToTopic('Belfast', authId: webAuthId);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Notifications enabled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh to hide the enable button
      }
    } else {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not enable notifications. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
