import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/local_data_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_tag_picker.dart';
import '../../utility/responsive_layout.dart';

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
  late Set<String> _selectedTagIDs;
  bool _testing = false;
  bool _canSave = false;
  bool _hasChanges = false;
  bool _imageValidated = true;

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
    _selectedTagIDs = Set<String>.from(widget.user.tagIDs);

    _tecForename.addListener(_updateChangeState);
    _tecSurname.addListener(_updateChangeState);
    _tecLocation.addListener(_updateChangeState);
    _tecImgSrc.addListener(_updateChangeState);
  }

  @override
  void dispose() {
    _tecForename.dispose();
    _tecSurname.dispose();
    _tecLocation.dispose();
    _tecImgSrc.dispose();
    super.dispose();
  }

  void _updateChangeState() {
    final sanitizedImg = _sanitiseSrc();
    final hasTextChanges = _tecForename.text != widget.user.forname ||
        _tecSurname.text != widget.user.surname ||
        _tecLocation.text != widget.user.location;
    final hasImgFieldChange = sanitizedImg != widget.user.imgSrc;
    final hasFlagChanges = _isAreaAdmin != widget.user.isAreaAdmin || _isLeader != widget.user.isLeader;
    final hasTagChanges = !_setEquals(_selectedTagIDs, widget.user.tagIDs.toSet());
    final requiredFieldsFilled = _tecForename.text.trim().isNotEmpty &&
        _tecSurname.text.trim().isNotEmpty &&
        _tecLocation.text.trim().isNotEmpty;

    if (!hasImgFieldChange) {
      _imageValidated = true;
    } else if (_src != sanitizedImg) {
      _imageValidated = false;
    }

    setState(() {
      _hasChanges = hasTextChanges || hasFlagChanges || hasTagChanges || hasImgFieldChange;
      _canSave = _hasChanges && _imageValidated && requiredFieldsFilled;
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget? _buildSaveBar() {
    if (!_hasChanges) return null;

    final horizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
        child: FilledButton.icon(
          onPressed: _canSave ? _onSaveChangesClick : null,
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 16);

    return SingleChildScrollView(
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
                        ? FutureBuilder<Uint8List>(
                            future: _fetchFile(),
                            builder: (_, snap) {
                              if (snap.hasData) {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundImage: MemoryImage(snap.data!),
                                );
                              } else if (snap.hasError) {
                                return const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 40),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(fontSize: 12)),
                                  ],
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
                      });
                      _updateChangeState();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Leader'),
                    subtitle: const Text('Has leadership privileges in the app'),
                    value: _isLeader,
                    onChanged: (value) {
                      setState(() {
                        _isLeader = value;
                      });
                      _updateChangeState();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AppContext>(
            builder: (context, appContext, _) => UserTagPicker(
              allTags: appContext.allTags,
              selectedTagIDs: _selectedTagIDs,
              onChanged: (selected) {
                _selectedTagIDs = selected;
                _updateChangeState();
              },
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
    );
  }

  // * Logic

  Future<Uint8List> _fetchFile() async {
    final imageUrl = NetworkImageHelper.getImageUrl(_src);
    final response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  Future<void> _testImageClick() async {
    setState(() {
      _testing = true;
      _src = _sanitiseSrc();
      _imageValidated = false;
    });
    _updateChangeState();

    try {
      // Test if the image is accessible via HEAD request
      final imageUrl = NetworkImageHelper.getImageUrl(_src);
      final response = await http.head(
        Uri.parse(imageUrl),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; Image-Validator/1.0)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _imageValidated = true;
        });
        _updateChangeState();
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
        _imageValidated = false;
      });
      _updateChangeState();
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
      tagIDs: _selectedTagIDs.toList(),
    );

    try {
      // Update in database
      final appContext = Provider.of<AppContext>(context, listen: false);
      final preservedInactiveTags = widget.user.tagIDs.where((id) {
        final tag = appContext.tagById(id);
        return tag != null && !tag.isActive;
      });
      final tagIDsToSave = [...preservedInactiveTags, ..._selectedTagIDs];

      final userToSave = User(
        id: updatedUser.id,
        forname: updatedUser.forname,
        surname: updatedUser.surname,
        imgSrc: updatedUser.imgSrc,
        location: updatedUser.location,
        isAreaAdmin: updatedUser.isAreaAdmin,
        isLeader: updatedUser.isLeader,
        authID: updatedUser.authID,
        tagIDs: tagIDsToSave,
      );
      await _userDBManager.updateUser(userToSave);

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
          final existing = allUsers[index];
          final replacement = User(
            id: userToSave.id,
            forname: userToSave.forname,
            surname: userToSave.surname,
            imgSrc: userToSave.imgSrc,
            location: userToSave.location,
            isAreaAdmin: userToSave.isAreaAdmin,
            isLeader: userToSave.isLeader,
            authID: userToSave.authID,
            tagIDs: userToSave.tagIDs,
          );
          if (existing.roles != null) replacement.setRoles(existing.roles!.toList());
          if (existing.posts != null) replacement.setPosts(existing.posts!.toList());
          allUsers[index] = replacement;

          if (appContext.currentUser.id == widget.user.id) {
            appContext.setCurrentUser(replacement);
          }
        }

        setState(() {
          _canSave = false;
          _testing = false;
          _hasChanges = false;
          _imageValidated = true;
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
