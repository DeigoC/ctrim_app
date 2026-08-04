import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_manager.dart';
import 'firebase/db_managers/event_db_manager.dart';
import 'firebase/db_managers/id_tracker.dart';
import 'firebase/db_managers/user_db_manager.dart';
import 'firebase/db_managers/user_location_db_manager.dart';
import 'firebase/db_managers/user_tag_db_manager.dart';
import 'firebase/db_managers/post_tag_db_manager.dart';
import 'firebase/db_managers/cell_group_db_manager.dart';
import 'firebase_options.dart';
import 'models/user.dart' as ctrim;
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_context.dart';
import 'utility/local_data_manager.dart';
import 'utility/user_schedule_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching (works on all platforms including web)
  await LocalDataManager.initialize();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Initialize Firebase App Check for DDoS/abuse protection.
  if (kDebugMode && kIsWeb) {
    // For web debug mode, we need to set the debug token
    // The debug token will be printed in the browser console on first run
    debugPrint('🔧 Running in DEBUG mode - Firebase App Check will generate a debug token');
    debugPrint('📋 Check your browser console for: "Firebase App Check debug token:"');
    debugPrint('🔗 Add the token at: https://console.firebase.google.com/project/_/appcheck/apps');

    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider('6Lezkk8sAAAAAHFUtJ6XpEviEaxFleXpMhZhHFfh'),
    );

    // Enable auto token refresh
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } else {
    // Production mode - use reCAPTCHA verification
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider('6Lezkk8sAAAAAHFUtJ6XpEviEaxFleXpMhZhHFfh'),
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

  final SharedPreferences prefInstance = await SharedPreferences.getInstance();
  final AuthManager authManager = AuthManager();
  final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  String? cacheDir, appDir;
  try {
    cacheDir = await getTemporaryDirectory().then((dir) => dir.path);
    appDir = await getApplicationDocumentsDirectory().then((dir) => dir.path);
  } on Exception catch (e) {
    debugPrint('-------- error getting directories: $e');
  } finally {}

  // * Always start as guest, then silently upgrade if credentials exist
  final String? email = prefInstance.getString('email'), pass = prefInstance.getString('password');

  // Create initial guest context and run app immediately
  final AppContext guestContext =
      AppContext(prefInstance: prefInstance, cacheDir: cacheDir, appDir: appDir, analytics: analytics);

  runApp(ChangeNotifierProvider(
      create: (_) => guestContext,
      child: MyApp(
        settingsController: settingsController,
      )));

  // Wait a moment for App Check to fully initialize before fetching data
  if (kIsWeb && kDebugMode) {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('✅ App Check should be ready, starting data fetch...');
  }

  // Fetch essential data in background for all users (guests and authenticated)
  _fetchEssentialDataInBackground(guestContext, prefInstance, authManager, eventHeadDBManager, email, pass);
}

Future<void> _fetchEssentialDataInBackground(
  AppContext guestContext,
  SharedPreferences prefInstance,
  AuthManager authManager,
  EventHeadDBManager eventHeadDBManager,
  String? email,
  String? pass,
) async {
  // First, fetch event heads for guest users (or anyone) - this makes content visible immediately
  try {
    final heads = await eventHeadDBManager.fetchEventHeads();
    final allUsers = await _fetchAllUsers(prefInstance);

    guestContext.addAllEventHeads(heads);
    guestContext.allUsers.addAll(allUsers);

    try {
      final allTags = await UserTagDBManager().fetchAllTags();
      guestContext.setAllTags(allTags);
    } catch (e) {
      debugPrint('Error fetching user tags (deploy firestore.rules if needed): $e');
    }
    try {
      final allPostTags = await PostTagDBManager().fetchAllTags();
      guestContext.setAllPostTags(allPostTags);
    } catch (e) {
      debugPrint('Error fetching post tags (deploy firestore.rules if needed): $e');
    }
    try {
      final allCellGroups = await CellGroupDBManager().fetchAllGroups();
      guestContext.setAllCellGroups(allCellGroups);
    } catch (e) {
      debugPrint('Error fetching cell groups (deploy firestore.rules if needed): $e');
    }
    try {
      final allLocations = await UserLocationDBManager().fetchAllLocations();
      guestContext.setAllLocations(allLocations);
    } catch (e) {
      debugPrint('Error fetching user locations (deploy firestore.rules if needed): $e');
    }
    guestContext.sortPostsByIndex();
    guestContext.rebuildPlease();

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
        // Fetch fresh data for authenticated user
        final allUsers = await _fetchAllUsers(prefInstance);
        final heads = await eventHeadDBManager.fetchEventHeads();

        // User roles cleanup
        currentUser.setRoles(await userDBManager.fetchUserRoles(currentUser.id));
        final scheduleService = UserScheduleService(userDBManager: userDBManager);
        await scheduleService.pruneStaleRoles(user: currentUser, eventHeads: heads);

        // Add current user to all users list
        allUsers.removeWhere((e) => e.id == currentUser.id);
        allUsers.add(currentUser);

        // Update the context with authenticated user data (this will refresh the UI with user-specific data)
        guestContext.upgradeToAuthenticatedUser(
          user: currentUser,
          heads: heads,
          allUsers: allUsers,
        );

        debugPrint('Successfully upgraded guest to authenticated user: ${currentUser.forname}');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Background login failed: $e');
      // Stay as guest with already-loaded data
    }
  }
}

