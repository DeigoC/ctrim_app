import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/select_users_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/broadcast_audience.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
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

  @override
  void initState() {
    _originalTitle = widget.eventContext.head.title;
    _originalSubtitle = widget.eventContext.head.subtitle;
    _originalLeadSpeakerUID =
        widget.eventContext.metadata.leadSpeakerUID ?? widget.eventContext.head.leadSpeakerUID;
    _originalTagIDs = List<String>.from(widget.eventContext.head.tagIDs);
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
                content: 'Please make sure that the title or subtitle fields are not left empty before leaving');
            return;
          }

          final titleChanged = _originalTitle.compareTo(_tecTitle.text.trim()) != 0;
          final subtitleChanged = _originalSubtitle.compareTo(_tecSubtitle.text.trim()) != 0;
          final leadSpeakerChanged = _leadSpeakerUID != _originalLeadSpeakerUID;
          final tagsChanged = !_sameTagIDs(_originalTagIDs, widget.eventContext.head.tagIDs);

          if (titleChanged || subtitleChanged) {
            widget.eventContext.head.setTitle(_tecTitle.text.trim());
            widget.eventContext.head.setSubtitle(_tecSubtitle.text.trim());
          }
          if (titleChanged || subtitleChanged || leadSpeakerChanged || tagsChanged) {
            widget.eventContext.allowSavingOfTheEdit();
          }
        },
        child: Scaffold(appBar: AppBar(title: const Text('Title & details')), body: _buildBody()));
  }

  bool _sameTagIDs(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return b.every(setA.contains);
  }

  String? get _leadSpeakerUID =>
      widget.eventContext.metadata.leadSpeakerUID ?? widget.eventContext.head.leadSpeakerUID;

  Widget _buildBody() {
    final appContext = Provider.of<AppContext>(context);
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 8);
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: webHorizontalPadding),
      children: [
        TextField(
          controller: _tecTitle,
          maxLength: 64,
          decoration: const InputDecoration(hintText: 'Make it snappy!', label: Text('Title')),
        ),
        TextField(
          controller: _tecSubtitle,
          maxLength: 128,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'A short description of the post', label: Text('Subtitle')),
        ),
        const SizedBox(height: 16),
        PostTagPicker(
          allTags: appContext.allPostTags,
          selectedTagIDs: Set<String>.from(widget.eventContext.head.tagIDs),
          onChanged: (selected) => _onTagsChanged(appContext, selected),
        ),
        const SizedBox(height: 16),
        _buildLeadSpeakerSection(),
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

  Widget _buildLeadSpeakerSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final User? speaker = _resolveLeadSpeaker(appContext);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lead speaker',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Shown on the bulletin card when there is no cover media',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (speaker == null)
          Text(
            'No lead speaker selected',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: MyUserAvatar(speaker, radius: 24),
            title: Text(speaker.fullname),
            subtitle: speaker.imgSrc.isEmpty
                ? const Text('No profile picture — card will show initials only')
                : null,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _onManageLeadSpeakerTap,
          icon: const Icon(Icons.person_search, size: 18),
          label: Text(speaker == null ? 'Select lead speaker' : 'Change lead speaker'),
        ),
        if (speaker != null)
          TextButton(
            onPressed: () {
              setState(() {
                widget.eventContext.applyLeadSpeaker(uid: null);
              });
            },
            child: const Text('Clear'),
          ),
      ],
    );
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
