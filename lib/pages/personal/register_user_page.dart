import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/id_tracker.dart';
import '../../firebase/db_managers/user_contact_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/user_contact.dart';
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
      _tecEmail = TextEditingController(),
      _tecPassword = TextEditingController(),
      _tecConfirmPassword = TextEditingController();
  final FocusNode _fnSurname = FocusNode(),
      _fnEmail = FocusNode(),
      _fnPassword = FocusNode(),
      _fnConfirmPassword = FocusNode();
  final AuthManager _authManager = AuthManager();

  bool _canSave = false;
  bool _isSaved = false;

  final List<String> _locations = <String>['Belfast', 'Portadown', 'North Coast'];

  String _currentLocation = 'Belfast'; // default for now

  @override
  void dispose() {
    _tecForename.dispose();
    _tecSurname.dispose();
    _tecEmail.dispose();
    _tecPassword.dispose();
    _tecConfirmPassword.dispose();

    _fnSurname.dispose();
    _fnPassword.dispose();
    _fnEmail.dispose();
    _fnConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Register User'),
        ),
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
          onSubmitted: (_) => _fnSurname.requestFocus(),
        ),
        TextField(
          decoration: const InputDecoration(label: Text('Surname'), hintText: 'Enter second name please'),
          controller: _tecSurname,
          onChanged: _areFieldsGood,
          focusNode: _fnSurname,
          onSubmitted: (_) => _fnEmail.requestFocus(),
        ),
        const SizedBox(
          height: 16,
        ),
        _buildLocationSelector(),
        const SizedBox(
          height: 16,
        ),
        TextField(
          decoration: const InputDecoration(label: Text('Email'), hintText: 'Enter email please'),
          controller: _tecEmail,
          onChanged: _areFieldsGood,
          focusNode: _fnEmail,
          onSubmitted: (_) => _fnPassword.requestFocus(),
        ),
        TextField(
          decoration: const InputDecoration(label: Text('Password'), hintText: 'Enter password'),
          controller: _tecPassword,
          onChanged: _areFieldsGood,
          focusNode: _fnPassword,
          onSubmitted: (_) => _fnConfirmPassword.requestFocus(),
          obscureText: true,
        ),
        TextField(
          decoration: const InputDecoration(label: Text('Confirm Password'), hintText: 'Confirm password'),
          controller: _tecConfirmPassword,
          onChanged: _areFieldsGood,
          focusNode: _fnConfirmPassword,
          onSubmitted: (_) => _fnConfirmPassword.unfocus(),
          obscureText: true,
        ),
        const SizedBox(
          height: 16,
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20)),
        onPressed: _canSave ? () => _saveUserClick() : null,
        child: const Text('Save'));
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
  void _saveUserClick() {
    if (_tecPassword.text.compareTo(_tecConfirmPassword.text) == 0) {
      showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Save User'),
              content: const Text('Are you sure all details are finished?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAttemptingToSaveDialog();

                      _attemptToRegisterUserAuth().then(
                        (authID) {
                          if (authID != null) {
                            _registerUser(
                              authID,
                            ).then((newUser) {
                              Provider.of<AppContext>(context, listen: false).addUser(newUser);
                              _isSaved = true;
                              Navigator.of(context).pop(); // pop the 'progress' indicator
                              Navigator.of(context).pop(); // pop the page
                            });
                          }
                        },
                      );
                    },
                    child: const Text('Save')),
              ],
            );
          });
    } else {
      _showErrorMessage('Passwords do not match!');
    }
  }

  Future<ctrim.User> _registerUser(String authID) async {
    final IDTrackerDBManager idTracker = IDTrackerDBManager();
    final UserDBManager userDBManager = UserDBManager();
    final UserContactDBManager contactDBManager = UserContactDBManager();

    final String newID = await idTracker.getAndIncrementUserID();
    final ctrim.User newUser =
        ctrim.User(id: newID, forname: _tecForename.text.trim(), surname: _tecSurname.text.trim());

    userDBManager.addUser(newUser);
    contactDBManager.addUserContact(newID, UserContact(authID: authID, id: newID, email: _tecEmail.text.trim()));

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

  Future<String?> _attemptToRegisterUserAuth() async {
    String? uid;
    try {
      // uid = await _authManager.registerUserAndSendVerification(_tecEmail.text, _tecPassword.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showErrorMessage('That email is already in use, please try another');
      } else if (e.code == 'invalid-email') {
        _showErrorMessage('Not a correct email');
      } else if (e.code == 'operation-not-allowed') {
        _showErrorMessage('Registration is not enabled, please check up with Admin(s)');
      } else if (e.code == 'weak-password') {
        _showErrorMessage('That password is too weak, please improve it 🤷');
      } else {
        _showErrorMessage('Something went wrong!');
      }
    }

    return uid;
  }

  void _showErrorMessage(String message) {
    Navigator.of(context).pop();
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Registration Error'),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
          );
        });
  }

  Future<bool> _onWillPop() async {
    if (_isSaved) return true;
    bool shouldPop = false;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Leave Page'),
          content: const Text('Do you want to discard all the changes made?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  shouldPop = true;
                  _authManager.signOut(); // sign out the "admin" account from registering a new user
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
        _tecPassword.text.isNotEmpty &&
        _tecConfirmPassword.text.isNotEmpty) {
      setState(() {
        _canSave = true;
      });
    } else if (_canSave &&
        (_tecForename.text.isEmpty ||
            _tecSurname.text.isEmpty ||
            _tecEmail.text.isEmpty ||
            _tecPassword.text.isEmpty ||
            _tecConfirmPassword.text.isEmpty)) {
      setState(() {
        _canSave = false;
      });
    }
  }
}
