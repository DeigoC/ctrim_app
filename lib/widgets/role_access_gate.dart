import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../utility/app_context.dart';

/// In-page gate for admin/leader screens that rely on menu entry points.
///
/// Renders [child] when [allow] is true for the current user; otherwise shows
/// a denied message and a back action (no privileged UI is built).
class RoleAccessGate extends StatelessWidget {
  const RoleAccessGate({
    super.key,
    required this.allow,
    required this.deniedMessage,
    required this.child,
    this.title = 'Access denied',
  });

  final bool Function(User user) allow;
  final String deniedMessage;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.sessionEpoch);
    final user = Provider.of<AppContext>(context, listen: false).currentUser;
    if (allow(user)) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  deniedMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
