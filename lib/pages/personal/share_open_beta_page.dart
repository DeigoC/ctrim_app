import 'package:flutter/material.dart';

class ShareOpenBetaPage extends StatelessWidget {
  const ShareOpenBetaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Beta Testing')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(padding: const EdgeInsets.all(16.0), children: [
      Image.asset('assets/personal/ios_qr.png'),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: () => {},
          icon: const Icon(Icons.copy),
          label: const Text('https://testflight.apple.com/join/SxS0Mfjj')),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 16),
      Image.asset('assets/personal/android_qr.png'),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: () => {},
          icon: const Icon(Icons.copy),
          label: const Text('https://play.google.com/apps/testing/com.ctrim.ctrim_app')),
      const SizedBox(height: 32)
    ]);
  }
}
