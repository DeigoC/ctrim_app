import 'dart:io';

import 'package:ctrim_app/firebase/messaging_manager.dart';
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
  final AuthManager _authManager = AuthManager();
  bool _loggedIn = false;

  @override
  void dispose() {
    _tecEmail.dispose();
    _tecPassword.dispose();
    _fnPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 8;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          appBar: AppBar(title: const Text('Login'), leading: Container()),
          body: ListView(padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding, vertical: 8), children: [
            TextField(
                controller: _tecEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(label: Text('Email')),
                onSubmitted: (_) => _fnPassword.requestFocus()),
            TextField(
                controller: _tecPassword,
                decoration: const InputDecoration(label: Text('Password')),
                onSubmitted: (_) => _fnPassword.unfocus(),
                focusNode: _fnPassword,
                obscureText: true),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _onForgotEmailClick, child: const Text('Forgot Password'))),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _onLoginClick(), child: const Text('Login'))
          ])),
    );
  }

  // * Logic

  void _onLoginClick() async {
    DialogManager.showProgressDialog(context: context, title: 'Attempting To Login');
    final authID = await _attemptToLogin();

    if (authID != null) {
      _logUserToApp(authID).then((_) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _logUserToApp(final String authID) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final MessagingManager messagingManager = MessagingManager();

    final String? token = await messagingManager.getToken();
    final UserDBManager userDBManager = UserDBManager();
    final user = await userDBManager.fetchUserByAuthID(authID);

    debugPrint('setting device token as $token');
    final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
    final String platform = kIsWeb ? 'Web' : Platform.operatingSystem;

    if (token != null) {
      everyoneDBManager.addTokenForAuthID(authID: authID, token: token, platform: platform);
      appContext.sharedPref.saveFCMToken(token);
    }

    appContext.sharedPref.saveCreds(_tecEmail.text.trim(), _tecPassword.text);
    appContext.setCurrentUser(user);
    appContext.sharedPref.setLoggedOut(false);
    appContext.analytics.logLogin(loginMethod: 'in-app login page');
    _loggedIn = true;
  }

  Future<String?> _attemptToLogin() async {
    try {
      final String authID = await _authManager.loginAndReturnAuthID(_tecEmail.text.trim(), _tecPassword.text);
      if (!await _authManager.hasUserVerifiedEmail()) {
        _authManager.signOut().then((_) => DialogManager.showAlertDialog(
                context: context,
                title: 'Login Error',
                content: 'This user has not been verified, please look for your verify email link!')
            .then((_) => Navigator.of(context).pop()));
      } else {
        return authID;
      }
    } on auth.FirebaseAuthException catch (e) {
      _handleException(e);
    }
    return null;
  }

  void _onForgotEmailClick() {
    if (_tecEmail.text.trim().isEmpty) {
      DialogManager.showAlertDialog(
          context: context,
          title: 'Forgot Password',
          content: "Enter email in the 'Email' login text field to send the password reset link");
    } else {
      DialogManager.showConfirmationDialog(
              context: context,
              title: 'Password Reset',
              content: "Send password reset link to '${_tecEmail.text.trim()}?'")
          .then((confirm) {
        if (confirm) {
          _attemptToSendPasswordResetEmail().then((sent) {
            if (sent) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset link sent!'), behavior: SnackBarBehavior.floating));
            }
          });
        }
      });
    }
  }

  Future<bool> _attemptToSendPasswordResetEmail() async {
    try {
      DialogManager.showProgressDialog(context: context, title: 'Sending Password Reset Link!');
      await _authManager.sendPasswordResetEmail(_tecEmail.text.trim());
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _handleException(e);
    }
    return false;
  }

  void _handleException(final auth.FirebaseAuthException e) {
    Navigator.of(context).pop(); // pop the loading dialog
    const String title = 'Error';
    String content = 'Something went wrong!\n\n$e';
    if (e.code == 'invalid-email') {
      content = 'That email was badly formatted, please enter your complete email';
    } else if (e.code == 'email-already-in-use') {
      content = 'That email is already in use, please try to login';
    } else if (e.code == 'weak-password') {
      content = 'Password is really weak, please try a stronger alternative!';
    } else if (e.code == 'user-disabled') {
      content = 'This user has been disabled';
    } else if (e.code == 'user-not-found') {
      content = 'User with this email has not been found';
    } else if (e.code == 'wrong-password') {
      content = 'Wrong password, please try again or reset the password if forgotten';
    }
    DialogManager.showAlertDialog(context: context, title: title, content: content);
  }

  Future<bool> _onWillPop() async {
    DialogManager.showAlertDialog(context: context, title: 'CTRIM App', content: 'Please login to use the app');
    return _loggedIn;
  }
}
