import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:ctrim_app/widgets/user_selector_dialog.dart';
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
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
      TextField(
          controller: widget.tecTitle,
          decoration: const InputDecoration(label: Text('Title'), hintText: 'Make it snappy!'),
          onChanged: widget.onRequiredFieldChange,
          maxLength: 64),
      TextField(
          controller: widget.tecSubtitle,
          onChanged: widget.onRequiredFieldChange,
          maxLength: 128,
          maxLines: null,
          decoration: const InputDecoration(label: Text('Subtitle'), hintText: 'The synopsis of the post')),
      _buildContributorSection()
    ]);
  }

  Widget _buildContributorSection() {
    final List<Widget> children = [
      const Divider(),
      TextButton.icon(
          onPressed: _onAddContributorClick, icon: const Icon(Icons.person_add), label: const Text('Add Contributor')),
    ];

    if (widget.eventContext.metadata.contributorUIDs.isEmpty) {
      children.add(const Text('No one selected.'));
    } else {
      final appContext = Provider.of<AppContext>(context, listen: false);
      for (final uid in widget.eventContext.metadata.contributorUIDs) {
        final thisU = appContext.allUsers.firstWhere((e) => e.id.compareTo(uid) == 0);
        children.add(ListTile(
            title: Text(thisU.fullname),
            leading: MyUserAvatar(thisU),
            trailing: IconButton(
                onPressed: () => _onContributorRemoved(uid), icon: const Icon(Icons.delete, color: Colors.red))));
      }
    }

    children.add(const Divider());
    children.addAll(_buildNotificationControls());

    return Column(mainAxisSize: MainAxisSize.min, children: children);
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

  void _onAddContributorClick() {
    showDialog(
        context: context,
        builder: (_) => UserSelectorDialog(
            alreadySelectedUIDs: widget.eventContext.metadata.contributorUIDs, onSelected: _onContributorSelected));
  }

  void _onContributorSelected(final String id) {
    setState(() {
      widget.eventContext.metadata.contributorUIDs.add(id);
      widget.eventContext.contributorAdditionUIDs.add(id);
    });
  }

  void _onContributorRemoved(final String id) {
    setState(() {
      widget.eventContext.metadata.contributorUIDs.remove(id);
      widget.eventContext.contributorAdditionUIDs.remove(id);
    });
  }

  void _onNotifyBroadcastChange(final bool newState) {
    setState(() {
      widget.eventContext.setNotifyBroadcast(newState);
    });
  }

  void _onNotifyScheduledMembersChange(final bool newState) {
    setState(() {
      widget.eventContext.setNotifyScheduledMembers(newState);
    });
  }
}
