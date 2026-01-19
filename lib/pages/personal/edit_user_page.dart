import 'dart:typed_data';

import 'package:ctrim_app/firebase/db_managers/user_db_manager.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/local_data_manager.dart';
import 'package:ctrim_app/utility/network_image_helper.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key, required this.user});

  final User user;

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final UserDBManager _userDBManager = UserDBManager();
  final RegExp _driveRegExp = RegExp(r'https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');

  late final TextEditingController _tecForename;
  late final TextEditingController _tecSurname;
  late final TextEditingController _tecLocation;
  late final TextEditingController _tecImgSrc;

  late bool _isAreaAdmin;
  late bool _isLeader;
  late String _src;
  bool _testing = false;
  bool _canSave = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tecForename = TextEditingController(text: widget.user.forname);
    _tecSurname = TextEditingController(text: widget.user.surname);
    _tecLocation = TextEditingController(text: widget.user.location);
    _tecImgSrc = TextEditingController(text: widget.user.imgSrc);

    _isAreaAdmin = widget.user.isAreaAdmin;
    _isLeader = widget.user.isLeader;
    _src = widget.user.imgSrc;

    _tecForename.addListener(_onFieldChanged);
    _tecSurname.addListener(_onFieldChanged);
    _tecLocation.addListener(_onFieldChanged);
    _tecImgSrc.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _tecForename.dispose();
    _tecSurname.dispose();
    _tecLocation.dispose();
    _tecImgSrc.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final hasTextChanges = _tecForename.text != widget.user.forname ||
        _tecSurname.text != widget.user.surname ||
        _tecLocation.text != widget.user.location ||
        _tecImgSrc.text != widget.user.imgSrc;

    final hasFlagChanges = _isAreaAdmin != widget.user.isAreaAdmin || _isLeader != widget.user.isLeader;

    setState(() {
      _hasChanges = hasTextChanges || hasFlagChanges;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _canSave ? _onSaveChangesClick : null,
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Profile Picture',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _testing
                          ? FutureBuilder(
                              future: _fetchFile(),
                              builder: (_, snap) {
                                if (snap.hasData) {
                                  return CircleAvatar(
                                    radius: 60,
                                    backgroundImage: FileImage(snap.data!),
                                  );
                                }
                                return const CircularProgressIndicator();
                              })
                          : MyUserAvatar(
                              widget.user,
                              radius: 60,
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tecImgSrc,
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Enter image URL or Google Drive link',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _onHelpClick,
                          icon: const Icon(Icons.help_outline),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _testImageClick,
                          child: const Text('Test Image'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tecForename,
                      decoration: const InputDecoration(
                        labelText: 'Forename*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tecSurname,
                      decoration: const InputDecoration(
                        labelText: 'Surname*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tecLocation,
                      decoration: const InputDecoration(
                        labelText: 'Location*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Permissions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permissions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Area Admin'),
                      subtitle: const Text('Can manage users and access admin features'),
                      value: _isAreaAdmin,
                      onChanged: (value) {
                        setState(() {
                          _isAreaAdmin = value;
                          _onFieldChanged();
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Leader'),
                      subtitle: const Text('Has leadership privileges in the app'),
                      value: _isLeader,
                      onChanged: (value) {
                        setState(() {
                          _isLeader = value;
                          _onFieldChanged();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User ID Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('User ID'),
                      subtitle: Text(widget.user.id),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text('Auth ID'),
                      subtitle: Text(widget.user.authID),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // * Logic

  Future<void> _testImageClick() async {
    setState(() {
      _canSave = false;
      _testing = true;
      _src = _sanitiseSrc();
    });

    try {
      // Test if the image is accessible via HEAD request
      final imageUrl = NetworkImageHelper.getImageUrl(_src);
      final response = await http.head(
        Uri.parse(imageUrl),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; Image-Validator/1.0)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _canSave = true;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _testing = false;
        _canSave = false;
      });
    }
  }

  void _onSaveChangesClick() async {
    if (_tecForename.text.trim().isEmpty || _tecSurname.text.trim().isEmpty || _tecLocation.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create updated user object
    final updatedUser = User(
      id: widget.user.id,
      forname: _tecForename.text.trim(),
      surname: _tecSurname.text.trim(),
      imgSrc: _src,
      location: _tecLocation.text.trim(),
      isAreaAdmin: _isAreaAdmin,
      isLeader: _isLeader,
      authID: widget.user.authID,
    );

    try {
      // Update in database
      await _userDBManager.updateUser(updatedUser);

      // Update local image data if image changed
      if (_src != widget.user.imgSrc && _src.isNotEmpty) {
        await _updateLocalImageData();
      }

      // Update in app context if this is the current user or in all users list
      if (mounted) {
        final appContext = Provider.of<AppContext>(context, listen: false);

        // Update in all users list
        final allUsers = appContext.allUsers;
        final index = allUsers.indexWhere((u) => u.id == widget.user.id);
        if (index != -1) {
          allUsers[index].setImgSrc(updatedUser.imgSrc);
        }

        setState(() {
          _canSave = false;
          _testing = false;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateLocalImageData() async {
    final localDataManager = LocalDataManager();
    final imageUrl = NetworkImageHelper.getImageUrl(_src);
    final response = await http.get(Uri.parse(imageUrl));
    await localDataManager.writeUserImage(widget.user.id, response.bodyBytes);
    debugPrint('Cached updated user image for: ${widget.user.id}');
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

  void _onHelpClick() {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Adding Profile Picture',
      content: 'Please provide web links to the image file you want.\n\n'
          'When providing specific/personal media files, please upload these to your Google Drive, '
          'change the access to public (anyone with the link), and paste that link here.\n\n'
          'Supported formats:\n'
          '• Direct HTTPS URLs to images\n'
          '• Google Drive public links\n'
          '• Any publicly accessible image URL\n\n'
          'Recommended: Max image size is 512 KB',
    );
  }
}
