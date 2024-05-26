import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import '../../utility/event_context.dart';

class EditHeadDetailsPage extends StatefulWidget {
  const EditHeadDetailsPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditHeadDetailsPage> createState() => _EditHeadDetailsPageState();
}

class _EditHeadDetailsPageState extends State<EditHeadDetailsPage> {
  late final TextEditingController _tecTitle, _tecSubtitle;
  late final String _originalTitle, _originalSubtitle;

  @override
  void initState() {
    _originalTitle = widget.eventContext.head.title;
    _originalSubtitle = widget.eventContext.head.subtitle;
    _tecSubtitle = TextEditingController(text: _originalSubtitle);
    _tecTitle = TextEditingController(text: _originalTitle);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvoked: (_) {
          if (_tecSubtitle.text.trim().isEmpty || _tecTitle.text.trim().isEmpty) {
            DialogManager.showAlertDialog(
                context: context,
                title: 'Empty Fields',
                content: 'Please make sure that the title or subtitle fields are not left empty before leaving');
          } else if (_originalSubtitle.compareTo(_tecSubtitle.text.trim()) != 0 ||
              _originalTitle.compareTo(_tecTitle.text.trim()) != 0) {
            widget.eventContext.head.setTitle(_tecTitle.text.trim());
            widget.eventContext.head.setSubtitle(_tecSubtitle.text.trim());
            widget.eventContext.allowSavingOfTheEdit();
          }
        },
        child: Scaffold(appBar: AppBar(title: const Text('Title and Subtitle')), body: _buildBody()));
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 8;
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
      ],
    );
  }
}
