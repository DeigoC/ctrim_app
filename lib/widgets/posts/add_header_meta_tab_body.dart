import 'package:flutter/material.dart';

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
    return ListView(
      children: [
        TextField(
          controller: widget.tecTitle,
          decoration: const InputDecoration(label: Text('Title'), hintText: 'Make it snappy!'),
          onChanged: widget.onRequiredFieldChange,
          maxLength: 58,
        ),
        TextField(
          controller: widget.tecSubtitle,
          onChanged: widget.onRequiredFieldChange,
          maxLength: 128,
          maxLines: null,
          decoration: const InputDecoration(label: Text('Subtitle'), hintText: 'The synopsis of the post'),
        ),
        _buildContributorSection(),
      ],
    );
  }

  Widget _buildContributorSection() {
    final List<Widget> children = [
      const Text('Select Users who can edit certain details'),
      ElevatedButton.icon(
          onPressed: _onAddContributorClick, icon: const Icon(Icons.person_add), label: const Text('Add Contributor')),
      const Divider(),
    ];

    if (widget.contributorUIDs.isEmpty) {
      children.add(const Text('No one selected.'));
    } else {
      children.addAll(widget.contributorUIDs
          .map<Widget>((e) => ListTile(
                title: Text('UID is $e'),
              ))
          .toList());
    }

    return Column(children: children);
  }

  void _onAddContributorClick() {
    showDialog(
        context: context,
        builder: (_) {
          return const Dialog(
            child: Text('Complete this'),
          );
        });
  }
}
