import 'package:flutter/material.dart';

import '../../utility/pwa_install_service.dart';

/// Soft prompt for web users to install / add CTRIM to the home screen.
class AddToHomeScreenDialog extends StatefulWidget {
  const AddToHomeScreenDialog({super.key});

  @override
  State<AddToHomeScreenDialog> createState() => _AddToHomeScreenDialogState();
}

class _AddToHomeScreenDialogState extends State<AddToHomeScreenDialog> {
  final PwaInstallService _pwaInstallService = PwaInstallService.instance;

  @override
  void initState() {
    super.initState();
    _pwaInstallService.listenForAvailability(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.install_mobile_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add CTRIM to your Home Screen',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Install CTRIM like an app for quicker access, a full-screen experience, and easier return visits.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_pwaInstallService.canPromptInstall) ...[
                FilledButton.icon(
                  onPressed: _onInstallClick,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Install App'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ] else if (_pwaInstallService.isIosBrowser) ...[
                _buildStep(context, '1', 'Open in Safari', 'Use Safari rather than an in-app browser.'),
                const SizedBox(height: 12),
                _buildStep(context, '2', 'Tap Share', 'Use the Share button at the bottom of Safari.'),
                const SizedBox(height: 12),
                _buildStep(
                  context,
                  '3',
                  'Add to Home Screen',
                  'Scroll down, tap Add to Home Screen, then tap Add.',
                ),
              ] else ...[
                Text(
                  _pwaInstallService.installSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Open your browser menu and look for Install app or Add to Home Screen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Not now'),
                  ),
                  if (!_pwaInstallService.canPromptInstall) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.labelLarge?.copyWith(
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
              const SizedBox(height: 2),
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

  Future<void> _onInstallClick() async {
    final result = await _pwaInstallService.promptInstall();
    if (!mounted) return;

    if (result == PwaInstallResult.accepted) {
      Navigator.of(context).pop();
      return;
    }

    final message = switch (result) {
      PwaInstallResult.dismissed => 'Install cancelled.',
      PwaInstallResult.unavailable =>
        'Install is not available right now. Try again from your browser menu.',
      PwaInstallResult.accepted => 'CTRIM App installed successfully.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    setState(() {});
  }
}
