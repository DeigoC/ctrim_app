import 'package:ctrim_app/models/event/event_head.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/events/select_period_parent_page.dart';
import 'package:ctrim_app/pages/personal/select_users_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/broadcast_audience.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/parent_link.dart';
import 'package:ctrim_app/widgets/post_tag_picker.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utility/event_context.dart';
import '../../utility/responsive_layout.dart';

class EditHeadDetailsPage extends StatefulWidget {
  const EditHeadDetailsPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditHeadDetailsPage> createState() => _EditHeadDetailsPageState();
}

class _EditHeadDetailsPageState extends State<EditHeadDetailsPage> {
  late final TextEditingController _tecTitle, _tecSubtitle;
  late final String _originalTitle, _originalSubtitle;
  late final String? _originalLeadSpeakerUID;
  late final List<String> _originalTagIDs;
  late final bool _originalIsPeriodParent;
  late final String? _originalParentID;

  @override
  void initState() {
    _originalTitle = widget.eventContext.head.title;
    _originalSubtitle = widget.eventContext.head.subtitle;
    _originalLeadSpeakerUID =
        widget.eventContext.metadata.leadSpeakerUID ?? widget.eventContext.head.leadSpeakerUID;
    _originalTagIDs = List<String>.from(widget.eventContext.head.tagIDs);
    _originalIsPeriodParent = widget.eventContext.metadata.isPeriodParent;
    _originalParentID = widget.eventContext.metadata.parentID;
    _tecSubtitle = TextEditingController(text: _originalSubtitle);
    _tecTitle = TextEditingController(text: _originalTitle);
    super.initState();
  }

  @override
  void dispose() {
    _tecTitle.dispose();
    _tecSubtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_tecSubtitle.text.trim().isEmpty || _tecTitle.text.trim().isEmpty) {
          DialogManager.showAlertDialog(
            context: context,
            title: 'Empty Fields',
            content:
                'Please make sure that the title or subtitle fields are not left empty before leaving',
          );
          return;
        }

        final titleChanged = _originalTitle.compareTo(_tecTitle.text.trim()) != 0;
        final subtitleChanged = _originalSubtitle.compareTo(_tecSubtitle.text.trim()) != 0;
        final leadSpeakerChanged = _leadSpeakerUID != _originalLeadSpeakerUID;
        final tagsChanged = !_sameTagIDs(_originalTagIDs, widget.eventContext.head.tagIDs);
        final periodChanged = widget.eventContext.metadata.isPeriodParent != _originalIsPeriodParent;
        final parentChanged = widget.eventContext.metadata.parentID != _originalParentID;

