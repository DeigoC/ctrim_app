import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_manager.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_analytics.dart';
import 'utility/app_context.dart';
import 'utility/cache/local_data_manager.dart';
import 'utility/startup_load.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Shared preferences + theme settings before first frame so the preferred
  // ThemeMode is ready (system / light / dark) without a flash.
  final SharedPreferences prefInstance = await SharedPreferences.getInstance();
  final settingsController = SettingsController(SettingsService(prefInstance));
  await settingsController.loadSettings();

  // Initialize Hive for local caching (works on all platforms including web)
  await LocalDataManager.initialize();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  // Initialize Firebase App Check for DDoS/abuse protection.
  if (kDebugMode && kIsWeb) {
    // For web debug mode, we need to set the debug token
    // The debug token will be printed in the browser console on first run
    debugPrint(
        '🔧 Running in DEBUG mode - Firebase App Check will generate a debug token');
    debugPrint(
        '📋 Check your browser console for: "Firebase App Check debug token:"');
    debugPrint(
        '🔗 Add the token at: https://console.firebase.google.com/project/_/appcheck/apps');

    await FirebaseAppCheck.instance.activate(
      providerWeb:
          ReCaptchaV3Provider('6Lezkk8sAAAAAHFUtJ6XpEviEaxFleXpMhZhHFfh'),
    );

    // Enable auto token refresh
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } else {
    // Production mode - use reCAPTCHA verification
    await FirebaseAppCheck.instance.activate(
      providerWeb:
          ReCaptchaV3Provider('6Lezkk8sAAAAAHFUtJ6XpEviEaxFleXpMhZhHFfh'),
    );
  }

  // * Make sure we connect to the emulator on debug
  // if (kDebugMode) {
  //   try {
  //     await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //   } on Exception catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }

  final AuthManager authManager = AuthManager();
  final FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.instance;
  await firebaseAnalytics.setAnalyticsCollectionEnabled(kReleaseMode);
  final AppAnalytics analytics = AppAnalytics(
    FirebaseAnalyticsClient(firebaseAnalytics),
  );

  String? cacheDir, appDir;
  try {
    cacheDir = await getTemporaryDirectory().then((dir) => dir.path);
    appDir = await getApplicationDocumentsDirectory().then((dir) => dir.path);
  } on Exception catch (e) {
    debugPrint('-------- error getting directories: $e');
  } finally {}

  // * Always start as guest, then silently upgrade if credentials exist
  final String? email = prefInstance.getString('email'),
      pass = prefInstance.getString('password');

  // Create initial guest context and run app immediately
  final AppContext guestContext = AppContext(
      prefInstance: prefInstance,
      cacheDir: cacheDir,
      appDir: appDir,
      analytics: analytics);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: guestContext),
      ChangeNotifierProvider.value(value: settingsController),
    ],
    child: MyApp(
      settingsController: settingsController,
      loadStartup: (onProgress) async {
        // App Check on web debug needs a moment before the first Firestore read.
        if (kIsWeb && kDebugMode) {
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint('✅ App Check should be ready, starting data fetch...');
        }
        await loadEssentialAppData(
          app: guestContext,
          preferences: prefInstance,
          authManager: authManager,
          email: email,
          password: pass,
          onProgress: onProgress,
        );
      },
    ),
  ));
}
