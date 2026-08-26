import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../firebase/auth_manager.dart';
import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/db_managers/user_db_manager.dart';
import '../utility/app_context.dart';
import '../utility/dialog_manager.dart';
import 'common/app_dialog.dart';
import '../utility/event_heads_repository.dart';
import '../utility/notifications/notification_permission_prompt.dart';
import '../utility/users_repository.dart';

class GuestRegistrationCard extends StatefulWidget {
  const GuestRegistrationCard({super.key});

  @override
  State<GuestRegistrationCard> createState() => _GuestRegistrationCardState();
}

class _GuestRegistrationCardState extends State<GuestRegistrationCard> {
  bool _isSignUp = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  final AuthManager _authManager = AuthManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final UserDBManager _userDBManager = UserDBManager();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join CTRIM',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create an account to stay connected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Toggle between Sign Up and Sign In
            Container(
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Sign Up',
                      _isSignUp,
                      () {
                        setState(() {
                          _isSignUp = true;
                          _formKey.currentState?.reset();
                        });
                      },
                      theme,
                      colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      'Sign In',
                      !_isSignUp,
                      () {
                        setState(() {
                          _isSignUp = false;
                          _formKey.currentState?.reset();
                        });
                      },
                      theme,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !_isLoading,
                    obscureText: !_showPassword,
                    textInputAction:
                        _isSignUp ? TextInputAction.next : TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline,
                          color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (_isSignUp && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (_isSignUp) {
                        _confirmPasswordFocusNode.requestFocus();
                      } else {
                        _handleSubmit();
                      }
                    },
                  ),

