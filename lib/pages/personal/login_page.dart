import 'package:ctrim_app/firebase/db_managers/user_contact_db_manager.dart';
import 'package:ctrim_app/models/user_contact.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _tecEmail = TextEditingController(), _tecPassword = TextEditingController();
  final FocusNode _fnPassword = FocusNode();

  @override
  void dispose() {
    _tecEmail.dispose();
    _tecPassword.dispose();
    _fnPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          TextField(
            controller: _tecEmail,
            decoration: const InputDecoration(label: Text('Email'), hintText: "It's what you use for your app store"),
            onSubmitted: (_) => _fnPassword.requestFocus(),
          ),
          TextField(
            controller: _tecPassword,
            decoration: const InputDecoration(label: Text('Password'), hintText: 'Ask your admin if forgotten'),
            onSubmitted: (_) => _fnPassword.unfocus(),
            obscureText: true,
          ),
          ElevatedButton(onPressed: () => _onLoginClick(), child: const Text('Login'))
        ],
      ),
    );
  }

  void _onLoginClick() {
    _showLoadingDialog();
    _attemptToLogin().then((id) {
      if (id != null) {
        Provider.of<AppContext>(context, listen: false).setCurrentUser(id);
        _saveCredsAndToken();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  Future<String?> _attemptToLogin() async {
    try {
      final UserContactDBManager userContactDBManager = UserContactDBManager();
      final AuthManager authManager = AuthManager();
      final String authID = await authManager.loginAndReturnAuthID(_tecEmail.text.trim(), _tecPassword.text);
      final UserContact userContact = await userContactDBManager.fetchUserContactByAuthID(authID);
      return userContact.id;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        _showErrorMessage('That email is incorrect');
      } else if (e.code == 'user-disabled') {
        _showErrorMessage('This user has been disabled, please contact an admin');
      } else if (e.code == 'user-not-found') {
        _showErrorMessage('User with this email has not been found');
      } else if (e.code == 'wrong-password') {
        _showErrorMessage('Wrong password, please try again or reset the password if forgotten');
      } else {
        _showErrorMessage('Something went horribly wrong!');
      }
    }
    return null;
  }

  void _saveCredsAndToken() {
    Provider.of<AppContext>(context, listen: false).saveEmailPassword(_tecEmail.text.trim(), _tecPassword.text);
    // TODO the token should in theory already exist here, all we need to do is fetch it from storage and push it up
  }

  void _showErrorMessage(String message) {
    Navigator.of(context).pop(); // pop the loading dialog
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Login Error'),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
          );
        });
  }

  void _showLoadingDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return const Dialog(
            child: ListTile(
              title: Text('Attempting to Login'),
              subtitle: Text('Please wait...'),
              trailing: CircularProgressIndicator(),
            ),
          );
        });
  }
}
