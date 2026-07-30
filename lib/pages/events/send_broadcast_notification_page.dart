import 'package:flutter/material.dart';

import '../../firebase/functions_manager.dart';
import '../../utility/broadcast_audience.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/event_notification_copy.dart';
import '../../utility/notification_send_result.dart';
import '../../utility/notification_topics.dart';
import '../../widgets/responsive_content.dart';

/// Compose and send a broadcast push for a post.
///
/// Body can be the post subtitle, a reminder preset, or free-form text.
/// Audience can optionally include the Belfast umbrella topic for this send.
class SendBroadcastNotificationPage extends StatefulWidget {
  const SendBroadcastNotificationPage({super.key, required this.eventContext});

  final EventContext eventContext;

  @override
  State<SendBroadcastNotificationPage> createState() =>
      _SendBroadcastNotificationPageState();
}

class _SendBroadcastNotificationPageState
    extends State<SendBroadcastNotificationPage> {
  late final TextEditingController _tecCustomBody;
  late final List<String> _presets;
  late BroadcastBodySource _source;
  late String _selectedPreset;
  late bool _includeBelfastUmbrella;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final head = widget.eventContext.head;
    _presets = EventNotificationCopy.presetBodies(
      title: head.title,
      eventDate: head.eventDate,
    );
    _source = EventNotificationCopy.defaultSource(
      subtitle: head.subtitle,
      eventDate: head.eventDate,
    );
    _selectedPreset = _presets.first;
    _tecCustomBody = TextEditingController(
      text: head.eventDate != null ? _presets.first : head.subtitle,
    );
    _includeBelfastUmbrella = BroadcastAudience.includesBelfastUmbrella(
      widget.eventContext.metadata.topics,
    );
  }

  @override
  void dispose() {
    _tecCustomBody.dispose();
    super.dispose();
  }

  String get _resolvedBody => EventNotificationCopy.resolveBody(
        source: _source,
        subtitle: widget.eventContext.head.subtitle,
        customBody: _tecCustomBody.text,
        selectedPreset: _selectedPreset,
      );

  List<String> get _resolvedTopics => BroadcastAudience.resolve(
        postTopics: widget.eventContext.metadata.topics,
        includeBelfastUmbrella: _includeBelfastUmbrella,
      );

  bool get _canSend =>
      _resolvedTopics.isNotEmpty && _resolvedBody.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Broadcast')),
      body: ResponsiveContent(
        narrowPadding: 16,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: [
            _buildPreviewCard(context),
            const SizedBox(height: 24),
            _buildAudienceSection(context),
            const SizedBox(height: 24),
            Text(
              'Notification body',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            _buildSourceOption(
              source: BroadcastBodySource.preset,
              title: 'Reminder preset',
              subtitle: widget.eventContext.head.hasEventDate
                  ? 'Upcoming-event wording with the date and time'
                  : 'Short generic update lines',
            ),
            if (_source == BroadcastBodySource.preset) _buildPresetPicker(context),
            _buildSourceOption(
              source: BroadcastBodySource.subtitle,
              title: 'Post subtitle',
              subtitle: widget.eventContext.head.subtitle.trim().isEmpty
                  ? 'No subtitle on this post'
                  : widget.eventContext.head.subtitle,
            ),
            _buildSourceOption(
              source: BroadcastBodySource.custom,
              title: 'Custom message',
              subtitle: 'Write your own notification body',
            ),
            if (_source == BroadcastBodySource.custom) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _tecCustomBody,
                maxLength: 180,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: 'What should the notification say?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_resolvedTopics.isEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'No broadcast audience selected. Enable All Belfast updates '
                'or add topics in post settings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: !_canSend || _sending ? null : _onSendPressed,
              icon: _sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending…' : 'Send notification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSection(BuildContext context) {
    final theme = Theme.of(context);
    final baseTopics = BroadcastAudience.resolve(
      postTopics: widget.eventContext.metadata.topics,
      includeBelfastUmbrella: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audience',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (baseTopics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Post topics: ${BroadcastAudience.describe(baseTopics)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'This post has no service topics — use All Belfast updates below, '
              'or add topics in post settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(NotificationTopics.belfastUmbrellaLabel),
          subtitle: const Text(
            'Also notify everyone opted into All Belfast updates',
          ),
          value: _includeBelfastUmbrella,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _includeBelfastUmbrella = value);
          },
        ),
        Text(
          'Will notify: ${BroadcastAudience.describe(_resolvedTopics)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = widget.eventContext.head.title;
    final body = _resolvedBody.isEmpty ? 'Enter a body to preview' : _resolvedBody;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BroadcastBodySource source,
    required String title,
    required String subtitle,
  }) {
    final disabled = source == BroadcastBodySource.subtitle &&
        widget.eventContext.head.subtitle.trim().isEmpty;

    return RadioListTile<BroadcastBodySource>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      value: source,
      groupValue: _source,
      onChanged: disabled
          ? null
          : (value) {
              if (value == null) return;
              setState(() => _source = value);
            },
    );
  }

  Widget _buildPresetPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Column(
        children: [
          for (final preset in _presets)
            RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(preset),
              value: preset,
              groupValue: _selectedPreset,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPreset = value);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _onSendPressed() async {
    final body = _resolvedBody;
    final topics = _resolvedTopics;
    if (body.isEmpty || topics.isEmpty) return;

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Send broadcast?',
      content:
          'This will notify people subscribed to:\n'
          '${BroadcastAudience.describe(topics)}\n\n'
          '${widget.eventContext.head.title}\n$body',
      confirmText: 'Send',
      icon: Icons.notifications_active,
    );
    if (!confirmed || !mounted) return;

    setState(() => _sending = true);

    final cloudFunctionManager = CloudFunctionManager();
    final title = widget.eventContext.head.title;
    final image = widget.eventContext.head.getKeyGraphic();
    var combined = const NotificationSendResult();

    try {
      for (final topic in topics) {
        final result = await cloudFunctionManager.sendToTopic(
          topic: topic,
          title: title,
          body: body,
          data: {'PostID': widget.eventContext.id},
          iOSImage: image,
          androidImage: image,
        );
        combined = combined.merge(result);
      }

      if (!mounted) return;
      DialogManager.showSnackBar(
        context: context,
        message: combined.feedbackMessage,
        isError: combined.hasFailures && !combined.hasSuccess,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      DialogManager.showSnackBar(
        context: context,
        message: 'Failed to send broadcast: $e',
        isError: true,
      );
    }
  }
}
