import 'package:ctrim_app/firebase/db_managers/everyone_db_manager.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/id_tracker.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart' as ctrim;
import '../../utility/app_context.dart';
import '../../utility/volunteer_locations.dart';
import '../../widgets/user_tag_picker.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final TextEditingController _tecForename = TextEditingController(),
      _tecSurname = TextEditingController(),
      _tecEmail = TextEditingController();
  TextEditingController _tecAuthID = TextEditingController();
  final FocusNode _fnSurname = FocusNode(), _fnEmail = FocusNode();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();

  bool _canSave = false, _isSaved = false, _isLeader = false, _allowPop = false;
  Set<String> _selectedTagIDs = {};

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _currentLocation = VolunteerLocations.belfast;

  bool get _hasLinkedAuth => _tecAuthID.text.trim().isNotEmpty;

  @override
  void dispose() {
    _tecForename.dispose();
    _tecSurname.dispose();
    _tecEmail.dispose();

    _fnSurname.dispose();
    _fnEmail.dispose();
    _tecAuthID.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _isSaved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || _isSaved) return;
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Register User')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        TextField(
            decoration: const InputDecoration(label: Text('Forename'), hintText: 'Enter first name please'),
            controller: _tecForename,
            onChanged: _areFieldsGood,
            onSubmitted: (_) => _fnSurname.requestFocus()),
        TextField(
            decoration: const InputDecoration(label: Text('Surname'), hintText: 'Enter second name please'),
            controller: _tecSurname,
            onChanged: _areFieldsGood,
            focusNode: _fnSurname,
            onSubmitted: (_) => _fnEmail.requestFocus()),
        const SizedBox(height: 16),
        _buildLocationSelector(),
        const SizedBox(height: 16),
        const Divider(),
        Text('Account (optional)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Leave blank to create a placeholder profile (e.g. for schedules). '
          'Link their real account later from Edit User after they register.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
            decoration: const InputDecoration(
              label: Text('Email'),
              hintText: 'Their registered account email',
            ),
            controller: _tecEmail,
            onChanged: _areFieldsGood,
            focusNode: _fnEmail),
        TextField(
            decoration: const InputDecoration(
              label: Text('AuthID'),
              hintText: 'Found after searching email…',
            ),
            controller: _tecAuthID,
            readOnly: true),
        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: _tecAuthID.text.isEmpty ? _onSearchForAuthIDClick : null,
            child: const Text('Search for AuthID')),
        ElevatedButton(
            onPressed: _tecAuthID.text.isNotEmpty
                ? () {
                    setState(() {
                      _tecAuthID.clear();
                    });
                    _areFieldsGood('');
                  }
                : null,
            child: const Text('Clear AuthID')),
        const Divider(),
        SwitchListTile(
            title: const Text('Are they a leader?'),
            subtitle: const Text('Can create posts'),
            value: _isLeader,
            onChanged: (value) => setState(() {
                  _isLeader = value;
                })),
        const Divider(),
        const SizedBox(height: 16),
        Consumer<AppContext>(
          builder: (context, appContext, _) => UserTagPicker(
            allTags: appContext.allTags,
            selectedTagIDs: _selectedTagIDs,
            onChanged: (selected) => setState(() => _selectedTagIDs = selected),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _canSave ? () => _saveUserClick() : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text(_hasLinkedAuth ? 'Save' : 'Save placeholder'),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return DropdownButton<String>(
        icon: const Icon(Icons.map_sharp),
        hint: const Text('Location'),
        items: VolunteerLocations.assignable
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        value: _currentLocation,
        onChanged: (newLocation) {
          setState(() {
            _currentLocation = newLocation!;
            _areFieldsGood('');
          });
        });
  }

  // * Logic
  void _onSearchForAuthIDClick() {
    final email = _tecEmail.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter an email to search'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    _everyoneDBManager.fetchAuthIDFromEmail(email).then((auth) {
      debugPrint('auth is $auth');
      if (auth != null) {
        setState(() {
          _tecAuthID.text = auth;
        });
        _areFieldsGood('');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No auth found for this email!'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  void _saveUserClick() {
    final isPlaceholder = !_hasLinkedAuth;
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog.adaptive(
            title: Text(isPlaceholder ? 'Save placeholder' : 'Save User'),
            content: Text(isPlaceholder
                ? 'Create a profile with no login account? You can link their email later from Edit User.'
                : 'Are you sure all details are finished?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final saved = await DialogManager.runWithProgressDialog(
                      context: context,
                      title: isPlaceholder ? 'Creating placeholder' : 'Attempting to Register User',
                      subtitle: 'Please wait...',
                      errorTitle: 'Could not register user',
                      action: () async {
                        final newUser = await _registerUser();
                        if (!mounted) return;
                        Provider.of<AppContext>(context, listen: false).allUsers.add(newUser);
                      },
                    );
                    if (!mounted || !saved) return;
                    _isSaved = true;
                    _popRouteAfterAllowing();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  Future<ctrim.User> _registerUser() async {
    final IDTrackerDBManager idTracker = IDTrackerDBManager();
    final UserDBManager userDBManager = UserDBManager();
    final authID = _tecAuthID.text.trim();

    if (authID.isNotEmpty) {
      final existing = await userDBManager.fetchUserByAuthID(authID);
      if (existing != null) {
        throw StateError('That account is already linked to ${existing.fullname}.');
      }
    }

    final String newID = await idTracker.getAndIncrementUserID();
    final ctrim.User newUser = ctrim.User(
        id: newID,
        forname: _tecForename.text.trim(),
        surname: _tecSurname.text.trim(),
        authID: authID,
        location: _currentLocation,
        isLeader: _isLeader,
        tagIDs: _selectedTagIDs.toList());

    if (authID.isNotEmpty) {
      await _everyoneDBManager.setAsUser(authID, _isLeader);
    }
    await userDBManager.addUser(newUser);
    return newUser;
  }

  void _areFieldsGood(String _) {
    final namesOk = _tecForename.text.trim().isNotEmpty && _tecSurname.text.trim().isNotEmpty;
    if (_canSave != namesOk) {
      setState(() {
        _canSave = namesOk;
      });
    }
  }
}
