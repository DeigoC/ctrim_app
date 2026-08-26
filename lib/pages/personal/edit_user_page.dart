import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/cache/local_data_manager.dart';
import '../../utility/network_image_helper.dart';
import '../../utility/cache/persist_users_local_cache.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/user_auth_link.dart';
import '../../utility/user_activity_messages.dart';
import '../../utility/user_activity_recorder.dart';
import '../../utility/cache/users_local_cache.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/app_dialog.dart';
import '../../widgets/catalog/user_tag_picker.dart';
import '../../widgets/role_access_gate.dart';
import '../../utility/responsive_layout.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key, required this.user});

  final User user;

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final UserDBManager _userDBManager = UserDBManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final UserAuthLinkService _authLinkService = UserAuthLinkService();
  final RegExp _driveRegExp =
      RegExp(r'https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');

  late final TextEditingController _tecForename;
  late final TextEditingController _tecSurname;
  late final TextEditingController _tecImgSrc;

  late bool _isAreaAdmin;
  late bool _isLeader;
  late bool _isPlaceholder;
  late String _src;
  late String _authID;
  late String _currentLocation;
  late Set<String> _selectedTagIDs;
  bool _testing = false;
  bool _canSave = false;
  bool _hasChanges = false;
  bool _imageValidated = true;
  bool _authLinkChanged = false;
  bool _allowPop = false;

  Future<String?>? _emailFuture;

  @override
  void initState() {
    super.initState();
    _tecForename = TextEditingController(text: widget.user.forname);
    _tecSurname = TextEditingController(text: widget.user.surname);
    _tecImgSrc = TextEditingController(text: widget.user.imgSrc);

    _isAreaAdmin = widget.user.isAreaAdmin;
    _isLeader = widget.user.isLeader;
    _isPlaceholder = widget.user.isPlaceholder;
    _src = widget.user.imgSrc;
    _authID = widget.user.authID;
    _currentLocation = widget.user.location;
    _selectedTagIDs = Set<String>.from(widget.user.tagIDs);

    _tecForename.addListener(_updateChangeState);
    _tecSurname.addListener(_updateChangeState);
    _tecImgSrc.addListener(_updateChangeState);

    _emailFuture = _everyoneDBManager.fetchEmailFromAuthID(_authID);
  }

  @override
  void dispose() {
    _tecForename.dispose();
    _tecSurname.dispose();
    _tecImgSrc.dispose();
    super.dispose();
  }

  void _updateChangeState() {
    final sanitizedImg = _sanitiseSrc();
    final hasTextChanges = _tecForename.text != widget.user.forname ||
        _tecSurname.text != widget.user.surname ||
        _currentLocation != widget.user.location;
    final hasImgFieldChange = sanitizedImg != widget.user.imgSrc;
    final hasFlagChanges = _isAreaAdmin != widget.user.isAreaAdmin ||
        _isLeader != widget.user.isLeader;
    final hasTagChanges =
        !_setEquals(_selectedTagIDs, widget.user.tagIDs.toSet());
    final requiredFieldsFilled = _tecForename.text.trim().isNotEmpty &&
        _tecSurname.text.trim().isNotEmpty &&
        _currentLocation.trim().isNotEmpty;

    if (!hasImgFieldChange) {
      _imageValidated = true;
    } else if (_src != sanitizedImg) {
      _imageValidated = false;
    }

    setState(() {
      _hasChanges = hasTextChanges ||
          hasFlagChanges ||
          hasTagChanges ||
          hasImgFieldChange;
      _canSave = _hasChanges && _imageValidated && requiredFieldsFilled;
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _popRouteAfterAllowing({Object? result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleAccessGate(
      allow: (user) =>
          user.canManageVolunteers ||
          canEditPlaceholderProfile(actor: user, target: widget.user),
      deniedMessage: 'You cannot edit this user.',
      child: PopScope(
        canPop: _allowPop || !_hasChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || _allowPop) return;
          if (!_hasChanges) {
            _popRouteAfterAllowing(result: _authLinkChanged || result == true);
            return;
          }
          final shouldPop =
              await DialogManager.discardChanges(context: context);
          if (shouldPop && mounted) {
            _popRouteAfterAllowing(result: _authLinkChanged || result == true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isCreatorOnlyEdit ? 'Edit placeholder' : 'Edit User'),
          ),
          body: _buildBody(),
          bottomNavigationBar: _buildSaveBar(),
        ),
      ),
    );
  }

  bool get _isCreatorOnlyEdit {
    final current = Provider.of<AppContext>(context, listen: false).currentUser;
    if (current.canManageVolunteers) return false;
    // Use live Auth / placeholder state so a successful Link account leaves
    // the names-only creator path (permissions are area-admin only after link).
    final liveTarget = copyUser(
      widget.user,
      authID: _authID,
      isPlaceholder: _isPlaceholder,
    );
    return canEditPlaceholderProfile(actor: current, target: liveTarget);
  }

  bool get _canLinkAuth {
    final current = Provider.of<AppContext>(context, listen: false).currentUser;
    if (current.canManageVolunteers) return true;
    return _isPlaceholder &&
        _authID.isEmpty &&
        widget.user.createdByUserID == current.id;
  }

  bool get _canManagePermissions {
    final current = Provider.of<AppContext>(context, listen: false).currentUser;
    return current.canManageVolunteers;
  }

  bool get _canUnlinkAuth {
    final current = Provider.of<AppContext>(context, listen: false).currentUser;
    return canUnlinkUserAuth(actor: current);
  }

  Widget? _buildSaveBar() {
    if (!_hasChanges) return null;

    final horizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
        child: FilledButton.icon(
          onPressed: _canSave ? _onSaveChangesClick : null,
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return FutureBuilder<String?>(
      future: _emailFuture,
      builder: (context, snap) {
        final colorScheme = Theme.of(context).colorScheme;
        String display;
        if (snap.connectionState == ConnectionState.waiting) {
          display = 'Loading…';
        } else if (snap.hasError) {
          display = 'Unable to load email';
        } else if (snap.data == null || snap.data!.isEmpty) {
          display = _authID.isEmpty ? 'No account linked' : 'No email on file';
        } else {
          display = snap.data!;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
                helperText: _authID.isEmpty
                    ? 'No login linked — use Link account after they register'
                    : 'Linked account — reassign if they registered with a new email',
                helperMaxLines: 2,
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
              child: Text(
                display,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: snap.hasData &&
                              snap.data != null &&
                              snap.data!.isNotEmpty
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_canLinkAuth)
                  OutlinedButton.icon(
                    onPressed: _onLinkAccountClick,
                    icon: Icon(_authID.isEmpty ? Icons.link : Icons.swap_horiz),
                    label: Text(
                        _authID.isEmpty ? 'Link account' : 'Reassign account'),
                  ),
                if (_canUnlinkAuth && _authID.isNotEmpty)
                  TextButton.icon(
                    onPressed: _onUnlinkAccountClick,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Unlink'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 16);

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 16),
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
                                    Icon(Icons.error,
                                        color: Colors.red, size: 40),
                                    SizedBox(height: 8),
                                    Text('Failed to load image',
                                        style: TextStyle(fontSize: 12)),
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
                  _buildEmailField(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _locationDropdownValue(context),
                    decoration: const InputDecoration(
                      labelText: 'Location*',
                      border: OutlineInputBorder(),
                    ),
                    items: _locationOptions(context)
                        .map((location) => DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _currentLocation = value);
                      _updateChangeState();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Permissions Section (area admins only — creators cannot escalate roles)
          if (_canManagePermissions) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permissions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Leader'),
                      subtitle: const Text(
                          'Create posts, register people, and edit Information'),
                      value: _isLeader || _isAreaAdmin,
                      onChanged: (value) {
                        setState(() {
                          _isLeader = value;
                          if (!value) _isAreaAdmin = false;
                        });
                        _updateChangeState();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Area Admin'),
                      subtitle: const Text(
                          'Leader plus people, tags, locations, and cell groups'),
                      value: _isAreaAdmin,
                      onChanged: (value) {
                        setState(() {
                          _isAreaAdmin = value;
                          if (value) _isLeader = true;
                        });
                        _updateChangeState();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                    subtitle: Text(
                        _authID.isEmpty ? '(none — placeholder)' : _authID),
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

  User _userSnapshot({String? authID}) {
    final resolvedAuthID = authID ?? _authID;
    return User(
      id: widget.user.id,
      forname: _tecForename.text.trim().isEmpty
          ? widget.user.forname
          : _tecForename.text.trim(),
      surname: _tecSurname.text.trim().isEmpty
          ? widget.user.surname
          : _tecSurname.text.trim(),
      imgSrc: _src,
      location: _currentLocation.trim().isEmpty
          ? widget.user.location
          : _currentLocation.trim(),
      isAreaAdmin: _isAreaAdmin,
      isLeader: _isLeader,
      authID: resolvedAuthID,
      tagIDs: _selectedTagIDs.toList(),
      createdByUserID: widget.user.createdByUserID,
      isPlaceholder: effectiveIsPlaceholder(
        authID: resolvedAuthID,
        fallbackIsPlaceholder: _isPlaceholder,
      ),
    );
  }

  void _replaceUserInAppContext(User updated) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final existing = appContext.userById(updated.id);
    if (existing == null) return;

    if (existing.roles != null) updated.setRoles(existing.roles!.toList());
    if (existing.posts != null) updated.setPosts(existing.posts!.toList());
    appContext.addOrUpdateUser(updated);

    if (appContext.currentUser.id == updated.id) {
      appContext.setCurrentUser(updated);
    }
  }

  Future<void> _onLinkAccountClick() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AppDialog(
          icon: Icons.link,
          title: _authID.isEmpty ? 'Link account' : 'Reassign account',
          message: _authID.isEmpty
              ? 'Enter the email they used when registering in the app. '
                  'Their Auth ID will be linked to this volunteer profile.'
              : 'Enter the new account email. The previous Auth link will be cleared '
                  '(temp accounts are not deleted automatically).',
          child: TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: AppDialog.inputDecoration(label: 'Email'),
            onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
          ),
          actions: AppDialogActions(
            onCancel: () => Navigator.of(ctx).pop(),
            onConfirm: () => Navigator.of(ctx).pop(emailController.text.trim()),
            confirmLabel: 'Search',
          ),
        );
      },
    );

    if (!mounted || email == null || email.isEmpty) return;

    final linked = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Linking account',
      initialMessage: 'Looking up $email…',
      errorTitle: 'Could not link account',
      action: (onProgress) async {
        const total = 2;
        onProgress(completed: 0, total: total, message: 'Looking up $email…');
        final authID = await _everyoneDBManager.fetchAuthIDFromEmail(email);
        if (authID == null || authID.isEmpty) {
          throw StateError(
              'No account found for that email. Ask them to register first.');
        }
        onProgress(completed: 1, total: total, message: 'Linking account…');
        final actorUserId =
            Provider.of<AppContext>(context, listen: false).currentUser.id;
        final updated = await _authLinkService.linkAuth(
          user: _userSnapshot(),
          newAuthID: authID,
          isLeader: _isLeader,
          isAreaAdmin: _isAreaAdmin,
        );
        if (!mounted) return;
        _replaceUserInAppContext(updated);
        setState(() {
          _authID = updated.authID;
          _isPlaceholder = updated.isPlaceholder;
          _authLinkChanged = true;
          _emailFuture = _everyoneDBManager.fetchEmailFromAuthID(_authID);
        });
        await persistUsersLocalCache(
          Provider.of<AppContext>(context, listen: false).allUsers,
        );
        await UserActivityRecorder().record(
          actorUserId: actorUserId,
          log: UserActivityMessages.linkedVolunteerAccount,
          documentId: updated.id,
        );
      },
    );

    if (!mounted || !linked) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account linked successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onUnlinkAccountClick() async {
    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Unlink account',
      content:
          'Remove the login link from this profile? They will not be able to sign in as this '
          'volunteer until you link an account again. Schedule and profile data are kept.',
      confirmText: 'Unlink',
      icon: Icons.link_off,
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;

    final unlinked = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Unlinking account',
      subtitle: 'Removing login link…',
      errorTitle: 'Could not unlink account',
      action: () async {
        final actorUserId =
            Provider.of<AppContext>(context, listen: false).currentUser.id;
        final updated =
            await _authLinkService.unlinkAuth(user: _userSnapshot());
        if (!mounted) return;
        _replaceUserInAppContext(updated);
        setState(() {
          _authID = '';
          _isPlaceholder = true;
          _authLinkChanged = true;
          _emailFuture = Future.value(null);
        });
        await persistUsersLocalCache(
          Provider.of<AppContext>(context, listen: false).allUsers,
        );
        await UserActivityRecorder().record(
          actorUserId: actorUserId,
          log: UserActivityMessages.unlinkedVolunteerAccount,
          documentId: updated.id,
        );
      },
    );

    if (!mounted || !unlinked) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account unlinked'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
      // GET without custom headers — Flutter web CORS fails on User-Agent / HEAD preflight.
      final imageUrl = NetworkImageHelper.getImageUrl(_src);
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));

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
    if (_tecForename.text.trim().isEmpty ||
        _tecSurname.text.trim().isEmpty ||
        _currentLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create updated user object — never reuse stale widget.user.isPlaceholder
    // after Link account (that would write IsPlaceholder:true back to Firestore).
    final placeholder = effectiveIsPlaceholder(
      authID: _authID,
      fallbackIsPlaceholder: _isPlaceholder,
    );
    final updatedUser = User(
      id: widget.user.id,
      forname: _tecForename.text.trim(),
      surname: _tecSurname.text.trim(),
      imgSrc: _src,
      location: _currentLocation.trim(),
      isAreaAdmin: _isAreaAdmin,
      isLeader: _isLeader,
      authID: _authID,
      tagIDs: _selectedTagIDs.toList(),
      createdByUserID: widget.user.createdByUserID,
      isPlaceholder: placeholder,
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
        createdByUserID: updatedUser.createdByUserID,
        isPlaceholder: updatedUser.isPlaceholder,
      );

      if (_isCreatorOnlyEdit) {
        await _userDBManager.updateUserNames(
          uid: userToSave.id,
          forename: userToSave.forname,
          surname: userToSave.surname,
        );
      } else {
        await _userDBManager.updateUser(userToSave);
        if (userToSave.authID.isNotEmpty) {
          await _everyoneDBManager.setAsUser(
            userToSave.authID,
            isLeader: userToSave.isLeader,
            isAreaAdmin: userToSave.isAreaAdmin,
          );
        }
      }

      // Update local image data if image changed
      if (_src != widget.user.imgSrc && _src.isNotEmpty) {
        await _updateLocalImageData();
      }

      // Update in app context if this is the current user or in all users list
      if (mounted) {
        _replaceUserInAppContext(userToSave);
        await persistUsersLocalCache(appContext.allUsers);
        await UserActivityRecorder().record(
          actorUserId: appContext.currentUser.id,
          log: UserActivityMessages.editedVolunteerProfile,
          documentId: userToSave.id,
        );

        setState(() {
          _isPlaceholder = userToSave.isPlaceholder;
          _canSave = false;
          _testing = false;
          _hasChanges = false;
          _imageValidated = true;
          _authLinkChanged = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        _popRouteAfterAllowing(result: true); // Return true to indicate success
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

  List<String> _locationOptions(BuildContext context) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final options = List<String>.from(
      VolunteerLocations.assignableFrom(appContext.allLocations),
    );
    if (_currentLocation.isNotEmpty && !options.contains(_currentLocation)) {
      options.insert(0, _currentLocation);
    }
    return options;
  }

  String _locationDropdownValue(BuildContext context) {
    final options = _locationOptions(context);
    if (options.contains(_currentLocation)) return _currentLocation;
    return options.isNotEmpty ? options.first : _currentLocation;
  }
}
