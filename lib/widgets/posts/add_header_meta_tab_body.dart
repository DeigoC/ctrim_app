import 'package:ctrim_app/utility/app_context.dart';
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
      required this.contributorUIDs});
  final TextEditingController tecTitle, tecSubtitle;
  final Function(String) onRequiredFieldChange;
  final List<String> contributorUIDs;

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
      const Text('Select Users who can edit certain details'),
      const SizedBox(height: 8),
      ElevatedButton.icon(
          onPressed: _onAddContributorClick, icon: const Icon(Icons.person_add), label: const Text('Add Contributor')),
      const Divider(),
    ];

    if (widget.contributorUIDs.isEmpty) {
      children.add(const Text('No one selected.'));
    } else {
      final appContext = Provider.of<AppContext>(context, listen: false);
      for (final uid in widget.contributorUIDs) {
        final thisU = appContext.allUsers.firstWhere((e) => e.id.compareTo(uid) == 0);
        children.add(ListTile(
          title: Text(thisU.fullname),
          leading: MyUserAvatar(thisU),
          trailing: IconButton(
              onPressed: () => _onContributorRemoved(uid), icon: const Icon(Icons.delete, color: Colors.red)),
        ));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  void _onAddContributorClick() {
    showDialog(
        context: context,
        builder: (_) =>
            UserSelectorDialog(alreadySelectedUIDs: widget.contributorUIDs, onSelected: _onContributorSelected));
  }

  void _onContributorSelected(String id) {
    setState(() {
      widget.contributorUIDs.add(id);
    });
  }

  void _onContributorRemoved(String id) {
    setState(() {
      widget.contributorUIDs.remove(id);
    });
  }
}
