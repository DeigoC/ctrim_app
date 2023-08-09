import 'package:ctrim_app/firebase/auth_manager.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartupLoginPage extends StatefulWidget {
  const StartupLoginPage({super.key});

  @override
  State<StartupLoginPage> createState() => _StartupLoginPageState();
}

class _StartupLoginPageState extends State<StartupLoginPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppContext _appContext;
  final TextEditingController _tecRegistrationEmail = TextEditingController(),
      _tecRegistrationPassword = TextEditingController(),
      _tecRegistrationPasswordConfirmation = TextEditingController(),
      _tecLoginEmail = TextEditingController(),
      _tecLoginPassword = TextEditingController();
  final AuthManager _authManager = AuthManager();
  final FocusNode _fnPassword = FocusNode(), _fnConfirmPassword = FocusNode(), _fnLoginPassword = FocusNode();

  bool _isWaitingForVerification = false, _showLoginPassword = false, _showRegisterPassword = false;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    _tecRegistrationEmail.dispose();
    _tecRegistrationPassword.dispose();
    _tecRegistrationPasswordConfirmation.dispose();
    _fnPassword.dispose();
    _fnConfirmPassword.dispose();
    _tecLoginEmail.dispose();
    _tecLoginPassword.dispose();
    _fnLoginPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Hi, Welcome!'),
            centerTitle: false,
            leading: Image.asset('assets/images/ctrim_logo.png', fit: BoxFit.contain, height: kToolbarHeight),
            bottom: _isWaitingForVerification
                ? null
                : TabBar(controller: _tabController, tabs: const [Tab(text: 'Registration'), Tab(text: 'Login')])),
        body: _isWaitingForVerification
            ? _buildWaitingForVerification()
            : TabBarView(controller: _tabController, children: [_buildRegistrationTab(), _buildLoginTab()]));
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _tecLoginEmail,
              onSubmitted: (_) => _fnLoginPassword.requestFocus(),
              decoration: const InputDecoration(label: Text('Email'), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tecLoginPassword,
              onSubmitted: (_) => _fnLoginPassword.unfocus(),
              focusNode: _fnLoginPassword,
              obscureText: _showLoginPassword,
              decoration: InputDecoration(
                  label: const Text('Password'),
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                      onPressed: () => setState(() {
                            _showLoginPassword = !_showLoginPassword;
                          }),
                      icon: Icon(
                        _showLoginPassword ? Icons.visibility_off : Icons.visibility,
                        color: _showLoginPassword ? Colors.grey : Colors.blue,
                      ))),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _onForgotEmailClick, child: const Text('Forgot Password'))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loginClick, child: const Text('Login')),
            ElevatedButton(onPressed: _testButton, child: const Text('Test Button')),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationTab() {
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
                controller: _tecRegistrationEmail,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _fnPassword.requestFocus(),
                decoration: const InputDecoration(label: Text('Email'), prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 8),
            TextField(
                controller: _tecRegistrationPassword,
                keyboardType: TextInputType.visiblePassword,
                obscureText: _showRegisterPassword,
                focusNode: _fnPassword,
                onSubmitted: (_) => _fnConfirmPassword.requestFocus(),
                decoration: InputDecoration(
                    label: const Text('Password'),
                    prefixIcon: const Icon(Icons.password),
                    suffixIcon: IconButton(
                        onPressed: () => setState(() {
                              _showRegisterPassword = !_showRegisterPassword;
                            }),
                        icon: Icon(
                          _showRegisterPassword ? Icons.visibility_off : Icons.visibility,
                          color: _showRegisterPassword ? Colors.grey : Colors.blue,
                        )))),
            const SizedBox(height: 8),
            TextField(
                controller: _tecRegistrationPasswordConfirmation,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                focusNode: _fnConfirmPassword,
                onSubmitted: (_) => _fnConfirmPassword.unfocus(),
                decoration: const InputDecoration(label: Text('Confirm Password'), prefixIcon: Icon(Icons.password))),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _registerClick, child: const Text('Send Verification Email')),
          ]),
    ));
  }

  Widget _buildWaitingForVerification() {
    return Center(
        child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Verification Link Sent! Awaiting Email Verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(onPressed: _onRefreshVerificationClick, child: const Text('Refresh')))
        ],
      ),
    ));
  }

  // * LOGIC
  void _testButton() {
    _authManager.whoAmI();
  }

  Future<void> _loginClick() async {
    if (_tecLoginEmail.text.trim().isEmpty || _tecLoginPassword.text.isEmpty) {
      DialogManager.showAlertDialog(
          context: context, title: 'Login', content: 'Please provide your email and password to login');
    } else {
      _attemptToLogin().then((loggedIn) {
        if (loggedIn) {
          Navigator.of(context).pop();
          _instantiateTheRest(false);
        }
      });
    }
  }

  Future<bool> _attemptToLogin() async {
    try {
      DialogManager.showProgressDialog(context: context, title: 'Attempting to Login');
      await _authManager.loginAndReturnAuthID(_tecLoginEmail.text.trim(), _tecLoginPassword.text);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleException(e);
    } on Exception catch (e) {
      debugPrint('Something went really wrong for login: $e');
      DialogManager.showAlertDialog(context: context, title: 'Login Error', content: 'See exception: $e');
    }
    return false;
  }

  void _onForgotEmailClick() {
    if (_tecLoginEmail.text.trim().isEmpty) {
      DialogManager.showAlertDialog(
          context: context,
          title: 'Forgot Password',
          content: "Enter email in the 'Email' login text field to send the password reset link");
    } else {
      DialogManager.showConfirmationDialog(
              context: context,
              title: 'Password Reset',
              content: "Send password reset link to '${_tecLoginEmail.text.trim()}?'")
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
      await _authManager.sendPasswordResetEmail(_tecLoginEmail.text.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _handleException(e);
    }
    return false;
  }

  Future<void> _registerClick() async {
    if (_tecRegistrationEmail.text.trim().isEmpty || _tecRegistrationPassword.text.isEmpty) {
      DialogManager.showAlertDialog(
          context: context, title: 'Registration', content: 'Please provide an email and password');
      return;
    }
    if (_tecRegistrationPassword.text.compareTo(_tecRegistrationPasswordConfirmation.text) != 0) {
      DialogManager.showAlertDialog(context: context, title: 'Registration', content: 'Passwords do not match');
      return;
    }

    final bool confirmation = await DialogManager.showConfirmationDialog(
        context: context,
        title: 'Registration',
        content: 'Are you sure you can verify the following email?\n\n${_tecRegistrationEmail.text.trim()}',
        confirmText: 'Send Verification!');

    if (confirmation) {
      await _attemptToRegister().then((canVerifyEmail) {
        if (canVerifyEmail) {
          Navigator.of(context).pop();
          setState(() {
            _isWaitingForVerification = true;
          });
        }
      });
    }
  }

  Future<bool> _attemptToRegister() async {
    try {
      DialogManager.showProgressDialog(context: context, title: 'Attempting To Register');
      await _authManager.registerUserAndSendVerification(
          _tecRegistrationEmail.text.trim(), _tecRegistrationPassword.text);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleException(e);
    } on Exception catch (e) {
      debugPrint('Something went really wrong for registration: $e');
      DialogManager.showAlertDialog(context: context, title: 'Registration Error', content: 'See exception: $e');
    }
    return false;
  }

  void _handleException(final FirebaseAuthException e) {
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

  // ! There's technically a chance that the user token might be expired by then
  Future<void> _onRefreshVerificationClick() async {
    DialogManager.showProgressDialog(context: context, title: 'Refreshing');
    await _authManager.hasUserVerifiedEmail().then((verified) {
      if (!verified) {
        Navigator.of(context).pop();
        DialogManager.showAlertDialog(
            context: context,
            title: 'Error',
            content: 'Email verification not complete! Please check your emails on ${_tecRegistrationEmail.text}');
      } else {
        // show done dialog and loading data
        Navigator.of(context).pop();
        _instantiateTheRest(true);
      }
    });
  }

  void _instantiateTheRest(bool fromRegistration) {
    DialogManager.showProgressDialog(title: 'Success! Loading the rest of the app', context: context);
    _saveCreds(fromRegistration);
    _fetchEssentialData().then((_) {
      debugPrint('opened home page here');
      Navigator.of(context).pop(); // pop the progress dialog
      Navigator.of(context).pop(); // pop twice to close this page and then load the home page as the first?
    });
  }

  Future<void> _fetchEssentialData() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _saveCreds(bool fromRegistration) async {
    if (fromRegistration) {
      debugPrint(
          'Creds to save are: ${_tecRegistrationEmail.text.trim()} with password ${_tecRegistrationPassword.text}');
      _appContext.dataManager.saveCreds(_tecRegistrationEmail.text.trim(), _tecRegistrationPassword.text);
    } else {
      debugPrint('Creds to save are: ${_tecLoginEmail.text.trim()} with password ${_tecLoginPassword.text}');
      _appContext.dataManager.saveCreds(_tecLoginEmail.text.trim(), _tecLoginPassword.text);
    }
  }
}
