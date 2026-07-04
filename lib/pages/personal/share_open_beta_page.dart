import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ShareOpenBetaPage extends StatelessWidget {
  const ShareOpenBetaPage({super.key});

  static const String _iosLink = 'https://testflight.apple.com/join/SxS0Mfjj';
  // ? Android removed for now
  // static const String _androidLink = 'https://play.google.com/apps/testing/com.ctrim.ctrim_app';
  static const String _webAppLink = 'https://ctrim.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Beta Testing')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(padding: const EdgeInsets.all(16.0), children: [
      // Header Section
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
              Icons.science_outlined,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Join Our Beta Testing',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve by testing new features before they\'re released!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // iOS Section
      _buildIosSection(context),

      const SizedBox(height: 24),

      const Divider(),

      const SizedBox(height: 24),

      // Web App Section
      _buildWebAppSection(context),

      const SizedBox(height: 32),
    ]);
  }

  Widget _buildIosSection(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Header
            Row(
              children: [
                Icon(Icons.apple, size: 32, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'iOS (iPhone & iPad)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            _buildInstructionStep(
              context,
              '1',
              'Download TestFlight',
              'Install the TestFlight app from the App Store if you don\'t have it already.',
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              context,
              '2',
              'Scan QR Code or Use Link',
              'Scan the QR code below or tap the link to open TestFlight.',
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              context,
              '3',
              'Install CTRIM Beta',
              'Tap "Accept" in TestFlight, then tap "Install" to get the beta version.',
            ),

            const SizedBox(height: 24),

            // QR Code
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
                  'assets/personal/ios_qr.png',
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

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onOpenLink(_iosLink),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open TestFlight'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _onLinkCopyClick(_iosLink, context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Link'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAppSection(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Header
            Row(
              children: [
                Icon(Icons.language, size: 32, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Web App',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            _buildInstructionStep(
              context,
              '1',
              'Open in Browser',
              'Access the web app directly from any modern browser on your computer or mobile device.',
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              context,
              '2',
              'Scan QR Code or Use Link',
              'Scan the QR code below or tap the link to open the web app.',
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              context,
              '3',
              'Install as PWA (Optional)',
              'Add to home screen for an app-like experience with offline support.',
            ),

            const SizedBox(height: 24),

            // QR Code
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

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onOpenLink(_webAppLink),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open Web App'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _onLinkCopyClick(_webAppLink, context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Link'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onOpenLink(final String link) async {
    if (await canLaunchUrlString(link)) {
      await launchUrlString(link, mode: LaunchMode.externalApplication);
    }
  }

  void _onLinkCopyClick(final String link, final BuildContext context) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Link copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
