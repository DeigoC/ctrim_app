import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/team_rota.dart';
import '../../widgets/personal/team_rota_schedule_view.dart';
import 'team_rota_role_actions.dart';

/// Every programme line for one Ministry Schedule event.
///
/// Staffing is add and remove people. Time, ministry, and order stay on the post.
class ViewTeamRotaSchedulePage extends StatefulWidget {
  const ViewTeamRotaSchedulePage({
    super.key,
    required this.head,
    required this.program,
    required this.selectedTagIDs,
    required this.onProgramUpdated,
  });

  final EventHead head;
  final EventProgram program;

  /// Ministries selected on the list. Empty means every tagged line.
  final Set<String> selectedTagIDs;

  final ValueChanged<EventProgram> onProgramUpdated;

  @override
  State<ViewTeamRotaSchedulePage> createState() =>
      _ViewTeamRotaSchedulePageState();
}

class _ViewTeamRotaSchedulePageState extends State<ViewTeamRotaSchedulePage> {
  late EventProgram _program;

  @override
  void initState() {
    super.initState();
    _program = widget.program;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.head.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            tooltip: l10n.teamRotaOpenPost,
            onPressed: () => AppLinks.openPost(
              context,
              id: widget.head.id,
              extra: widget.head,
            ),
            icon: const Icon(Icons.open_in_new),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TeamRotaScheduleView(
        head: widget.head,
        roles: TeamRotaQuery.rolesInStartOrder(_program),
        selectedTagIDs: widget.selectedTagIDs,
        onRoleTap: _openRole,
      ),
    );
  }

  Future<void> _openRole(Map<String, dynamic> role) {
    final appContext = context.read<AppContext>();
    return TeamRotaRoleActions(
      context: context,
      appContext: appContext,
      onProgramUpdated: (postId, program) {
        if (!mounted || postId != widget.head.id) return;
        setState(() => _program = program);
        widget.onProgramUpdated(program);
      },
    ).openRole(head: widget.head, role: role);
  }
}
