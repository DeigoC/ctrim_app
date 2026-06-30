import 'package:ctrim_app/firebase/db_managers/everyone_db_manager.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/id_tracker.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user.dart' as ctrim;
import '../../utility/app_context.dart';

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

  bool _canSave = false, _isSaved = false, _isLeader = false;

  final List<String> _locations = <String>['Belfast', 'Portadown', 'North Coast'];

  String _currentLocation = 'Belfast'; // default for now

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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onWillPop(),
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
        TextField(
            decoration: const InputDecoration(label: Text('Email'), hintText: 'Enter email please'),
            controller: _tecEmail,
            onChanged: _areFieldsGood,
            focusNode: _fnEmail),
        TextField(
            decoration:
                const InputDecoration(label: Text('AuthID'), hintText: '...search for existing authenticated user'),
            controller: _tecAuthID,
            readOnly: true),
        const SizedBox(height: 16),
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
        ElevatedButton(
            onPressed: _tecAuthID.text.isEmpty ? _onSearchForAuthIDClick : null,
            child: const Text('Search for AuthID')),
        ElevatedButton(
            onPressed: _tecAuthID.text.isNotEmpty
                ? () {
                    setState(() {
                      _tecAuthID.clear();
                    });
                  }
                : null,
            child: const Text('Clear AuthID')),
        ElevatedButton(
          onPressed: _canSave ? () => _saveUserClick() : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return DropdownButton<String>(
        icon: const Icon(Icons.map_sharp),
        hint: const Text('Location'),
        items: _locations
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
    // ? For improvements: make sure we're not looking for an already existing email in the users collection
    _everyoneDBManager.fetchAuthIDFromEmail(_tecEmail.text.trim()).then((auth) {
      debugPrint('auth is $auth');
      if (auth != null) {
        setState(() {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            _areFieldsGood('');
          });
          _tecAuthID = TextEditingController(text: auth);
        });
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
    if (_tecAuthID.text.isNotEmpty) {
      showDialog(
          context: context,
          builder: (_) {
            return AlertDialog.adaptive(
              title: const Text('Save User'),
              content: const Text('Are you sure all details are finished?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAttemptingToSaveDialog();
                      _registerUser().then((newUser) {
                        if (!context.mounted) return;
                        Provider.of<AppContext>(context, listen: false).allUsers.add(newUser);
                        _isSaved = true;
                        Navigator.of(context).pop(); // pop the 'progress' indicator
                        Navigator.of(context).pop(); // pop the page
                      });
                    },
                    child: const Text('Save')),
              ],
            );
          });
    } else {
      DialogManager.showAlertDialog(
          context: context, title: 'Registration error', content: 'Please look for email of user you want to register');
    }
  }

  Future<ctrim.User> _registerUser() async {
    final IDTrackerDBManager idTracker = IDTrackerDBManager();
    final UserDBManager userDBManager = UserDBManager();

    final String newID = await idTracker.getAndIncrementUserID();
    final ctrim.User newUser = ctrim.User(
        id: newID,
        forname: _tecForename.text.trim(),
        surname: _tecSurname.text.trim(),
        authID: _tecAuthID.text,
        isLeader: _isLeader);

    _everyoneDBManager.setAsUser(_tecAuthID.text, _isLeader);
    userDBManager.addUser(newUser);
    return newUser;
  }

  void _showAttemptingToSaveDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Dialog(
            child: ListTile(
              title: Text('Attempting to Register User'),
              subtitle: Text('Please wait...'),
              trailing: CircularProgressIndicator(),
            ),
          );
        });
  }

  Future<bool> _onWillPop() async {
    if (_isSaved) return true;
    bool shouldPop = false;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog.adaptive(
          title: const Text('Leave Page'),
          content: const Text('Do you want to discard all the changes made?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  shouldPop = true;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Discard')),
          ],
        );
      },
    );

    return shouldPop;
  }

  void _areFieldsGood(String _) {
    if (!_canSave &&
        _tecForename.text.isNotEmpty &&
        _tecSurname.text.isNotEmpty &&
        _tecEmail.text.isNotEmpty &&
        _tecAuthID.text.isNotEmpty) {
      setState(() {
        _canSave = true;
      });
    } else if (_canSave &&
        (_tecForename.text.isEmpty || _tecSurname.text.isEmpty || _tecEmail.text.isEmpty || _tecAuthID.text.isEmpty)) {
      setState(() {
        _canSave = false;
      });
    }
  }
}
