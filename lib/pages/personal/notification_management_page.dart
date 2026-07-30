import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/notification_device_status.dart';
import '../../utility/notification_topics.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/responsive_content.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  late final AppContext _appContext;
  final MessagingManager _messagingManager = MessagingManager();
  final NotificationDeviceStatusService _statusService =
      NotificationDeviceStatusService();
  final Set<String> _pendingTopics = {};

  NotificationDeviceStatus? _status;
  bool _statusLoading = true;
  bool _repairing = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
    _refreshStatus();
  }

  bool get _hasToken =>
      _status?.hasLocalToken == true ||
      _appContext.sharedPref.fcmToken.isNotEmpty;

  bool _isPending(String topic) => _pendingTopics.contains(topic);

  String? get _webAuthId {
    if (!kIsWeb || _appContext.isCurrentUserGuest) return null;
    final id = AuthManager().currentAuthUID;
    return id.isEmpty ? null : id;
  }

  Future<void> _refreshStatus() async {
    setState(() => _statusLoading = true);
    final status = await _statusService.probe(
      prefs: _appContext.sharedPref,
      webAuthId: _webAuthId,
    );
    if (!mounted) return;
    setState(() {
      _status = status;
      _statusLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        actions: [
          IconButton(
            onPressed: _statusLoading ? null : _refreshStatus,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh device status',
          ),
          IconButton(
            onPressed: _helpClick,
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'About notifications',
          ),
        ],
      ),
      body: ResponsiveContent(
        narrowPadding: 16,
        maxContentWidthOverride: 1000,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = ResponsiveLayout.isWideScreen(constraints.maxWidth);

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                _buildInfoBanner(theme, colorScheme),
                const SizedBox(height: 20),
                _buildSectionHeader(theme, colorScheme, 'This device'),
                const SizedBox(height: 8),
                _buildDeviceStatusCard(theme, colorScheme),
                if (!_hasToken) ...[
                  const SizedBox(height: 12),
                  _buildTokenWarning(theme, colorScheme),
                ],
                const SizedBox(height: 24),
                _buildSectionHeader(theme, colorScheme, 'Belfast'),
                const SizedBox(height: 8),
                _buildTopicCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildTopicSwitch(
                      topic: NotificationTopics.belfastUmbrella,
                      title: NotificationTopics.belfastUmbrellaLabel,
                      subtitle: 'General Belfast church announcements',
                      value: _appContext.sharedPref.subscribedToBelfast,
                      updateBelfastPref: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, colorScheme, 'Services & Groups'),
                const SizedBox(height: 8),
                _buildServiceTopicsSection(
                  theme: theme,
                  colorScheme: colorScheme,
                  wide: isWide,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard(ThemeData theme, ColorScheme colorScheme) {
    final status = _status;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: _statusLoading || status == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusRow(
                    theme,
                    colorScheme,
                    label: 'Permission',
                    value: status.permissionLabel,
                    ok: status.permissionGranted,
                  ),
                  _statusRow(
                    theme,
                    colorScheme,
                    label: 'Push token',
                    value: status.hasLocalToken
                        ? (status.tokenPreview ?? 'Present')
                        : 'Missing',
                    ok: status.hasLocalToken,
                  ),
                  if (status.isWeb)
                    _statusRow(
                      theme,
                      colorScheme,
                      label: 'Home Screen app',
                      value: status.isPwaInstalled
                          ? 'Installed'
                          : (status.isIosBrowser
                              ? 'Required on iPhone/iPad'
                              : 'Optional'),
                      ok: !status.needsHomeScreenInstall,
                    ),
                  _statusRow(
                    theme,
                    colorScheme,
                    label: 'Topics enabled',
                    value: '${status.subscribedTopicCount}',
                    ok: status.subscribedTopicCount > 0,
                  ),
                  if (status.primaryIssue != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      status.primaryIssue!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _repairing ? null : _onRepairPressed,
                        icon: _repairing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(_repairing ? 'Repairing…' : 'Re-register'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: !_hasToken || _testing
                            ? null
                            : _onSendTestPressed,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.notification_important_outlined,
                                size: 18),
                        label: Text(_testing ? 'Sending…' : 'Send test to me'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String label,
    required String value,
    required bool ok,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: ok ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTopicsSection({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool wide,
  }) {
    final topics = NotificationTopics.serviceTopics;

    List<Widget> switchesFor(List<String> topicIds) {
      return [
        for (var i = 0; i < topicIds.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          _buildTopicSwitch(
            topic: topicIds[i],
            title: NotificationTopics.labelFor(topicIds[i]),
            value: _appContext.sharedPref.isSubscribedToTopic(topicIds[i]),
          ),
        ],
      ];
    }

    if (!wide) {
      return _buildTopicCard(
        theme: theme,
        colorScheme: colorScheme,
        children: switchesFor(topics),
      );
    }

    final midpoint = (topics.length / 2).ceil();
    final left = topics.sublist(0, midpoint);
    final right = topics.sublist(midpoint);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTopicCard(
            theme: theme,
            colorScheme: colorScheme,
            children: switchesFor(left),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopicCard(
            theme: theme,
            colorScheme: colorScheme,
            children: switchesFor(right),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You may still receive notifications for posts you bookmarked, '
                'are tagged on, or are assigned a task for.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenWarning(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_off_outlined,
                color: colorScheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Push notifications are not ready on this device yet. '
                'Use Re-register above, or Personal → Enable Notifications.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildTopicSwitch({
    required String topic,
    required String title,
    required bool value,
    String? subtitle,
    bool updateBelfastPref = false,
  }) {
    final pending = _isPending(topic);
    final enabled = _hasToken && !pending;

    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: enabled
          ? (newState) => _onTopicClick(topic, newState,
              updateBelfastPref: updateBelfastPref)
          : null,
      secondary: pending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
    );
  }

  Future<void> _onRepairPressed() async {
    final authId = AuthManager().currentAuthUID;
    if (authId.isEmpty) return;

    setState(() => _repairing = true);
    final message = await _statusService.repairRegistration(
      prefs: _appContext.sharedPref,
      authId: authId,
    );
    if (!mounted) return;
    setState(() => _repairing = false);
    await _refreshStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onSendTestPressed() async {
    setState(() => _testing = true);
    try {
      final token = await _statusService.currentDeviceToken(
        webAuthId: _webAuthId,
      );
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No push token on this device. Re-register first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await CloudFunctionManager().sendMessageToSelectedTokens(
        tokens: [token],
        title: 'CTRIM test notification',
        body: 'If you can read this, push is working on this device.',
        data: const {},
      );

      if (!mounted) return;
      final ok = result.hasSuccess || result.successCount > 0;
      DialogManager.showSnackBar(
        context: context,
        message: ok
            ? 'Test sent — check for a notification on this device.'
            : result.feedbackMessage,
        isError: !ok,
      );
    } catch (e) {
      if (!mounted) return;
      DialogManager.showSnackBar(
        context: context,
        message: 'Could not send test: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _onTopicClick(
    final String topic,
    final bool newState, {
    bool updateBelfastPref = false,
  }) async {
    if (_isPending(topic) || !_hasToken) return;

    setState(() => _pendingTopics.add(topic));

    final authId = kIsWeb ? AuthManager().currentAuthUID : null;
    final ok = newState
        ? await _messagingManager.subscribeToTopic(topic, authId: authId)
        : await _messagingManager.unsubscribeFromTopic(topic, authId: authId);

    if (!mounted) return;

    setState(() {
      _pendingTopics.remove(topic);
      if (ok) {
        if (updateBelfastPref) {
          _appContext.sharedPref.setSubscribedToBelfast(newState);
        } else {
          _appContext.sharedPref.setSubscribedToTopic(topic, newState);
        }
      }
    });

    if (ok) {
      _appContext.analytics.logEvent(
        name: newState ? 'notif_subscribe' : 'notif_unsubscribe',
        parameters: {'topic': topic},
      );
      await _refreshStatus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState
                ? 'Could not subscribe to ${NotificationTopics.labelFor(topic)}. Try again.'
                : 'Could not unsubscribe from ${NotificationTopics.labelFor(topic)}. Try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _helpClick() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Notifications',
      content:
          'Use This device to check permission and token registration. '
          'Send test to me only notifies this browser/app — not a broadcast.\n\n'
          'On iPhone/iPad web, open CTRIM from the Home Screen icon.\n\n'
          'You can still receive notifications for posts you bookmarked, '
          'are tagged on, or assigned a task for.',
    );
  }
}
