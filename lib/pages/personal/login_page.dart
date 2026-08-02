import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/web_notification_lifecycle.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _tecEmail = TextEditingController();
  final TextEditingController _tecPassword = TextEditingController();
  final FocusNode _fnEmail = FocusNode();
  final FocusNode _fnPassword = FocusNode();
  final AuthManager _authManager = AuthManager();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loggedIn = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _tecEmail.dispose();
    _tecPassword.dispose();
    _fnEmail.dispose();
    _fnPassword.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Responsive padding
    final double horizontalPadding = ResponsiveLayout.horizontalGutter(size.width, narrowPadding: 24.0);

    return PopScope(
      canPop: _loggedIn,
      onPopInvokedWithResult: (didPop, result) => _loggedIn ? null : _onWillPop(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: Container(),
          centerTitle: true,
        ),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo/Header Section
                          _buildHeaderSection(theme, colorScheme),

                          const SizedBox(height: 48),

                          // Email Field
                          _buildEmailField(theme, colorScheme),

                          const SizedBox(height: 24),

                          // Password Field
                          _buildPasswordField(theme, colorScheme),

                          const SizedBox(height: 16),

                          // Forgot Password Link
                          _buildForgotPasswordLink(theme, colorScheme),

                          const SizedBox(height: 32),

                          // Login Button
                          _buildLoginButton(theme, colorScheme),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // * UI Components

  Widget _buildHeaderSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // App icon/logo placeholder - you can replace with your actual logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.church_rounded, // Replace with your app's icon
            size: 64,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'CTRIM App',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _tecEmail,
      focusNode: _fnEmail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email address',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onFieldSubmitted: (_) => _fnPassword.requestFocus(),
    );
  }

  Widget _buildPasswordField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _tecPassword,
      focusNode: _fnPassword,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
      onFieldSubmitted: (_) => _onLoginClick(),
    );
  }

  Widget _buildForgotPasswordLink(ThemeData theme, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _onForgotEmailClick,
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          'Forgot Password?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _onLoginClick,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login,
                    size: 20,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign In',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // * Logic

  void _onLoginClick() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    final success = await DialogManager.runWithSteppedProgressDialog(
      context: context,
      title: 'Signing In',
      initialMessage: 'Signing in…',
      errorTitle: 'Login Error',
      action: (onProgress) async {
        const total = 3;
        onProgress(completed: 0, total: total, message: 'Signing in…');
        final authID = await _attemptToLogin();

        onProgress(completed: 1, total: total, message: 'Loading your profile…');
        await _logUserToApp(authID, onProgress: onProgress, totalSteps: total);
      },
    );

    if (!mounted) return;
    if (!success) {
      setState(() => _isLoading = false);
      return;
    }

    // PopScope reads canPop from the last build. Update _loggedIn via setState,
    // then pop on the next frame so canPop is true and the route can close.
    setState(() {
      _isLoading = false;
      _loggedIn = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _logUserToApp(
    final String authID, {
    LoadProgressReporter? onProgress,
    int totalSteps = 3,
  }) async {
    final appContext = Provider.of<AppContext>(context, listen: false);

    // Defer token registration on first open; HomePage shows welcome before any prompt.
    if (!appContext.sharedPref.isFirstOpen) {
      if (kIsWeb) {
        final lifecycle = WebNotificationLifecycle();
        await lifecycle.register(
          authId: authID,
          onTokenSaved: appContext.sharedPref.saveFCMToken,
          prefs: appContext.sharedPref,
          webAuthId: authID,
        );
      } else {
        final MessagingManager messagingManager = MessagingManager();
        final String? token = await messagingManager.getToken();
        if (token != null) {
          final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
          everyoneDBManager.addTokenForAuthID(authID: authID, token: token, platform: Platform.operatingSystem);
          appContext.sharedPref.saveFCMToken(token);
        }
      }
    }

    final UserDBManager userDBManager = UserDBManager();
    final user = await userDBManager.fetchUserByAuthID(authID);
    if (user == null) {
      throw Exception('No user profile found for this account. Please contact an admin.');
    }

    onProgress?.call(completed: 2, total: totalSteps, message: 'Finishing…');
    appContext.sharedPref.saveCreds(_tecEmail.text.trim(), _tecPassword.text);
    appContext.setCurrentUser(user);
    appContext.sharedPref.setLoggedOut(false);
    appContext.analytics.logLogin(loginMethod: 'in-app login page');
  }

  Future<String> _attemptToLogin() async {
    try {
      final String authID = await _authManager.loginAndReturnAuthID(
        _tecEmail.text.trim(),
        _tecPassword.text,
      );

      if (!await _authManager.hasUserVerifiedEmail()) {
        await _authManager.signOut();
        throw Exception(
          'Please verify your email address before signing in. Check your inbox for the verification link.',
        );
      }
      return authID;
    } on auth.FirebaseAuthException catch (e) {
      throw Exception(_firebaseAuthMessage(e));
    }
  }

  void _onForgotEmailClick() {
    if (_tecEmail.text.trim().isEmpty) {
      DialogManager.showAlertDialog(
        context: context,
        title: 'Email Required',
        content: "Please enter your email address in the 'Email' field first, then try again.",
        icon: Icons.info_outline,
      );
      return;
    }

    DialogManager.showConfirmationDialog(
      context: context,
      title: 'Reset Password',
      content: "Send password reset link to '${_tecEmail.text.trim()}'?",
      icon: Icons.email_outlined,
      confirmText: 'Send Link',
    ).then((confirm) async {
      if (!confirm || !mounted) return;
      final sent = await DialogManager.runWithProgressDialog(
        context: context,
        title: 'Sending Reset Link',
        subtitle: 'Sending email…',
        errorTitle: 'Could not send reset link',
        action: () async {
          try {
            await _authManager.sendPasswordResetEmail(_tecEmail.text.trim());
          } on auth.FirebaseAuthException catch (e) {
            throw Exception(_firebaseAuthMessage(e));
          }
        },
      );
      if (!sent || !mounted) return;
      DialogManager.showSnackBar(
        context: context,
        message: 'Password reset link sent to ${_tecEmail.text.trim()}',
        actionLabel: 'Got it',
        onActionPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      );
    });
  }

  String _firebaseAuthMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted. Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered. Please try signing in instead.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'An unexpected error occurred. Please try again later.';
    }
  }

  Future<bool> _onWillPop() async {
    DialogManager.showAlertDialog(
      context: context,
      title: 'Sign In Required',
      content: 'You need to sign in to access the CTRIM app features.',
      icon: Icons.login,
    );
    return _loggedIn;
  }
}
