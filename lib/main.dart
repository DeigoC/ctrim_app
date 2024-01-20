import 'dart:convert';

import 'package:ctrim_app/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'models/user.dart' as ctrim;
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_context.dart';
import 'utility/local_data_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp();
  }

  // * Make sure we connect to the emulator on debug
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

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

  // * First up, we log the returning user in, otherwise it's a guest
  final String? email = prefInstance.getString('email'), pass = prefInstance.getString('password');

  String? authID;
  ctrim.User? currentUser;

  if (email != null && email != '' && pass != null && pass != '') {
    debugPrint('email is $email and pass is $pass');
    try {
      authID =
          await authManager.loginAndReturnAuthID(prefInstance.getString('email')!, prefInstance.getString('password')!);
    } on FirebaseAuthException catch (e) {
      // means that there was no user
      debugPrint('error on attempting to sign in: $e');
    }
  }

  // user has logged in before, we fetch the data as per usual and open the app to home
  if (authID != null) {
    final UserDBManager userDBManager = UserDBManager();
    currentUser = await userDBManager.fetchUserByAuthID(authID);

    // * Then fetch the rest of the important data
    final allUsers = await _fetchAllUsers(prefInstance);
    final heads = await eventHeadDBManager.fetchEventHeads();

    // * User Related work
    // this is dumb, we need to move the local data writing logic to it's own class so
    // it can be called anywhere and remove the need to do these weird, hacky things!
    if (currentUser != null) {
      // sort out the user roles. We first figure out what roles to remove
      currentUser.setRoles(await userDBManager.fetchUserRoles(currentUser.id));
      final List<String> postsToRemove = [];
      for (final roleEntry in currentUser.roles!) {
        if (heads.any((e) => e.id == roleEntry['postID'])) {
          final thisPost = heads.firstWhere((e) => e.id == roleEntry['postID']);
          if (thisPost.eventDate!.add(const Duration(days: 1)).isBefore(DateTime.now())) {
            postsToRemove.add(thisPost.id);
          }
        } else {
          postsToRemove.add(roleEntry['postID']);
        }
      }

      // perform the removal if necessary
      if (postsToRemove.isNotEmpty) {
        debugPrint('removing the following dated roles: $postsToRemove');
        currentUser.removeRoles(postsToRemove);
        for (final postID in postsToRemove) {
          await userDBManager.removeUserPostRole(currentUser.id, postID);
        }
      }

      // after the work on user roles, finish with putting the user in with the rest
      allUsers.removeWhere((e) => e.id == currentUser!.id);
      allUsers.add(currentUser);
    }

    // * Create the AppContext, setup the FCM and run the app
    final AppContext appContext = AppContext(
        heads: heads,
        allUsers: allUsers,
        prefInstance: prefInstance,
        user: currentUser,
        analytics: analytics,
        cacheDir: cacheDir,
        appDir: appDir);
    runApp(ChangeNotifierProvider(
        create: (_) => appContext,
        child: MyApp(
          settingsController: settingsController,
          openWelcomePage: false,
        )));
  }
  // otherwise we open the welcome page! we perform the rest of the fetching at the end of that page
  else {
    final AppContext appContext =
        AppContext(prefInstance: prefInstance, cacheDir: cacheDir, appDir: appDir, analytics: analytics);
    runApp(ChangeNotifierProvider(
        create: (_) => appContext,
        child: MyApp(
          settingsController: settingsController,
          openWelcomePage: true,
        )));
  }
}

Future<List<ctrim.User>> _fetchAllUsers(final SharedPreferences pref) async {
  final IDTrackerDBManager trackerDBManager = IDTrackerDBManager();
  final LocalDataManager dataManager = LocalDataManager();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final String version = packageInfo.version;
  const LineSplitter ls = LineSplitter();
  debugPrint('version is $version');

  final String currentID = await trackerDBManager.getCurrentUserID();
  final List<String> usersData = kIsWeb ? ls.convert(pref.getString('usersData') ?? '') : await dataManager.readUsers();
  final DateTime? lastWebUserFetch = pref.getString('lastUserFetch') == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(int.parse(pref.getString('lastUserFetch')!));

  final lastUserFetch = kIsWeb ? lastWebUserFetch : await dataManager.readLastUserFetch();
  final bool lastFetchWasNotAWhileAgo = lastUserFetch != null && DateTime.now().difference(lastUserFetch).inDays <= 7;

  // only use the local data if the count is the same in the DB and the last time has been multiple days ago (7 days)
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
    const int chunkSize = 8;
    final int numberOfChunks = usersData.length ~/ chunkSize;

    final List<List<String>> allUserEntries = List<List<String>>.generate(numberOfChunks, (index) {
      int startIndex = index * chunkSize;
      int endIndex = (index + 1) * chunkSize;
      return usersData.sublist(startIndex, endIndex);
    });

    final List<ctrim.User> result = List<ctrim.User>.empty(growable: true);
    for (final userEntry in allUserEntries) {
      final thisUser = ctrim.User(
          id: userEntry[0],
          forname: userEntry[1],
          surname: userEntry[2],
          imgSrc: userEntry[3],
          isLeader: userEntry[4] == '1',
          isAreaAdmin: userEntry[5] == '1',
          location: userEntry[6],
          authID: userEntry[7]);
      result.add(thisUser);
    }

    return result;
  } else {
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
    }

    debugPrint('--writing users from DB');
    // this write thing should be updated when we register users
    if (kIsWeb) {
      pref.setString('usersData', allUsersContent);
      pref.setString('lastUserFetch', DateTime.now().millisecondsSinceEpoch.toString());
    } else {
      await dataManager.writeUsersList(allUsersContent);
      await dataManager.writeLastUsersFetch();
    }

    pref.setBool('fetchUserImages', true); // refresh user image fetch
    return allUsers;
  }
}
