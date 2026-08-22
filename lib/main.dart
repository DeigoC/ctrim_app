import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_manager.dart';
import 'firebase/db_managers/user_db_manager.dart';
import 'firebase/db_managers/user_location_db_manager.dart';
import 'firebase/db_managers/user_tag_db_manager.dart';
import 'firebase/db_managers/post_tag_db_manager.dart';
import 'firebase/db_managers/cell_group_db_manager.dart';
import 'firebase_options.dart';
import 'models/event/event_head.dart';
import 'models/user.dart' as ctrim;
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_context.dart';
import 'utility/event_heads_repository.dart';
import 'utility/local_data_manager.dart';
import 'utility/user_schedule_service.dart';
import 'utility/users_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

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
    ),
  ));

  // Wait a moment for App Check to fully initialize before fetching data
  if (kIsWeb && kDebugMode) {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('✅ App Check should be ready, starting data fetch...');
  }

  // Fetch essential data in background for all users (guests and authenticated)
  _fetchEssentialDataInBackground(
      guestContext, prefInstance, authManager, email, pass);
}

Future<void> _fetchEssentialDataInBackground(
  AppContext guestContext,
  SharedPreferences prefInstance,
  AuthManager authManager,
  String? email,
  String? pass,
) async {
  final eventHeadsRepository = EventHeadsRepository();
  final usersRepository = UsersRepository();

  List<EventHead> heads = <EventHead>[];
  List<ctrim.User> allUsers = <ctrim.User>[];

  // First, fetch event heads for guest users (or anyone) - this makes content visible immediately
  try {
    late final List<EventHead> fetchedHeads;
    late final UsersLoadResult usersResult;
    await Future.wait([
      eventHeadsRepository
          .fetchEventHeads()
          .then((value) => fetchedHeads = value),
      usersRepository.fetchUsersWithMeta().then((value) => usersResult = value),
    ]);
    heads = fetchedHeads;
    allUsers = usersResult.users;
    if (!usersResult.fromCache) {
      prefInstance.setBool('fetchUserImages', true);
    }

    guestContext.setAllEventHeads(heads);
    guestContext.setAllUsers(allUsers);

    await Future.wait([
      _tryLoadCatalog(
        label: 'user tags',
        fetch: () => UserTagDBManager().fetchAllTags(),
        apply: guestContext.setAllTags,
      ),
      _tryLoadCatalog(
        label: 'post tags',
        fetch: () => PostTagDBManager().fetchAllTags(),
        apply: guestContext.setAllPostTags,
      ),
      _tryLoadCatalog(
        label: 'cell groups',
        fetch: () => CellGroupDBManager().fetchAllGroups(),
        apply: guestContext.setAllCellGroups,
      ),
      _tryLoadCatalog(
        label: 'user locations',
        fetch: () => UserLocationDBManager().fetchAllLocations(),
        apply: guestContext.setAllLocations,
      ),
    ]);

    debugPrint('Successfully loaded ${heads.length} posts for guest user');
  } catch (e) {
    debugPrint('Error fetching initial data for guest: $e');
  }

  // Then try to upgrade to authenticated user if credentials exist
  if (email != null && email != '' && pass != null && pass != '') {
    debugPrint('Found stored credentials, attempting background login...');
    try {
      final authID = await authManager.loginAndReturnAuthID(email, pass);

      final UserDBManager userDBManager = UserDBManager();
      final currentUser = await userDBManager.fetchUserByAuthID(authID);

      if (currentUser != null) {
        var loadedHeads = List<EventHead>.from(heads);
        if (loadedHeads.isEmpty) {
          loadedHeads = await eventHeadsRepository.fetchEventHeads();
        }
        var loadedUsers = List<ctrim.User>.from(allUsers);
        if (loadedUsers.isEmpty) {
          loadedUsers = await usersRepository.fetchUsers();
        }

        currentUser
            .setRoles(await userDBManager.fetchUserRoles(currentUser.id));
        final scheduleService =
            UserScheduleService(userDBManager: userDBManager);
        await scheduleService.pruneStaleRoles(
          user: currentUser,
          eventHeads: loadedHeads,
        );

        loadedUsers.removeWhere((e) => e.id == currentUser.id);
        loadedUsers.add(currentUser);

        guestContext.upgradeToAuthenticatedUser(
          user: currentUser,
          heads: loadedHeads,
          allUsers: loadedUsers,
        );

        debugPrint(
            'Successfully upgraded guest to authenticated user: ${currentUser.forname}');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Background login failed: $e');
      // Stay as guest with already-loaded data
    }
  }
}

Future<void> _tryLoadCatalog<T>({
  required String label,
  required Future<List<T>> Function() fetch,
  required void Function(List<T> records) apply,
}) async {
  try {
    apply(await fetch());
  } catch (e) {
    debugPrint('Error fetching $label (deploy firestore.rules if needed): $e');
  }
}