                  // Confirm Password Field (Sign Up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      enabled: !_isLoading,
                      obscureText: !_showConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary),
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  // Forgot Password (Sign In only)
                  if (!_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Continue as Guest Button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final appContext =
                          Provider.of<AppContext>(context, listen: false);
                      appContext.sharedPref.setDismissedGuestBanner(true);
                      if (mounted) {
                        setState(() {});
                      }
                    },
              child: Text(
                'Continue as Guest',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();

    if (_isSignUp) {
      await _handleSignUp();
    } else {
      await _handleSignIn();
    }
  }

  Future<void> _handleSignUp() async {
    final confirmation = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Confirm Email Address',
      content:
          'We\'ll send a verification link to:\n\n${_emailController.text.trim()}\n\nMake sure you can access this email address.',
      confirmText: 'Send Verification',
      icon: Icons.email_outlined,
    );

    if (!confirmation) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final created = await DialogManager.runWithProgressDialog(
        context: context,
        title: 'Creating Account',
        subtitle: 'Setting up your account...',
        errorTitle: 'Registration Error',
        action: () async {
          try {
            await _authManager.registerUserAndSendVerification(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } on auth.FirebaseAuthException catch (e) {
            throw Exception(_firebaseAuthMessage(e));
          }
        },
      );

      if (!mounted || !created) return;

      final appContext = Provider.of<AppContext>(context, listen: false);
      appContext.analytics.logEvent(name: 'register email');

      await _showVerificationDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final signedIn = await DialogManager.runWithProgressDialog(
        context: context,
        title: 'Signing In',
        subtitle: 'Signing you in…',
        errorTitle: 'Login Error',
        action: () async {
          try {
            await _authManager.loginAndReturnAuthID(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } on auth.FirebaseAuthException catch (e) {
            throw Exception(_firebaseAuthMessage(e));
          }
        },
      );

      if (!mounted || !signedIn) return;

      await _completeAuthentication(false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showVerificationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        icon: Icons.mark_email_read_outlined,
        title: 'Verify Your Email',
        message:
            'We\'ve sent a verification link to:\n\n${_emailController.text.trim()}\n\nPlease check your email and click the verification link.',
        actions: AppDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: () async {
            Navigator.pop(context);
            await _checkVerificationAndComplete();
          },
          confirmLabel: "I've Verified",
        ),
      ),
    );
  }

  Future<void> _checkVerificationAndComplete() async {
    var verified = false;
    final checked = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Checking Verification',
      subtitle: 'Checking your email verification…',
      errorTitle: 'Verification check failed',
      action: () async {
        verified = await _authManager.hasUserVerifiedEmail();
      },
    );

    if (!mounted || !checked) return;

    if (!verified) {
      DialogManager.showAlertDialog(
        context: context,
        title: 'Email Not Verified',
        content:
            'Email verification is not complete yet. Please check your inbox at ${_emailController.text.trim()} and click the verification link.',
        icon: Icons.mark_email_unread_outlined,
        isError: true,
      );
      return;
    }

    final appContext = Provider.of<AppContext>(context, listen: false);
    appContext.analytics.logSignUp(signUpMethod: 'email-verified');

    await _completeAuthentication(true);
  }

  Future<void> _completeAuthentication(bool isNewUser) async {
    final ready = await DialogManager.runWithSteppedProgressDialog(
      title: 'Welcome to CTRIM!',
      initialMessage: 'Saving credentials…',
      context: context,
      errorTitle: 'Could not complete setup',
      action: (onProgress) async {
        const total = 4;
        final appContext = Provider.of<AppContext>(context, listen: false);

        onProgress(completed: 0, total: total, message: 'Saving credentials…');
        appContext.sharedPref.saveCreds(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (isNewUser) {
          onProgress(
              completed: 1, total: total, message: 'Creating your profile…');
          await _everyoneDBManager.createUser(
            _authManager.currentAuthUID,
            _emailController.text.trim(),
          );
        } else {
          onProgress(
              completed: 1, total: total, message: 'Setting up notifications…');
        }

        onProgress(
            completed: 2, total: total, message: 'Setting up notifications…');
        await _migrateFCMToken();

        onProgress(
            completed: 3, total: total, message: 'Loading posts and people…');
        await _fetchEssentialData();

        appContext.sharedPref.setLoggedOut(false);
        appContext.sharedPref.setDismissedGuestBanner(true);
      },
    );

    if (!mounted || !ready) return;

    // Soft-ask before the browser Allow prompt (web); skip cold getToken during setup.
    if (kIsWeb) {
      final appContext = Provider.of<AppContext>(context, listen: false);
      await NotificationPermissionPrompt.maybePromptAfterAuth(
        context: context,
        prefs: appContext.sharedPref,
        authId: _authManager.currentAuthUID,
      );
      if (!mounted) return;
    }

    // Return to Personal (this card lives on GuestRegistrationPage).
    Navigator.of(context).pop();
  }

  Future<void> _migrateFCMToken() async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final token = appContext.sharedPref.guestFcmToken;

    // Only migrate an existing guest token. Do not call getToken() here — that
    // can trigger the browser permission prompt without an in-app explainer.
    if (token.isEmpty) return;

    debugPrint('Migrating FCM token: $token');
    final String platformName = kIsWeb ? 'Web' : Platform.operatingSystem;
    appContext.sharedPref.saveFCMToken(token);
    appContext.sharedPref.clearGuestFCMToken();
    await _everyoneDBManager.addTokenForAuthID(
      authID: _authManager.currentAuthUID,
      token: token,
      platform: platformName,
    );
  }

  Future<void> _fetchEssentialData() async {
    final appContext = Provider.of<AppContext>(context, listen: false);

    final allUsers = await UsersRepository().fetchUsers();
    final heads = await EventHeadsRepository().fetchEventHeads();

    // Fetch current user
    final currentUser =
        await _userDBManager.fetchUserByAuthID(_authManager.currentAuthUID);

    if (currentUser != null) {
      // Update context with authenticated user data
      appContext.upgradeToAuthenticatedUser(
        user: currentUser,
        heads: heads,
        allUsers: allUsers,
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      DialogManager.showAlertDialog(
        context: context,
        title: 'Email Required',
        content: "Please enter your email address first, then try again.",
        icon: Icons.info_outline,
      );
      return;
    }

    final confirmed = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Reset Password',
      content: "Send password reset link to '${_emailController.text.trim()}'?",
      icon: Icons.email_outlined,
      confirmText: 'Send Link',
    );

    if (!confirmed) return;
    if (!mounted) return;

    final sent = await DialogManager.runWithProgressDialog(
      context: context,
      title: 'Sending Reset Link',
      subtitle: 'Sending email…',
      errorTitle: 'Could not send reset link',
      action: () async {
        try {
          await _authManager
              .sendPasswordResetEmail(_emailController.text.trim());
        } on auth.FirebaseAuthException catch (e) {
          throw Exception(_firebaseAuthMessage(e));
        }
      },
    );

    if (!mounted || !sent) return;

    DialogManager.showSnackBar(
      context: context,
      message: 'Password reset link sent to ${_emailController.text.trim()}',
      actionLabel: 'Got it',
      onActionPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );
  }

  String _firebaseAuthMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted. Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered. Please try signing in instead.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'The password is incorrect. Please try again or reset your password if you\'ve forgotten it.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'An unexpected error occurred. Please try again later.';
    }
  }
}