        if (titleChanged || subtitleChanged) {
          widget.eventContext.head.setTitle(_tecTitle.text.trim());
          widget.eventContext.head.setSubtitle(_tecSubtitle.text.trim());
        }
        if (titleChanged ||
            subtitleChanged ||
            leadSpeakerChanged ||
            tagsChanged ||
            periodChanged ||
            parentChanged) {
          widget.eventContext.allowSavingOfTheEdit();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Title & details')),
        body: _buildBody(),
      ),
    );
  }

  bool _sameTagIDs(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return b.every(setA.contains);
  }

  String? get _leadSpeakerUID =>
      widget.eventContext.metadata.leadSpeakerUID ?? widget.eventContext.head.leadSpeakerUID;

  bool get _canEditParentStructure {
    final appContext = Provider.of<AppContext>(context, listen: false);
    return widget.eventContext.isUserAuthor(appContext.currentUser.id) ||
        appContext.currentUser.isAreaAdmin;
  }

  Widget _buildBody() {
    final appContext = Provider.of<AppContext>(context);
    final double gutter =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 12);

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 24),
      children: [
        _DetailsSectionCard(
          icon: Icons.title,
          title: 'Basics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _tecTitle,
                maxLength: 64,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Make it snappy!',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tecSubtitle,
                maxLength: 128,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  hintText: 'A short description of the post',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PostTagPicker(
          allTags: appContext.allPostTags,
          selectedTagIDs: Set<String>.from(widget.eventContext.head.tagIDs),
          onChanged: (selected) => _onTagsChanged(appContext, selected),
        ),
        const SizedBox(height: 12),
        _buildLeadSpeakerCard(appContext),
        if (_canEditParentStructure) ...[
          const SizedBox(height: 12),
          _buildRelatedPostsCard(appContext),
        ],
      ],
    );
  }

  void _onTagsChanged(AppContext appContext, Set<String> selected) {
    setState(() {
      final includeUmbrella = BroadcastAudience.includesLocationUmbrella(
        topics: widget.eventContext.metadata.topics,
        locationName: widget.eventContext.head.location,
      );
      widget.eventContext.applyTagIDs(selected.toList());
      widget.eventContext.syncNotificationTopics(
        allTags: appContext.allPostTags,
        includeLocationUmbrella: includeUmbrella,
      );
    });
  }

  Widget _buildLeadSpeakerCard(AppContext appContext) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final User? speaker = _resolveLeadSpeaker(appContext);

    return _DetailsSectionCard(
      icon: Icons.record_voice_over_outlined,
      title: 'Lead speaker',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Shown on the bulletin card when there is no cover media',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: speaker == null
                  ? CircleAvatar(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
                    )
                  : MyUserAvatar(speaker, radius: 20),
              title: Text(speaker?.fullname ?? 'No lead speaker'),
              subtitle: speaker == null
                  ? const Text('Tap to select')
                  : (speaker.imgSrc.isEmpty
                      ? const Text('No photo — card shows initials')
                      : null),
              trailing: speaker == null
                  ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        setState(() => widget.eventContext.applyLeadSpeaker(uid: null));
                      },
                      icon: const Icon(Icons.close),
                    ),
              onTap: _onManageLeadSpeakerTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedPostsCard(AppContext appContext) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parentID = widget.eventContext.metadata.parentID;
    final EventHead? parentHead = _resolveParentHead(appContext, parentID);
    final bool isPeriodParent = widget.eventContext.metadata.isPeriodParent;

    return _DetailsSectionCard(
      icon: Icons.account_tree_outlined,
      title: 'Related posts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Group meeting posts under a period parent for a term or season.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isPeriodParent ? Icons.flag : Icons.flag_outlined,
              color: isPeriodParent ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: const Text('Period parent'),
            subtitle: const Text('Allow other posts to attach under this one'),
            value: isPeriodParent,
            onChanged: (value) {
              setState(() => widget.eventContext.applyIsPeriodParent(value));
            },
          ),
          const Divider(height: 24),
          Text(
            'Parent post',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.account_tree,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                parentHead?.title ??
                    (parentID == null ? 'No parent' : 'Parent unavailable'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                parentHead?.subtitle.trim().isNotEmpty == true
                    ? parentHead!.subtitle
                    : (parentID == null ? 'Tap to attach under a period parent' : 'id: $parentID'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: parentID == null
                  ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
                  : IconButton(
                      tooltip: 'Clear parent',
                      onPressed: () {
                        setState(() => widget.eventContext.applyParentID(null));
                      },
                      icon: const Icon(Icons.close),
                    ),
              onTap: _onPickParentTap,
            ),
          ),
        ],
      ),
    );
  }

  EventHead? _resolveParentHead(AppContext appContext, String? parentID) {
    if (parentID == null || parentID.isEmpty) return null;
    try {
      return appContext.getPostHead(parentID);
    } catch (_) {
      for (final head in appContext.eventHeads) {
        if (head.id == parentID) return head;
      }
      return null;
    }
  }

  Future<void> _onPickParentTap() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectPeriodParentPage(
          currentParentID: widget.eventContext.metadata.parentID,
          excludePostID: widget.eventContext.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final String? newParentID = result.isEmpty ? null : result;
    if (newParentID == widget.eventContext.metadata.parentID) return;

    final appContext = Provider.of<AppContext>(context, listen: false);
    final createsCycle = ParentLink.wouldCreateCycle(
      postId: widget.eventContext.id,
      newParentId: newParentID,
      childrenOf: (id) {
        if (id == widget.eventContext.id) {
          return List<String>.from(widget.eventContext.metadata.childrenPostIDs);
        }
        final cached = appContext.getMetadata(id);
        return cached == null ? const <String>[] : List<String>.from(cached.childrenPostIDs);
      },
    );
    if (createsCycle) {
      if (!mounted) return;
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Invalid parent',
        content:
            'That post is this post or one of its related children. Choose a different period parent.',
      );
      return;
    }

    setState(() => widget.eventContext.applyParentID(newParentID));
  }

  User? _resolveLeadSpeaker(AppContext appContext) {
    final uid = _leadSpeakerUID;
    if (uid == null || uid.isEmpty) return null;
    try {
      return appContext.getUserFromID(uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onManageLeadSpeakerTap() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: _leadSpeakerUID == null ? <String>[] : [_leadSpeakerUID!],
          includeCurrentUser: true,
          maxSelection: 1,
          title: 'Select lead speaker',
        ),
      ),
    );
    if (result == null || !mounted) return;

    final appContext = Provider.of<AppContext>(context, listen: false);
    setState(() {
      if (result.isEmpty) {
        widget.eventContext.applyLeadSpeaker(uid: null);
      } else {
        final user = appContext.getUserFromID(result.first);
        widget.eventContext.applyLeadSpeaker(uid: user.id, imgSrc: user.imgSrc, name: user.fullname);
      }
    });
  }
}

/// Section card matching add-post / edit-schedule styling (header strip + body).
class _DetailsSectionCard extends StatelessWidget {
  const _DetailsSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