Future<List<ctrim.User>> _fetchAllUsers(final SharedPreferences pref) async {
  final IDTrackerDBManager trackerDBManager = IDTrackerDBManager();
  final LocalDataManager dataManager = LocalDataManager();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final String version = packageInfo.version;
  debugPrint('version is $version');

  final String currentID = await trackerDBManager.getCurrentUserID();
  final List<String> usersData = await dataManager.readUsers();
  final DateTime? lastUserFetch = await dataManager.readLastUserFetch();
  final bool lastFetchWasNotAWhileAgo = lastUserFetch != null && DateTime.now().difference(lastUserFetch).inDays <= 21;

  // only use the local data if the count is the same in the DB and the last time has been multiple days ago (21 days)
  bool shouldReadLocalData = false;
  if (usersData.isNotEmpty) {
    // from now on we check that the version is the same as before
    final firstLine = usersData[0].split('-');
    if (firstLine.length == 2) {
      shouldReadLocalData = firstLine[0] == currentID && firstLine[1] == version && lastFetchWasNotAWhileAgo;
    }
  }

  if (shouldReadLocalData) {
    debugPrint('--fetching users from Local Data');

    usersData.removeAt(0);
    const int oldChunkSize = 8;
    const int newChunkSize = 9;
    final int dataLength = usersData.length;
    int chunkSize = newChunkSize;
    if (dataLength % newChunkSize == 0) {
      chunkSize = newChunkSize;
    } else if (dataLength % oldChunkSize == 0) {
      chunkSize = oldChunkSize;
    } else {
      debugPrint('--local user cache format mismatch, refetching from DB');
      shouldReadLocalData = false;
    }

    if (shouldReadLocalData) {
      final int numberOfChunks = dataLength ~/ chunkSize;

      final List<List<String>> allUserEntries = List<List<String>>.generate(numberOfChunks, (index) {
        int startIndex = index * chunkSize;
        int endIndex = (index + 1) * chunkSize;
        return usersData.sublist(startIndex, endIndex);
      });

      final List<ctrim.User> result = List<ctrim.User>.empty(growable: true);
      for (final userEntry in allUserEntries) {
        final tagIDs = chunkSize == newChunkSize && userEntry.length > 8
            ? userEntry[8].split(',').where((e) => e.isNotEmpty).toList()
            : <String>[];
        final thisUser = ctrim.User(
            id: userEntry[0],
            forname: userEntry[1],
            surname: userEntry[2],
            imgSrc: userEntry[3],
            isLeader: userEntry[4] == '1',
            isAreaAdmin: userEntry[5] == '1',
            location: userEntry[6],
            authID: userEntry[7],
            tagIDs: tagIDs);
        result.add(thisUser);
      }

      return result;
    }
  }

  debugPrint('--fetching users from DB');
    final UserDBManager userDBManager = UserDBManager();
    final allUsers = await userDBManager.fetchAllUsers();

    String allUsersContent = '$currentID-$version'; // start with the current count / uID
    for (final user in allUsers) {
      allUsersContent += '\n${user.id}';
      allUsersContent += '\n${user.forname}';
      allUsersContent += '\n${user.surname}';
      allUsersContent += '\n${user.imgSrc}';
      allUsersContent += '\n${user.isLeader ? '1' : '0'}';
      allUsersContent += '\n${user.isAreaAdmin ? '1' : '0'}';
      allUsersContent += '\n${user.location}';
      allUsersContent += '\n${user.authID}';
      allUsersContent += '\n${user.tagIDs.join(',')}';
    }

    debugPrint('--writing users from DB');
    // this write thing should be updated when we register users
    await dataManager.writeUsersList(allUsersContent);
    await dataManager.writeLastUsersFetch();

    pref.setBool('fetchUserImages', true); // refresh user image fetch
    return allUsers;
}
