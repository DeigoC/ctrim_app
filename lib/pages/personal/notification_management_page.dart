import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
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
  final Set<String> _pendingTopics = {};

  @override
  void initState() {
    super.initState();
    _appContext = Provider.of<AppContext>(context, listen: false);
  }

  bool get _hasToken => _appContext.sharedPref.fcmToken.isNotEmpty;

  bool _isPending(String topic) => _pendingTopics.contains(topic);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        actions: [
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
                if (!_hasToken) ...[
                  const SizedBox(height: 12),
                  _buildTokenWarning(theme, colorScheme),
                ],
                const SizedBox(height: 20),
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
                'Push notifications are not enabled on this device yet. '
                'Enable them from Personal → Enable Notifications, then return here to choose topics.',
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
          'Please bear in mind that you can still receive push notifications on posts that you '
          'bookmarked, are tagged to, or assigned for a task.',
    );
  }
}
