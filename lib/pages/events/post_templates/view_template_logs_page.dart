import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/post_template.dart';
import '../../../models/user.dart';
import '../../../utility/app_context.dart';
import '../../../utility/responsive_layout.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/app_dialog.dart';

/// Read-only change history for a [PostTemplate] (embedded `Logs` entries).
class ViewTemplateLogsPage extends StatelessWidget {
  const ViewTemplateLogsPage({super.key, required this.template});

  final PostTemplate template;

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy. HH:mm');

  @override
  Widget build(BuildContext context) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 0);
    final logs = List<Map<String, dynamic>>.from(template.logs)
      ..sort((a, b) => (b['ts']! as DateTime).compareTo(a['ts']! as DateTime));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Change History'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                webHorizontalPadding + 16, 16, webHorizontalPadding + 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change History',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          template.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding:
                EdgeInsets.symmetric(horizontal: webHorizontalPadding + 16),
            sliver: logs.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState(context))
                : SliverList.builder(
                    itemCount: logs.length,
                    itemBuilder: (_, index) {
                      final entry = logs[index];
                      final user =
                          _userFor(appContext, entry['uid'] as String? ?? '');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: MyUserAvatar(user),
                          title: Text(
                            entry['log'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${user.fullname} · ${_dateFormat.format(entry['ts'] as DateTime)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          onTap: () => _showFullLog(
                              context, entry, user, webHorizontalPadding),
                        ),
                      );
                    },
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_edu,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No changes yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Template edits will appear here when you save with an update note.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  User _userFor(AppContext appContext, String uid) {
    return appContext.userById(uid) ??
        User(
          id: uid.isEmpty ? 'unknown' : uid,
          forname: 'Unknown',
          surname: 'User',
        );
  }

  void _showFullLog(
    BuildContext context,
    Map<String, dynamic> entry,
    User user,
    double horizontalPadding,
  ) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: user.fullname,
        message: _dateFormat.format(entry['ts'] as DateTime),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyUserAvatar(user),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry['log'] as String? ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
        actions: AppDialogActions(
          onConfirm: () => Navigator.of(context).pop(),
          confirmLabel: 'Close',
        ),
      ),
    );
  }
}
