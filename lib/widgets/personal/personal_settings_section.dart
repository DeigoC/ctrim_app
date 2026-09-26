import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../src/localization/app_localizations.dart';
import '../../src/settings/settings_controller.dart';
import '../../utility/app_context.dart';
import '../../utility/cache/persist_users_local_cache.dart';
import '../common/app_dialog.dart';
import 'personal_action_section.dart';

class PersonalSettingsSection extends StatefulWidget {
  const PersonalSettingsSection({
    super.key,
    required this.appContext,
    required this.wide,
    this.gridColumns = 1,
    this.onPushNotifications,
    this.onEnableNotifications,
  });

  static const String productGuideUrl = 'https://deigoc.github.io/ctrim_app/';

  final AppContext appContext;
  final bool wide;
  final int gridColumns;
  final VoidCallback? onPushNotifications;
  final VoidCallback? onEnableNotifications;

  @override
  State<PersonalSettingsSection> createState() =>
      _PersonalSettingsSectionState();
}

class _PersonalSettingsSectionState extends State<PersonalSettingsSection> {
  static const String _slideDeckUtilsUrl =
      'https://church-slidedeck-utils.streamlit.app/';

  @override
  Widget build(BuildContext context) {
    return PersonalActionSection(
      title: 'Settings',
      titleIcon: Icons.settings_outlined,
      actions: _settingsActions(context),
      wide: widget.wide,
      gridColumns: widget.gridColumns,
    );
  }

  List<PersonalAction> _settingsActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <PersonalAction>[];
    final settingsController = Provider.of<SettingsController>(context);
    final themeLabel = _themeModeLabel(settingsController.themeMode);

    actions.add(
      PersonalAction(
        icon: Icons.brightness_6_rounded,
        title: 'Appearance',
        subtitle: themeLabel,
        onTap: () {
          HapticFeedback.lightImpact();
          _showThemeModeDialog(settingsController);
        },
        iconColor: colorScheme.tertiary,
      ),
    );

    if (!widget.appContext.isCurrentUserGuest) {
      final l10n = AppLocalizations.of(context)!;
      final showFullSurname =
          widget.appContext.currentUser.showFullSurnameToGuests;
      actions.add(
        PersonalAction(
          icon: Icons.badge_outlined,
          title: l10n.showFullSurnameToGuestsTitle,
          subtitle: showFullSurname
              ? l10n.showFullSurnameToGuestsOn
              : l10n.showFullSurnameToGuestsOff,
          onTap: () {
            HapticFeedback.lightImpact();
            _showFullSurnameDialog();
          },
          iconColor: colorScheme.tertiary,
        ),
      );

      final currentTab = widget.appContext.sharedPref.preferredStartupTab;
      final tabName = currentTab == 0
          ? 'Events'
          : currentTab == 2
              ? 'Cell Groups'
              : currentTab == 3
                  ? 'Personal'
                  : 'Information';
      actions.add(
        PersonalAction(
          icon: Icons.home_rounded,
          title: 'Startup Tab',
          subtitle: 'Opens to: $tabName',
          onTap: () {
            HapticFeedback.lightImpact();
            _showStartupTabDialog();
          },
          iconColor: colorScheme.tertiary,
        ),
      );
    }

    if (widget.onPushNotifications != null) {
      actions.add(
        PersonalAction(
          icon: Icons.notifications_active_rounded,
          title: 'Push Notifications',
          subtitle: 'Manage notification settings',
          onTap: widget.onPushNotifications!,
          iconColor: colorScheme.secondary,
        ),
      );
    }
    if (widget.onEnableNotifications != null) {
      actions.add(
        PersonalAction(
          icon: Icons.notifications_none_rounded,
          title: 'Enable Notifications',
          subtitle: 'Get updates from CTRIM',
          onTap: widget.onEnableNotifications!,
          iconColor: colorScheme.tertiary,
        ),
      );
    }

