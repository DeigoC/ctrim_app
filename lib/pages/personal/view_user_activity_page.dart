import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart';
import '../../models/user_activity_log.dart';
import '../../models/user_activity_record.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/role_access_gate.dart';

class ViewUserActivityPage extends StatefulWidget {
  const ViewUserActivityPage({super.key, required this.selectedUser});

  final User selectedUser;

  @override
  State<ViewUserActivityPage> createState() => _ViewUserActivityPageState();
}

class _ViewUserActivityPageState extends State<ViewUserActivityPage> {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy. HH:mm');
  final UserDBManager _userDBManager = UserDBManager();

  bool _loading = true;
  Object? _loadError;
  UserActivityLog _log = UserActivityLog();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActivity());
  }

  Future<void> _loadActivity() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final log = await _userDBManager.fetchActivity(widget.selectedUser.id);
      if (!mounted) return;
      setState(() {
        _log = log;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading activity: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RoleAccessGate(
      allow: (user) => user.canManageVolunteers,
      deniedMessage: l10n.userActivityDenied,
      title: l10n.userActivityPageTitle,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.userActivityPageTitle),
        ),
        body: (_loading || _loadError != null)
            ? LoadProgressBody(
                message: 'Loading activity…',
                completedSteps: _loading ? 0 : 1,
                totalSteps: 1,
                error: _loadError,
                errorTitle: 'Could not load activity',
                onRetry: _loadActivity,
              )
            : _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gutter = ResponsiveLayout.horizontalGutter(
      MediaQuery.sizeOf(context).width,
      narrowPadding: 16,
    );
    final records = _log.records;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 24),
      children: [
        Text(
          widget.selectedUser.fullname,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (records.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.userProfileNoRecentActivity,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _ActivityTile(
                    record: records[i],
                    dateLabel: _dateFormat.format(records[i].ts),
                    documentLabel:
                        l10n.userActivityDocumentId(records[i].documentId),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.record,
    required this.dateLabel,
    required this.documentLabel,
  });

  final UserActivityRecord record;
  final String dateLabel;
  final String documentLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      leading: Icon(Icons.history, color: colorScheme.primary),
      title: Text(record.log),
      subtitle: Text('$dateLabel\n$documentLabel'),
      isThreeLine: true,
    );
  }
}
