import 'dart:math';
import 'package:ctrim_app/pages/personal/select_users_page.dart';
import 'package:ctrim_app/src/localization/app_localizations.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/my_avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEventHeadMeta extends StatefulWidget {
  const AddEventHeadMeta(
      {super.key,
      required this.tecTitle,
      required this.tecSubtitle,
      required this.onRequiredFieldChange,
      required this.eventContext});
  final TextEditingController tecTitle, tecSubtitle;
  final EventContext eventContext;
  final Function(String) onRequiredFieldChange;

  @override
  State<AddEventHeadMeta> createState() => _AddEventHeadMetaState();
}

class _AddEventHeadMetaState extends State<AddEventHeadMeta> {
  String? _selectedSubtitle;
  String? _selectedHeadMediaSrc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final availableSubtitles = widget.eventContext.templateSubtitles;
    final hasSubtitles = availableSubtitles != null && availableSubtitles.isNotEmpty;
    final headMediaPool = widget.eventContext.templateHeadMediaPool;
    final hasHeadMediaPool = headMediaPool != null && headMediaPool.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Section
          Card(
            elevation: 1,
            margin: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.title, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Post Title',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: widget.tecTitle,
                    decoration: const InputDecoration(
                      hintText: 'Make it snappy!',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onRequiredFieldChange,
                    maxLength: 64,
                  ),
                ),
              ],
            ),
          ),

          // Subtitle Selector Section (if available)
          if (hasSubtitles)
            Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, size: 18, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Template Subtitles',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSubtitleSelectorContent(availableSubtitles),
                  ),
                ],
              ),
            ),

          // Head Media Pool Section (if available)
          if (hasHeadMediaPool)
            Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Template Cover Image',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildHeadMediaPoolSelector(headMediaPool),
                  ),
                ],
              ),
            ),

          // Subtitle Section
          Card(
            elevation: 1,
            margin: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.subtitles, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'Post Subtitle',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: widget.tecSubtitle,
                    onChanged: widget.onRequiredFieldChange,
                    maxLength: 128,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'The synopsis of the post',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contributors Section
          _buildContributorSection(),
        ],
      ),
    );
  }

  Widget _buildHeadMediaPoolSelector(List<Map<String, dynamic>> pool) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pool.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = pool[index];
              final bool isSelected = _selectedHeadMediaSrc == item['src'];
              final bool isVideo = item['type'] == 'vid';
              final String? thumbnailSrc = item['thumbnailSrc'];
              final String src = item['src'] ?? '';
              final displaySrc = isVideo ? thumbnailSrc : src;

              return GestureDetector(
                onTap: () => _applyHeadMediaItem(item),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: displaySrc != null && displaySrc.isNotEmpty
                            ? Image.network(displaySrc,
                                fit: BoxFit.cover, errorBuilder: (_, __, ___) => _headMediaFallback(isVideo))
                            : _headMediaFallback(isVideo),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                            child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    if (isVideo)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(Icons.videocam, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final random = Random();
            _applyHeadMediaItem(pool[random.nextInt(pool.length)]);
          },
          icon: const Icon(Icons.shuffle, size: 18),
          label: const Text('Random'),
        ),
      ],
    );
  }

  Widget _headMediaFallback(bool isVideo) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _applyHeadMediaItem(Map<String, dynamic> item) {
    widget.eventContext.head.clearMedia();
    widget.eventContext.head.addMediaItem(
      type: item['type']!,
      src: item['src']!,
      title: item['title'] ?? '',
      thumbnail: item['thumbnailSrc'] ?? '',
    );
    setState(() => _selectedHeadMediaSrc = item['src']);
    widget.onRequiredFieldChange('');
  }

  Widget _buildSubtitleSelectorContent(List<String> availableSubtitles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a more flexible layout that adapts to screen size
        if (constraints.maxWidth < 400) {
          // Stack vertically on small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedSubtitle,
                decoration: const InputDecoration(
                  labelText: 'Select a subtitle',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                selectedItemBuilder: (BuildContext context) {
                  return availableSubtitles.map<Widget>((String subtitle) {
                    return Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    );
                  }).toList();
                },
                items: availableSubtitles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subtitle = entry.value;
                  final isLast = index == availableSubtitles.length - 1;
                  return DropdownMenuItem<String>(
                    value: subtitle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSubtitle = value;
                      widget.tecSubtitle.text = value;
                      widget.onRequiredFieldChange(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final random = Random();
                    final randomSubtitle = availableSubtitles[random.nextInt(availableSubtitles.length)];
                    setState(() {
                      _selectedSubtitle = randomSubtitle;
                      widget.tecSubtitle.text = randomSubtitle;
                      widget.onRequiredFieldChange(randomSubtitle);
                    });
                  },
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Random'),
                ),
              ),
            ],
          );
        } else {
          // Use horizontal layout on larger screens
          return Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSubtitle,
                  decoration: const InputDecoration(
                    labelText: 'Select a subtitle',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  selectedItemBuilder: (BuildContext context) {
                    return availableSubtitles.map<Widget>((String subtitle) {
                      return Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      );
                    }).toList();
                  },
                  items: availableSubtitles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final subtitle = entry.value;
                    final isLast = index == availableSubtitles.length - 1;
                    return DropdownMenuItem<String>(
                      value: subtitle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSubtitle = value;
                        widget.tecSubtitle.text = value;
                        widget.onRequiredFieldChange(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Random',
                onPressed: () {
                  final random = Random();
                  final randomSubtitle = availableSubtitles[random.nextInt(availableSubtitles.length)];
                  setState(() {
                    _selectedSubtitle = randomSubtitle;
                    widget.tecSubtitle.text = randomSubtitle;
                    widget.onRequiredFieldChange(randomSubtitle);
                  });
                },
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildContributorSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Contributors',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.eventContext.metadata.contributorUIDs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No contributors added yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  MyAvatarStack(
                    users: appContext.allUsers
                        .where((e) => widget.eventContext.metadata.contributorUIDs.contains(e.id))
                        .toList(),
                    appDir: appContext.appDir,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.eventContext.metadata.contributorUIDs.length} contributor${widget.eventContext.metadata.contributorUIDs.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _onManageContributorsTap,
                  icon: const Icon(Icons.group, size: 18),
                  label: Text(AppLocalizations.of(context)!.selectUsersManageContributors),
                ),
                const Divider(height: 32),
                ..._buildNotificationControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationControls() {
    return [
      CheckboxListTile(
          title: const Text('Notify Broadcast'),
          value: widget.eventContext.notifyBroadcast,
          onChanged: (newState) => _onNotifyBroadcastChange(newState!)),
      CheckboxListTile(
          title: const Text('Notify Scheduled Members'),
          value: widget.eventContext.notifyScheduledMembers,
          onChanged: (newState) => _onNotifyScheduledMembersChange(newState!)),
    ];
  }

  // ? Logic

  Future<void> _onManageContributorsTap() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: List<String>.from(widget.eventContext.metadata.contributorUIDs),
          excludedUIDs: [widget.eventContext.metadata.authorUID],
          title: AppLocalizations.of(context)!.selectUsersContributorsTitle,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      widget.eventContext.applyContributorUIDs(result);
    });
  }

  void _onNotifyBroadcastChange(final bool newState) {
    setState(() {
      final List<String> topics = widget.eventContext.metadata.topics;
      debugPrint('----- topics during adding are $topics');
      widget.eventContext.setNotifyBroadcast(newState);
    });
  }

  void _onNotifyScheduledMembersChange(final bool newState) {
    setState(() {
      widget.eventContext.setNotifyScheduledMembers(newState);
    });
  }
}
