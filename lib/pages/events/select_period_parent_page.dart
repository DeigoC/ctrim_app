import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/load_progress_body.dart';

/// Picks a period/season parent post (`IsPeriodParent == true`).
///
/// Returns the selected head id, or an empty string when the user clears the parent.
class SelectPeriodParentPage extends StatefulWidget {
  const SelectPeriodParentPage({
    super.key,
    this.currentParentID,
    this.excludePostID,
  });

  final String? currentParentID;

  /// The post being edited — cannot be selected as its own parent.
  final String? excludePostID;

  @override
  State<SelectPeriodParentPage> createState() => _SelectPeriodParentPageState();
}

class _SelectPeriodParentPageState extends State<SelectPeriodParentPage> {
  Future<List<EventHead>>? _loadFuture;
  String? _selectedID;

  @override
  void initState() {
    super.initState();
    _selectedID = widget.currentParentID;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _loadParents();
  }

  Future<List<EventHead>> _loadParents() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final fromCache =
        appContext.eventHeads.where((h) => h.isPeriodParent).toList();
    final fromQuery = await EventHeadDBManager().fetchPeriodParentHeads();

    final byId = <String, EventHead>{};
    for (final head in [...fromCache, ...fromQuery]) {
      if (widget.excludePostID != null && head.id == widget.excludePostID)
        continue;
      byId[head.id] = head;
    }
    final heads = byId.values.toList()
      ..sort((a, b) => b.recentDate.compareTo(a.recentDate));
    return heads;
  }

  @override
  Widget build(BuildContext context) {
    final double gutter = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Period parent'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedID ?? ''),
            child: const Text('Done'),
          ),
        ],
      ),
      body: FutureBuilder<List<EventHead>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (_loadFuture == null ||
              snapshot.connectionState != ConnectionState.done) {
            return const LoadProgressBody(
              message: 'Loading period parents…',
              completedSteps: 0,
              totalSteps: 1,
            );
          }
          if (snapshot.hasError) {
            return LoadProgressBody(
              message: 'Loading period parents…',
              completedSteps: 0,
              totalSteps: 1,
              error: snapshot.error,
              errorTitle: 'Could not load period parents',
              onRetry: () => setState(() {
                _loadFuture = _loadParents();
              }),
            );
          }

          final heads = snapshot.data ?? const <EventHead>[];
          if (heads.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(gutter + 8),
              child: Text(
                'No period parent posts yet. Mark a post as a period parent in Title & details, then pick it here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            );
          }

          final dateFormat = DateFormat('EEE, d MMM yyyy');
          return ListView(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: gutter),
            children: [
              ListTile(
                leading: Icon(
                  _selectedID == null || _selectedID!.isEmpty
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: const Text('No parent'),
                subtitle: const Text('Clear related-post parent'),
                onTap: () => setState(() => _selectedID = null),
              ),
              const Divider(),
              ...heads.map((head) {
                final selected = _selectedID == head.id;
                return ListTile(
                  leading: Icon(selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(head.title),
                  subtitle: Text(
                    [
                      if (head.subtitle.trim().isNotEmpty) head.subtitle.trim(),
                      dateFormat.format(head.recentDate),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() => _selectedID = head.id),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
