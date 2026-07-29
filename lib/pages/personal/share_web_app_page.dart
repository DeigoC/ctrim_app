import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utility/dialog_manager.dart';
import '../../utility/pwa_install_service.dart';
import '../../widgets/responsive_content.dart';

class ShareWebAppPage extends StatefulWidget {
  const ShareWebAppPage({super.key});

  static const String webAppLink = 'https://ctrim.app';

  static const String shareMessage = 'Join CTRIM at https://ctrim.app — open in your browser. '
      'On mobile, you can add it to your home screen for an app-like experience.';

  @override
  State<ShareWebAppPage> createState() => _ShareWebAppPageState();
}

class _ShareWebAppPageState extends State<ShareWebAppPage> {
  final PwaInstallService _pwaInstallService = PwaInstallService.instance;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _pwaInstallService.listenForAvailability(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Web App')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ResponsiveContent(
      narrowPadding: 16,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Share the CTRIM Web App',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite others to open CTRIM in their browser and add it to their home screen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildShareActions(context),
          const SizedBox(height: 24),
          _buildQrSection(context),
          if (_shouldShowInstallSection) ...[
            const SizedBox(height: 24),
            _buildInstallSection(context),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  bool get _shouldShowInstallSection {
    if (kIsWeb) {
      return _pwaInstallService.shouldShowInstallOption;
    }
    return true;
  }

  Widget _buildShareActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share the link',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              ShareWebAppPage.webAppLink,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _onShareClick(context),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Link'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onOpenLink(ShareWebAppPage.webAppLink),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onLinkCopyClick(ShareWebAppPage.webAppLink, context),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan to open',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan this QR code on another device to open the web app.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/personal/webapp_qr.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.qr_code,
                        size: 100,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.install_mobile_rounded, size: 28, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add to Home Screen',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (kIsWeb && _pwaInstallService.canPromptInstall) ...[
              Text(
                'Install CTRIM as an app on this device for quick access and a full-screen experience.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _onInstallAppClick,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Install App'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ] else if (kIsWeb && _pwaInstallService.isIosBrowser) ...[
              _buildInstructionStep(
                context,
                '1',
                'Open in Safari',
                'Make sure you are using Safari, not an in-app browser.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                context,
                '2',
                'Tap Share',
                'Tap the Share button at the bottom of Safari.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                context,
                '3',
                'Add to Home Screen',
                'Scroll down, tap Add to Home Screen, then tap Add.',
              ),
            ] else ...[
              _buildInstructionStep(
                context,
                '1',
                'Open the link',
                'Visit https://ctrim.app in Chrome, Edge, or Safari.',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                context,
                '2',
                'Install or add to home screen',
                kIsWeb
                    ? 'Use your browser menu to install the app or add it to your home screen.'
                    : 'In Chrome or Edge, choose Install app from the menu. On iPhone or iPad, use Safari → Share → Add to Home Screen.',
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showBrowserInstallInstructions,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Show browser install steps'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onShareClick(BuildContext context) async {
    if (kIsWeb) {
      try {
        final result = await SharePlus.instance.share(
          ShareParams(text: ShareWebAppPage.shareMessage),
        );
        if (!context.mounted) return;
        if (result.status == ShareResultStatus.dismissed || result.status == ShareResultStatus.unavailable) {
          _onLinkCopyClick(ShareWebAppPage.shareMessage, context, successText: 'Message copied to clipboard!');
        }
        return;
      } catch (_) {
        if (!context.mounted) return;
        _onLinkCopyClick(ShareWebAppPage.shareMessage, context, successText: 'Message copied to clipboard!');
        return;
      }
    }

    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: ShareWebAppPage.shareMessage,
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  Future<void> _onInstallAppClick() async {
    if (_pwaInstallService.canPromptInstall) {
      final result = await _pwaInstallService.promptInstall();
      if (!mounted) return;

      final message = switch (result) {
        PwaInstallResult.accepted => 'CTRIM App installed successfully.',
        PwaInstallResult.dismissed => 'Install cancelled.',
        PwaInstallResult.unavailable => 'Install is not available right now. Try again from your browser menu.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      setState(() {});
      return;
    }

    if (_pwaInstallService.isIosBrowser) {
      _showIosInstallInstructions();
      return;
    }

    _showBrowserInstallInstructions();
  }

  void _showIosInstallInstructions() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Add to Home Screen',
      content: 'To install CTRIM on your iPhone or iPad:\n\n'
          '1. Tap the Share button at the bottom of Safari\n'
          '2. Scroll down and tap Add to Home Screen\n'
          '3. Tap Add in the top right corner',
      icon: Icons.ios_share_rounded,
    );
  }

  void _showBrowserInstallInstructions() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Install App',
      content: 'To install CTRIM as an app:\n\n'
          '• Chrome or Edge: open the browser menu and choose Install app, or use the install icon in the address bar\n'
          '• Other browsers: look for Add to Home Screen or Install in the browser menu',
      icon: Icons.install_desktop_rounded,
    );
  }

  Future<void> _onOpenLink(String link) async {
    if (await canLaunchUrlString(link)) {
      await launchUrlString(link, mode: LaunchMode.externalApplication);
    }
  }

  void _onLinkCopyClick(
    String link,
    BuildContext context, {
    String successText = 'Link copied to clipboard!',
  }) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(successText),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
