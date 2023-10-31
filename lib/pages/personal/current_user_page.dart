import 'dart:io';

import 'package:ctrim_app/firebase/db_managers/user_db_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  String _src = '';
  bool _canSave = false, _testing = false;

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
            leading: MyUserAvatar(_appContext.currentUser, tmpImageSrc: _canSave ? _src : null)),
        const Divider(),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _testing ? _buildImageFB() : const Center(child: Text('...')),
        ),
        TextField(
          controller: _tecImgSrc,
          textInputAction: TextInputAction.done,
          maxLines: null,
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

  Widget _buildImageFB() {
    if (_canSave) {
      return Image.network(
        _src,
        fit: BoxFit.contain,
      );
    }
    return FutureBuilder(
        future: _fetchFile(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            final file = snap.data!;
            final double sizeInKb = file.lengthSync() / 1024;

            if (sizeInKb <= 512) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                setState(() {
                  _canSave = true;
                });
              });

              result = Image.file(file, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  setState(() {
                    _canSave = false;
                  });
                });
                return const Text('Could not load image!');
              });
            } else {
              result = Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'File size is too large at ${sizeInKb.toStringAsFixed(2)} KB (maximum of 512KB). Please compress image or use alternative!',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                      onPressed: () => launchUrlString('https://imagecompressor.com'),
                      child: const Text('Online Image Compressor'))
                ],
              ));
            }
          } else if (snap.hasError) {
            debugPrint('something with fetching image: ${snap.error}');
            result = const Center(
                child: Text(
              'Something went wrong, please check the image source again!',
              textAlign: TextAlign.center,
            ));
          }

          return result;
        });
  }

  // * Logic

  Future<void> _testImageClick() async {
    setState(() {
      _canSave = false;
      _testing = true;
      _src = _sanitiseSrc();
    });
  }

  void _onSaveChangesClick() async {
    UserDBManager userDBManager = UserDBManager();
    _appContext.currentUser.setImgSrc(_src);
    // we need to override the image?
    await _updateLocalImageData();
    userDBManager.updateUser(_appContext.currentUser).then((_) {
      setState(() {
        _canSave = false;
        _testing = false;
      });
      DialogManager.showAlertDialog(
          context: context,
          title: 'Profile Image Updated!',
          content: "Please bear in mind that this may require a restart of the app to see changes!");
    });
  }

  Future<void> _updateLocalImageData() async {
    final String userImgDir = '${_appContext.appDir}/user_imgs';
    final File imageFile = File('$userImgDir/${_appContext.currentUser.id}.png');
    final response = await http.get(Uri.parse(_src));
    await imageFile.writeAsBytes(response.bodyBytes);
  }

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
    final String tmpPath = '${dir.path}/tmp.png';
    final File tmp = File(tmpPath);
    final response = await http.get(Uri.parse(_src));
    return await tmp.writeAsBytes(response.bodyBytes);
  }

  void _onHelpClick() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Adding Media Files',
        content:
            'Please provide web links to the media file you want.\n\nWhen providing specific/personal media file please upload these to your Google Drive, change the access to public (anyone with the link), and paste that link here\n\nMax image size is 100 KB');
  }
}
