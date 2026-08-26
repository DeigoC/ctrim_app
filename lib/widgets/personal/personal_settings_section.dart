import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../src/settings/settings_controller.dart';
import '../../utility/app_context.dart';
import '../app_dialog.dart';
import 'personal_action_section.dart';

class PersonalSettingsSection extends StatefulWidget {
  const PersonalSettingsSection({
    super.key,
    required this.appContext,
    required this.wide,
    this.gridColumns = 1,
    required this.onShareWebApp,
  });

  final AppContext appContext;
  final bool wide;
  final int gridColumns;
  final VoidCallback onShareWebApp;

  @override
  State<PersonalSettingsSection> createState() =>
      _PersonalSettingsSectionState();
}

class _PersonalSettingsSectionState extends State<PersonalSettingsSection> {
  static const String _slideDeckUtilsUrl =
      'https://church-slidedeck-utils.streamlit.app/';
  static const String _stakeholderDocsUrl =
      'https://deigoc.github.io/ctrim_app/';

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

    actions.addAll([
      PersonalAction(
        icon: Icons.share_rounded,
        title: 'Share Web App',
        subtitle: 'Share link or add to home screen',
        onTap: widget.onShareWebApp,
        iconColor: colorScheme.tertiary,
      ),
      PersonalAction(
        icon: Icons.menu_book_rounded,
        title: 'Product guide',
        subtitle: 'How the app works — open to everyone',
        onTap: () => launchUrlString(_stakeholderDocsUrl),
        iconColor: colorScheme.primary,
      ),
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
