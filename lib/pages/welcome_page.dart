import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../firebase/auth_manager.dart';
import '../firebase/db_managers/event_db_manager.dart';
import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/db_managers/id_tracker.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../firebase/messaging_manager.dart';
import '../models/user.dart';
import '../utility/app_context.dart';
import '../utility/dialog_manager.dart';
import '../utility/local_data_manager.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppContext _appContext;
  final TextEditingController _tecRegistrationEmail = TextEditingController(),
      _tecRegistrationPassword = TextEditingController(),
      _tecRegistrationPasswordConfirmation = TextEditingController(),
      _tecLoginEmail = TextEditingController(),
      _tecLoginPassword = TextEditingController();
  final AuthManager _authManager = AuthManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final UserDBManager _userDBManager = UserDBManager();
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
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;

    return Scaffold(
        appBar: AppBar(
            title: const Text('Hi, Welcome!'),
            centerTitle: false,
            leading: Image.asset('assets/images/ctrim_logo.png', fit: BoxFit.contain, height: kToolbarHeight),
            bottom: _isWaitingForVerification
                ? null
                : TabBar(controller: _tabController, tabs: const [Tab(text: 'Registration'), Tab(text: 'Login')])),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          child: _isWaitingForVerification
              ? _buildWaitingForVerification()
              : TabBarView(controller: _tabController, children: [_buildRegistrationTab(), _buildLoginTab()]),
        ));
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
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(label: Text('Email'), prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tecLoginPassword,
              onSubmitted: (_) => _fnLoginPassword.unfocus(),
              focusNode: _fnLoginPassword,
              obscureText: !_showLoginPassword,
              textInputAction: TextInputAction.next,
              keyboardType: _showLoginPassword ? TextInputType.visiblePassword : null,
              decoration: InputDecoration(
                  label: const Text('Password'),
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                      onPressed: () => setState(() {
                            _showLoginPassword = !_showLoginPassword;
                          }),
                      icon: Icon(
                        _showLoginPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ))),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _onForgotEmailClick, child: const Text('Forgot Password'))),
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
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _fnPassword.requestFocus(),
                      decoration: const InputDecoration(label: Text('Email'), prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _tecRegistrationPassword,
                      keyboardType: _showRegisterPassword ? TextInputType.visiblePassword : null,
                      obscureText: !_showRegisterPassword,
                      textInputAction: TextInputAction.next,
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
                                color: Colors.grey,
                              )))),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _tecRegistrationPasswordConfirmation,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      focusNode: _fnConfirmPassword,
                      onSubmitted: (_) => _fnConfirmPassword.unfocus(),
                      decoration:
                          const InputDecoration(label: Text('Confirm Password'), prefixIcon: Icon(Icons.password))),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: _registerClick, child: const Text('Register Account')),
                  const SizedBox(height: 16),
                  kIsWeb ? _buildLegalStuffSection() : Container(),
                ])));
  }

  Widget _buildLegalStuffSection() {
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    return Center(
      child: RichText(
          text: TextSpan(children: <TextSpan>[
        TextSpan(
            text: 'By creating an account, I agree to CTRIM App\'s ',
            style: TextStyle(color: onDark ? Colors.white : Colors.black)),
        TextSpan(
          text: 'Terms and Conditions',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              launchUrlString('https://ctrim-terms-and-conditions.web.app');
            },
        ),
        TextSpan(text: ' and ', style: TextStyle(color: onDark ? Colors.white : Colors.black)),
        TextSpan(
          text: 'Privacy Policy',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              launchUrlString('https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b');
            },
        )
      ])),
    );
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
  Future<void> _loginClick() async {
    if (_tecLoginEmail.text.trim().isEmpty || _tecLoginPassword.text.isEmpty) {
      DialogManager.showAlertDialog(
          context: context, title: 'Login', content: 'Please provide your email and password to login');
    } else {
      _attemptToLogin().then((loggedIn) {
        if (loggedIn) {
          _appContext.analytics.logLogin(loginMethod: 'welcome page');
          Navigator.of(context).pop();
          _attemptToFetchAndSetUser().then((_) => _instantiateTheRest(false));
        }
      });
    }
  }

  Future<bool> _attemptToLogin() async {
    try {
      DialogManager.showProgressDialog(context: context, title: 'Attempting to Login');
      await _authManager.loginAndReturnAuthID(_tecLoginEmail.text.trim(), _tecLoginPassword.text);
      if (!await _authManager.hasUserVerifiedEmail()) {
        _authManager
            .signOut()
            .then((_) => DialogManager.showAlertDialog(
                context: context,
                title: 'Login Error',
                content: 'This user has not been verified, please look for your verify email link!'))
            .then((_) {
          Navigator.of(context).pop();
        });
      } else {
        return true;
      }
    } on auth.FirebaseAuthException catch (e) {
      _handleFirebaseException(e);
    } on Exception catch (e) {
      debugPrint('Something went really wrong for login: $e');
      _handleException(e, 'Login Error!');
    }
    return false;
  }

  Future<void> _attemptToFetchAndSetUser() async {
    final u = await _userDBManager.fetchUserByAuthID(_authManager.currentAuthUID);
    _appContext.setCurrentUser(u);
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
    } on auth.FirebaseAuthException catch (e) {
      _handleFirebaseException(e);
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
        confirmText: 'Send Verification Email');

    if (confirmation) {
      await _attemptToRegister().then((canVerifyEmail) {
        if (canVerifyEmail) {
          _appContext.analytics.logEvent(name: 'register email');
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
    } on auth.FirebaseAuthException catch (e) {
      _handleFirebaseException(e);
    } on Exception catch (e) {
      debugPrint('Something went really wrong for registration: $e');
      _handleException(e, 'Registration Error!');
    }
    return false;
  }

  void _handleFirebaseException(final auth.FirebaseAuthException e) {
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

  void _handleException(final Exception e, final String title) {
    DialogManager.showAlertDialog(context: context, title: title, content: 'See exception: $e');
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
        _appContext.analytics.logSignUp(signUpMethod: 'email-verified');
        debugPrint('creating user with auth: ${_authManager.currentAuthUID}');
        Navigator.of(context).pop();
        _instantiateTheRest(true);
      }
    });
  }

  Future<void> _instantiateTheRest(bool fromRegistration) async {
    DialogManager.showProgressDialog(title: 'Success! Loading the rest of the app', context: context);
    _saveCreds(fromRegistration);

    if (fromRegistration) {
      await _everyoneDBManager.createUser(_authManager.currentAuthUID, _tecRegistrationEmail.text.trim());
    }
    _saveFCMToken();
    _fetchEssentialData().then((_) {
      debugPrint('opened home page here');
      _appContext.sharedPref.setLoggedOut(false);
      Navigator.of(context).pop(); // pop the progress dialog
      Navigator.of(context).pop(); // pop twice to close this page and then load the home page as the first?
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  Future<void> _fetchEssentialData() async {
    final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
    final allUsers = await _fetchUsers();
    final heads = await eventHeadDBManager.fetchEventHeads();
    _appContext.allUsers.addAll(allUsers);
    _appContext.addAllEventHeads(heads);
  }

  Future<void> _saveFCMToken() async {
    final MessagingManager messagingManager = MessagingManager();
    final token = await messagingManager.getToken();
    if (token != null) {
      debugPrint('token to save is $token');
      final String platform = kIsWeb ? 'Web' : Platform.operatingSystem;
      _appContext.sharedPref.saveFCMToken(token);
      _everyoneDBManager.addTokenForAuthID(authID: _authManager.currentAuthUID, token: token, platform: platform);
    }
  }

  Future<List<User>> _fetchUsers() async {
    debugPrint('--fetching users from DB');
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final LocalDataManager dataManager = LocalDataManager();
    final IDTrackerDBManager trackerDBManager = IDTrackerDBManager();

    final List<User> allUsers = await _userDBManager.fetchAllUsers();
    final String currentID = await trackerDBManager.getCurrentUserID();

    String allUsersContent = '$currentID-${packageInfo.version}';
    for (final user in allUsers) {
      allUsersContent += '\n${user.id}';
      allUsersContent += '\n${user.forname}';
      allUsersContent += '\n${user.surname}';
      allUsersContent += '\n${user.imgSrc}';
      allUsersContent += '\n${user.isLeader ? '1' : '0'}';
      allUsersContent += '\n${user.isAreaAdmin ? '1' : '0'}';
      allUsersContent += '\n${user.location}';
      allUsersContent += '\n${user.authID}';
    }

    debugPrint('--writing users from DB');
    // this write thing should be updated when we register users
    if (kIsWeb) {
      _appContext.sharedPref.setUsersData(allUsersContent);
      _appContext.sharedPref.setLastUsersFetch();
    } else {
      await dataManager.writeUsersList(allUsersContent);
      await dataManager.writeLastUsersFetch();
    }
    return allUsers;
  }

  Future<void> _saveCreds(bool fromRegistration) async {
    if (fromRegistration) {
      debugPrint(
          'Creds to save are: ${_tecRegistrationEmail.text.trim()} with password ${_tecRegistrationPassword.text}');
      _appContext.sharedPref.saveCreds(_tecRegistrationEmail.text.trim(), _tecRegistrationPassword.text);
    } else {
      debugPrint('Creds to save are: ${_tecLoginEmail.text.trim()} with password ${_tecLoginPassword.text}');
      _appContext.sharedPref.saveCreds(_tecLoginEmail.text.trim(), _tecLoginPassword.text);
    }
  }
}
