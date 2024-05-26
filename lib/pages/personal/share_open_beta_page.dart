import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareOpenBetaPage extends StatelessWidget {
  const ShareOpenBetaPage({super.key});

  static const String _iosLink = 'https://testflight.apple.com/join/SxS0Mfjj';
  static const String _androidLink = 'https://play.google.com/apps/testing/com.ctrim.ctrim_app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Beta Testing')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(final BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16.0), children: [
      Image.asset('assets/personal/ios_qr.png'),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: () => _onLinkCopyClick(_iosLink, context),
          icon: const Icon(Icons.copy),
          label: const Text(_iosLink)),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 16),
      Image.asset('assets/personal/android_qr.png'),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: () => _onLinkCopyClick(_androidLink, context),
          icon: const Icon(Icons.copy),
          label: const Text(_androidLink)),
      const SizedBox(height: 32)
    ]);
  }

  void _onLinkCopyClick(final String link, final BuildContext context) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Link copied!'), behavior: SnackBarBehavior.floating));
  }
}
