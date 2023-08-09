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

  bool _isWaitingForVerification = false;

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
            title: const Text(
              'Startup login/registration',
            ),
            bottom: _isWaitingForVerification
                ? null
                : TabBar(controller: _tabController, tabs: const [Tab(text: 'Login'), Tab(text: 'Registration')])),
        body: _isWaitingForVerification
            ? _buildWaitingForVerification()
            : TabBarView(controller: _tabController, children: [_buildLoginTab(), _buildRegistrationTab()]));
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
              decoration: const InputDecoration(label: Text('Password'), prefixIcon: Icon(Icons.password)),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _attemptToLogin, child: const Text('Forgot Password'))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loginClick, child: const Text('Login')),
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
                obscureText: true,
                focusNode: _fnPassword,
                onSubmitted: (_) => _fnConfirmPassword.requestFocus(),
                decoration: const InputDecoration(label: Text('Password'), prefixIcon: Icon(Icons.password))),
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
          const Text(
            'Awaiting Email Verification!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21),
          ),
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(onPressed: _onRefreshVerificationClick, child: const Text('Refresh')))
        ],
      ),
    ));
  }

  // * LOGIC
  Future<void> _loginClick() async {}

  Future<bool> _attemptToLogin() async {
    try {
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
      final bool canVerifyEmail = await _attemptToRegister();
      if (canVerifyEmail) {
        setState(() {
          _isWaitingForVerification = true;
        });
      }
    }
  }

  Future<bool> _attemptToRegister() async {
    try {
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
    if (e.code == 'invalid-email') {
      DialogManager.showAlertDialog(context: context, title: 'Error', content: 'That email badly formatted');
    } else if (e.code == 'email-already-in-use') {
      DialogManager.showAlertDialog(
          context: context, title: 'Error', content: 'That email is already in use, please try to login');
    } else if (e.code == 'weak-password') {
      DialogManager.showAlertDialog(
          context: context, title: 'Error', content: 'Password is really weak, please try a stronger alternative!');
    } else if (e.code == 'user-disabled') {
      DialogManager.showAlertDialog(context: context, title: 'Error', content: 'This user has been disabled');
    } else if (e.code == 'user-not-found') {
      DialogManager.showAlertDialog(
          context: context, title: 'Error', content: 'User with this email has not been found');
    } else if (e.code == 'wrong-password') {
      DialogManager.showAlertDialog(
          context: context,
          title: 'Error',
          content: 'Wrong password, please try again or reset the password if forgotten');
    } else {
      DialogManager.showAlertDialog(context: context, title: 'Error', content: 'Something went wrong!\n\n$e');
    }
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
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // pop twice to close this page and then load the home page as the first?
      debugPrint('opened home page here');
    });
  }

  Future<void> _fetchEssentialData() async {}

  Future<void> _saveCreds(bool fromRegistration) async {
    if (fromRegistration) {
      _appContext.dataManager.saveCreds(_tecRegistrationEmail.text.trim(), _tecRegistrationPassword.text);
    } else {
      _appContext.dataManager.saveCreds(_tecLoginEmail.text.trim(), _tecLoginPassword.text);
    }
  }
}