    actions.addAll([
      PersonalAction(
        icon: Icons.slideshow_rounded,
        title: 'Slide Deck Utils',
        subtitle: 'Create slides or extract text from PDF/PPTX',
        onTap: () => launchUrlString(_slideDeckUtilsUrl),
        iconColor: colorScheme.primary,
      ),
      PersonalAction(
        icon: Icons.privacy_tip_rounded,
        title: 'Privacy Policy',
        subtitle: 'View our privacy policy',
        onTap: () => launchUrlString(
            'https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b'),
        iconColor: colorScheme.secondary,
      ),
      PersonalAction(
        icon: Icons.contact_page_rounded,
        title: 'Terms and Conditions',
        subtitle: 'View terms and conditions',
        onTap: () =>
            launchUrlString('https://ctrim-terms-and-conditions.web.app'),
        iconColor: colorScheme.primary,
      ),
    ]);

    if (kIsWeb) {
      actions.add(
        PersonalAction(
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

  void _showStartupTabDialog() {
    final currentTab = widget.appContext.sharedPref.preferredStartupTab;

    showDialog(
      context: context,
      builder: (context) {
        return AppDialog(
          icon: Icons.tab_outlined,
          title: 'Choose Startup Tab',
          child: RadioGroup<int>(
            groupValue: currentTab,
            onChanged: (value) {
              if (value != null) {
                widget.appContext.sharedPref.setPreferredStartupTab(value);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: Text('Events'),
                  subtitle: Text('Open to the Posts/Bulletin tab'),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text('Information'),
                  subtitle: Text('Open to the CTRIM Information tab'),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text('Cell Groups'),
                  subtitle: Text('Open to the Cell Groups tab'),
                  value: 2,
                ),
                RadioListTile<int>(
                  title: Text('Personal'),
                  subtitle: Text('Open to the Personal tab'),
                  value: 3,
                ),
              ],
            ),
          ),
          actions: AppDialogActions(
            onCancel: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Match device';
    }
  }

  void _showFullSurnameDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enabled =
                widget.appContext.currentUser.showFullSurnameToGuests;
            return AppDialog(
              icon: Icons.badge_outlined,
              title: l10n.showFullSurnameToGuestsTitle,
              message: l10n.showFullSurnameToGuestsSubtitle,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  enabled
                      ? l10n.showFullSurnameToGuestsOn
                      : l10n.showFullSurnameToGuestsOff,
                ),
                value: enabled,
                onChanged: saving
                    ? null
                    : (value) async {
                        setDialogState(() => saving = true);
                        final ok = await _saveShowFullSurname(value);
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        if (mounted) setState(() {});
                        if (!ok && dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content:
                                  Text(l10n.showFullSurnameToGuestsSaveFailed),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              ),
              actions: AppDialogActions(
                onCancel: () => Navigator.pop(dialogContext),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _saveShowFullSurname(bool value) async {
    final user = widget.appContext.currentUser;
    try {
      await UserDBManager().updateShowFullSurnameToGuests(user.id, value);
      widget.appContext.setShowFullSurnameToGuests(value);
      await persistUsersLocalCache(widget.appContext.allUsers);
      return true;
    } catch (error) {
      debugPrint('Could not save guest surname setting: $error');
      return false;
    }
  }

  void _showThemeModeDialog(SettingsController settingsController) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: settingsController,
          builder: (context, _) {
            return AppDialog(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              child: RadioGroup<ThemeMode>(
                groupValue: settingsController.themeMode,
                onChanged: (value) async {
                  if (value == null) return;
                  await settingsController.updateThemeMode(value);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('Match device'),
                      subtitle: Text('Follow the system light or dark setting'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light'),
                      subtitle: Text('Always use light mode'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark'),
                      subtitle: Text('Always use dark mode'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
              actions: AppDialogActions(
                onCancel: () => Navigator.pop(dialogContext),
              ),
            );
          },
        );
      },
    );
  }
}
