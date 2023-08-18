import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../widgets/user_avatar.dart';

class CurrentUserPage extends StatefulWidget {
  const CurrentUserPage({super.key});

  @override
  State<CurrentUserPage> createState() => _CurrentUserPageState();
}

class _CurrentUserPageState extends State<CurrentUserPage> {
  late final TextEditingController _tecImgSrc;
  late final AppContext _appContext;
  final RegExp _driveRegExp = RegExp(r"drive.google.com/file/d/([a-zA-Z0-9_-]+)");
  File? _tmpFile;
  String _src = '';
  bool _canSave = false;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _src = _appContext.currentUser.imgSrc;
    _tecImgSrc = TextEditingController(text: _src);
    super.initState();
  }

  @override
  void dispose() {
    _tecImgSrc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(), appBar: AppBar(title: const Text('Current User')));
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ListTile(
          title: Text(_appContext.currentUser.fullname),
          subtitle: const Text('Tap to expand'),
          leading: MyUserAvatar(_appContext.currentUser),
          onTap: () => DialogManager.showUserProfile(
              selectedUser: _appContext.currentUser,
              context: context,
              currentUserAdmin: _appContext.currentUser.isAreaAdmin),
        ),
        TextField(
          controller: _tecImgSrc,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
              label: const Text('Image Source'),
              hintText: 'https://...',
              suffixIcon: IconButton(onPressed: _onHelpClick, icon: const Icon(Icons.help))),
        ),
        ElevatedButton(onPressed: _testImageClick, child: const Text('Test Image Link')),
        ElevatedButton(onPressed: _canSave ? _onSaveChangesClick : null, child: const Text('Save Changes')),
      ],
    );
  }

  // * Logic

  void _onHelpClick() {}

  Future<void> _testImageClick() async {
    _src = _sanitiseSrc();
    _tmpFile = await _fetchFile();

    if (_tmpFile != null) {
    } else {}
  }

  void _onSaveChangesClick() {}

  String _sanitiseSrc() {
    RegExpMatch? match = _driveRegExp.firstMatch(_tecImgSrc.text.trim());
    if (match != null) {
      String id = match.group(1)!;
      debugPrint('Link is a GoogleDrive Share link. Parsing now. ID is $id');
      return 'https://drive.google.com/uc?id=$id';
    }
    return _tecImgSrc.text.trim();
  }

  Future<File> _fetchFile() async {
    final dir = await getTemporaryDirectory();
    _src = _sanitiseSrc();
    final String tmpPath = '${dir.path}/tmp.png';
    final File tmp = File(tmpPath);
    final response = await http.get(Uri.parse(_src));
    return await tmp.writeAsBytes(response.bodyBytes);
  }
}
