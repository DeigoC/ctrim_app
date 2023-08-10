import 'dart:io';

import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';

import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../utility/app_context.dart';

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
        appBar: AppBar(title: const Text('Login')),
        body: ListView(padding: const EdgeInsets.all(8), children: [
          TextField(
              controller: _tecEmail,
              decoration: const InputDecoration(label: Text('Email'), hintText: "It's what you use for your app store"),
              onSubmitted: (_) => _fnPassword.requestFocus()),
          TextField(
              controller: _tecPassword,
              decoration: const InputDecoration(label: Text('Password'), hintText: 'Ask your admin if forgotten'),
              onSubmitted: (_) => _fnPassword.unfocus(),
              obscureText: true),
          ElevatedButton(onPressed: () => _onLoginClick(), child: const Text('Login'))
        ]));
  }

  void _onLoginClick() {
    DialogManager.showProgressDialog(context: context, title: 'Attempting To Login');
    _attemptToLogin().then((user) {
      if (user != null) {
        final appContext = Provider.of<AppContext>(context, listen: false);
        final String token = appContext.dataManager.fcmToken;

        if (!kDebugMode) {
          debugPrint('setting contact token as $token');
          final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
          everyoneDBManager.addToken(authID: user.authID, token: token, platform: Platform.operatingSystem);
        }
        appContext.dataManager.saveCreds(_tecEmail.text.trim(), _tecPassword.text);
        appContext.setCurrentUser(user);

        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  Future<User?> _attemptToLogin() async {
    try {
      final AuthManager authManager = AuthManager();
      final UserDBManager userDBManager = UserDBManager();
      final String authID = await authManager.loginAndReturnAuthID(_tecEmail.text.trim(), _tecPassword.text);
      final u = await userDBManager.fetchUserByAuthID(authID);
      return u;
    } on auth.FirebaseAuthException catch (e) {
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
}
