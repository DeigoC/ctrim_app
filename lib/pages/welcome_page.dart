import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AppContext _appContext;
  late final AnimationController _heroAnimationController;
  late final AnimationController _contentAnimationController;
  late final Animation<double> _heroFadeAnimation;
  late final Animation<double> _heroScaleAnimation;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  // Form controllers
  final TextEditingController _tecRegistrationEmail = TextEditingController();
  final TextEditingController _tecRegistrationPassword = TextEditingController();
  final TextEditingController _tecRegistrationPasswordConfirmation = TextEditingController();
  final TextEditingController _tecLoginEmail = TextEditingController();
  final TextEditingController _tecLoginPassword = TextEditingController();

  // Form keys for validation
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();

  // Managers
  final AuthManager _authManager = AuthManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final UserDBManager _userDBManager = UserDBManager();

  // Focus nodes
  final FocusNode _fnRegisterPassword = FocusNode();
  final FocusNode _fnConfirmPassword = FocusNode();
  final FocusNode _fnLoginPassword = FocusNode();

  // State variables
  bool _isWaitingForVerification = false;
  bool _showLoginPassword = false;
  bool _showRegisterPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _appContext = Provider.of<AppContext>(context, listen: false);

    // Initialize animation controllers
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Hero animations
    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _heroScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Content animations
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _heroAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tecRegistrationEmail.dispose();
    _tecRegistrationPassword.dispose();
    _tecRegistrationPasswordConfirmation.dispose();
    _fnRegisterPassword.dispose();
    _fnConfirmPassword.dispose();
    _tecLoginEmail.dispose();
    _tecLoginPassword.dispose();
    _fnLoginPassword.dispose();
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Responsive padding
    final double horizontalPadding = size.width >= 768 ? size.width / 6 : 24.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _isWaitingForVerification
            ? _buildWaitingForVerification(theme, colorScheme)
            : _buildMainContent(theme, colorScheme, horizontalPadding),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme, double horizontalPadding) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          // Hero Header Section - Collapsible
          SliverToBoxAdapter(
            child: _buildHeroHeader(theme, colorScheme),
          ),

          // Tab Bar - Sticky
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              child: AnimatedBuilder(
                animation: _contentFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Container(
                      color: colorScheme.surface,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: colorScheme.onPrimary,
                          unselectedLabelColor: colorScheme.onSurfaceVariant,
                          labelStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: theme.textTheme.titleMedium,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tabs: const [
                            Tab(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('Sign Up'),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ];
      },
      body: AnimatedBuilder(
        animation: _contentSlideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _contentSlideAnimation,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRegistrationTab(theme, colorScheme),
                    _buildLoginTab(theme, colorScheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, ColorScheme colorScheme) {
    // Get text scale factor to adjust sizes for accessibility
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeText = textScaleFactor > 1.2;

    // Adjust sizes based on text scaling for better accessibility
    final logoSize = isLargeText ? 80.0 : 120.0;
    final logoPadding = isLargeText ? 16.0 : 32.0;
    final spacing = isLargeText ? 12.0 : 24.0;

    return AnimatedBuilder(
      animation: _heroFadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _heroScaleAnimation.value,
          child: Opacity(
            opacity: _heroFadeAnimation.value,
            child: Container(
              padding: EdgeInsets.all(logoPadding),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(isLargeText ? 24 : 32),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isLargeText ? 24 : 32),
                      child: Image.asset(
                        'assets/images/ctrim_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.church_rounded,
                            size: logoSize * 0.5,
                            color: colorScheme.onPrimaryContainer,
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // Welcome Text
                  Text(
                    'Welcome to CTRIM',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: spacing / 3),

                  Text(
                    'Connect, grow, and thrive in faith',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Email Field
            TextFormField(
              controller: _tecLoginEmail,
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
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
              onFieldSubmitted: (_) => _fnLoginPassword.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _tecLoginPassword,
              focusNode: _fnLoginPassword,
              obscureText: !_showLoginPassword,
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
                      _showLoginPassword = !_showLoginPassword;
                    });
                  },
                  icon: Icon(
                    _showLoginPassword ? Icons.visibility_off : Icons.visibility,
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
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              onFieldSubmitted: (_) => _loginClick(),
            ),

            const SizedBox(height: 16),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _onForgotEmailClick,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                child: Text(
                  'Forgot Password?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _loginClick,
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
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Form(
        key: _registrationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Email Field
            TextFormField(
              controller: _tecRegistrationEmail,
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
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
              onFieldSubmitted: (_) => _fnRegisterPassword.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _tecRegistrationPassword,
              focusNode: _fnRegisterPassword,
              obscureText: !_showRegisterPassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a strong password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showRegisterPassword = !_showRegisterPassword;
                    });
                  },
                  icon: Icon(
                    _showRegisterPassword ? Icons.visibility_off : Icons.visibility,
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
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _fnConfirmPassword.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Confirm Password Field
            TextFormField(
              controller: _tecRegistrationPasswordConfirmation,
              focusNode: _fnConfirmPassword,
              obscureText: !_showConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
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
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _tecRegistrationPassword.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onFieldSubmitted: (_) => _registerClick(),
            ),

            const SizedBox(height: 32),

            // Register Button
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _registerClick,
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
                            Icons.person_add,
                            size: 20,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Account',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Legal Section (only for web)
            if (kIsWeb) _buildLegalStuffSection(theme, colorScheme),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalStuffSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          children: <TextSpan>[
            const TextSpan(
              text: 'By creating an account, you agree to our ',
            ),
            TextSpan(
              text: 'Terms and Conditions',
              style: TextStyle(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrlString('https://ctrim-terms-and-conditions.web.app');
                },
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrlString('https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b');
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForVerification(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Verification Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Check Your Email',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Email address display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tecRegistrationEmail.text.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _onRefreshVerificationClick,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: colorScheme.onPrimary,
                      ),
                label: Text(
                  _isLoading ? 'Checking...' : 'I\'ve Verified My Email',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Text(
              'Didn\'t receive the email? Check your spam folder or try refreshing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // * LOGIC
  Future<void> _loginClick() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    final loggedIn = await _attemptToLogin();
    if (loggedIn) {
      _appContext.analytics.logLogin(loginMethod: 'welcome page');
      Navigator.of(context).pop();
      await _attemptToFetchAndSetUser();
      _instantiateTheRest(false);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _attemptToLogin() async {
    try {
      DialogManager.showProgressDialog(
        context: context,
        title: 'Signing In',
        subtitle: 'Please wait while we authenticate you...',
      );

      await _authManager.loginAndReturnAuthID(
        _tecLoginEmail.text.trim(),
        _tecLoginPassword.text,
      );

      if (!await _authManager.hasUserVerifiedEmail()) {
        await _authManager.signOut();
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          await DialogManager.showAlertDialog(
            context: context,
            title: 'Email Verification Required',
            content: 'Please verify your email address before signing in. Check your inbox for the verification link.',
            icon: Icons.mark_email_unread_outlined,
            isError: true,
          );
        }
        return false;
      } else {
        return true;
      }
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) {
        _handleFirebaseException(e);
      }
      return false;
    } on Exception catch (e) {
      debugPrint('Something went really wrong for login: $e');
      if (mounted) {
        _handleException(e, 'Login Error!');
      }
      return false;
    }
  }

  Future<void> _attemptToFetchAndSetUser() async {
    final u = await _userDBManager.fetchUserByAuthID(_authManager.currentAuthUID);
    _appContext.setCurrentUser(u);
  }

  void _onForgotEmailClick() {
    if (_tecLoginEmail.text.trim().isEmpty) {
      DialogManager.showAlertDialog(
        context: context,
        title: 'Email Required',
        content: "Please enter your email address first, then try again.",
        icon: Icons.info_outline,
      );
      return;
    }

    DialogManager.showConfirmationDialog(
      context: context,
      title: 'Reset Password',
      content: "Send password reset link to '${_tecLoginEmail.text.trim()}'?",
      icon: Icons.email_outlined,
      confirmText: 'Send Link',
    ).then((confirm) {
      if (confirm) {
        _attemptToSendPasswordResetEmail().then((sent) {
          if (sent && mounted) {
            Navigator.of(context).pop(); // Close any open dialogs
            DialogManager.showSnackBar(
              context: context,
              message: 'Password reset link sent to ${_tecLoginEmail.text.trim()}',
              actionLabel: 'Got it',
              onActionPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            );
          }
        });
      }
    });
  }

  Future<bool> _attemptToSendPasswordResetEmail() async {
    try {
      DialogManager.showProgressDialog(
        context: context,
        title: 'Sending Reset Link',
        subtitle: 'Please wait...',
      );
      await _authManager.sendPasswordResetEmail(_tecLoginEmail.text.trim());
      return true;
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) {
        _handleFirebaseException(e);
      }
      return false;
    }
  }

  Future<void> _registerClick() async {
    if (!_registrationFormKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();

    final bool confirmation = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Confirm Email Address',
      content:
          'We\'ll send a verification link to:\n\n${_tecRegistrationEmail.text.trim()}\n\nMake sure you can access this email address.',
      confirmText: 'Send Verification',
      icon: Icons.email_outlined,
    );

    if (confirmation) {
      setState(() {
        _isLoading = true;
      });

      final canVerifyEmail = await _attemptToRegister();
      if (canVerifyEmail) {
        _appContext.analytics.logEvent(name: 'register email');
        Navigator.of(context).pop();
        setState(() {
          _isWaitingForVerification = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _attemptToRegister() async {
    try {
      DialogManager.showProgressDialog(
        context: context,
        title: 'Creating Account',
        subtitle: 'Setting up your account...',
      );

      await _authManager.registerUserAndSendVerification(
        _tecRegistrationEmail.text.trim(),
        _tecRegistrationPassword.text,
      );
      return true;
    } on auth.FirebaseAuthException catch (e) {
      if (mounted) {
        _handleFirebaseException(e);
      }
      return false;
    } on Exception catch (e) {
      debugPrint('Something went really wrong for registration: $e');
      if (mounted) {
        _handleException(e, 'Registration Error!');
      }
      return false;
    }
  }

  void _handleFirebaseException(auth.FirebaseAuthException e) {
    Navigator.of(context).pop(); // Close any progress dialog

    String title = 'Authentication Error';
    String content = 'Something went wrong during authentication.';
    IconData icon = Icons.error_outline;

    switch (e.code) {
      case 'invalid-email':
        title = 'Invalid Email';
        content = 'The email address is badly formatted. Please enter a valid email address.';
        icon = Icons.email_outlined;
        break;
      case 'email-already-in-use':
        title = 'Email Already Registered';
        content = 'This email is already registered. Please try signing in instead.';
        icon = Icons.person_outline;
        break;
      case 'weak-password':
        title = 'Weak Password';
        content = 'The password is too weak. Please choose a stronger password with at least 6 characters.';
        icon = Icons.lock_outline;
        break;
      case 'user-disabled':
        title = 'Account Disabled';
        content = 'This account has been disabled. Please contact support for assistance.';
        icon = Icons.block;
        break;
      case 'user-not-found':
        title = 'Account Not Found';
        content = 'No account found with this email address. Please check your email or create a new account.';
        icon = Icons.person_search;
        break;
      case 'wrong-password':
        title = 'Incorrect Password';
        content = 'The password is incorrect. Please try again or reset your password if you\'ve forgotten it.';
        icon = Icons.lock_outline;
        break;
      case 'too-many-requests':
        title = 'Too Many Attempts';
        content = 'Too many failed attempts. Please wait a moment before trying again.';
        icon = Icons.timer;
        break;
      case 'network-request-failed':
        title = 'Connection Error';
        content = 'Unable to connect to the server. Please check your internet connection and try again.';
        icon = Icons.wifi_off;
        break;
      default:
        content = 'An unexpected error occurred. Please try again later.\n\nError: ${e.message}';
        break;
    }

    DialogManager.showAlertDialog(
      context: context,
      title: title,
      content: content,
      icon: icon,
      isError: true,
    );
  }

  void _handleException(Exception e, String title) {
    Navigator.of(context).pop(); // Close any progress dialog
    DialogManager.showAlertDialog(
      context: context,
      title: title,
      content: 'An unexpected error occurred. Please try again.\n\nError details: $e',
      icon: Icons.error_outline,
      isError: true,
    );
  }

  Future<void> _onRefreshVerificationClick() async {
    setState(() {
      _isLoading = true;
    });

    DialogManager.showProgressDialog(
      context: context,
      title: 'Checking Verification',
      subtitle: 'Please wait...',
    );

    await _authManager.hasUserVerifiedEmail().then((verified) {
      if (!verified) {
        Navigator.of(context).pop();
        DialogManager.showAlertDialog(
          context: context,
          title: 'Email Not Verified',
          content:
              'Email verification is not complete yet. Please check your inbox at ${_tecRegistrationEmail.text} and click the verification link.',
          icon: Icons.mark_email_unread_outlined,
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        _appContext.analytics.logSignUp(signUpMethod: 'email-verified');
        debugPrint('creating user with auth: ${_authManager.currentAuthUID}');
        Navigator.of(context).pop();
        _instantiateTheRest(true);
      }
    });
  }

  Future<void> _instantiateTheRest(bool fromRegistration) async {
    DialogManager.showProgressDialog(
      title: 'Welcome to CTRIM!',
      subtitle: 'Setting up your experience...',
      context: context,
    );
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
      final String platformName = kIsWeb ? 'Web' : Platform.operatingSystem;
      _appContext.sharedPref.saveFCMToken(token);
      _everyoneDBManager.addTokenForAuthID(authID: _authManager.currentAuthUID, token: token, platform: platformName);
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

// Sticky Tab Bar Delegate for persistent header
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 72.0;

  @override
  double get maxExtent => 72.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
