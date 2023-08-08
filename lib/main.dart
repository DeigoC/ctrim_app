import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_manager.dart';
import 'firebase/db_managers/event_db_manager.dart';
import 'firebase/db_managers/id_tracker.dart';
import 'firebase/db_managers/user_contact_db_manager.dart';
import 'firebase/db_managers/user_db_manager.dart';
import 'models/user.dart' as ctrim;
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_context.dart';
import 'utility/local_data_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  await Firebase.initializeApp();

  // * Make sure we connect to the emulator on debug
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  final SharedPreferences prefInstance = await SharedPreferences.getInstance();
  final AuthManager authManager = AuthManager();
  final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();

  // * First up, we log the returning user in, otherwise it's a guest
  final String? email = prefInstance.getString('email'), pass = prefInstance.getString('password');
  String? uAuth;
  if (email != null && email != '' && pass != null && pass != '') {
    debugPrint('email is $email and pass is $pass');
    uAuth =
        await authManager.loginAndReturnAuthID(prefInstance.getString('email')!, prefInstance.getString('password')!);
  }

  final allUsers = await _fetchAllUsers(prefInstance);
  ctrim.User currentUser = ctrim.User(id: '0', forname: 'Guest', surname: 'Account');

  if (uAuth != null) {
    final UserContactDBManager userContactDBManager = UserContactDBManager();
    final uContact = await userContactDBManager.fetchUserContactByAuthID(uAuth);
    currentUser = allUsers.firstWhere((u) => u.id.compareTo(uContact.id) == 0);
  }

  // * Then fetch the rest of the important data
  final heads = await eventHeadDBManager.fetchEventHeads();
  final cacheDir = await getTemporaryDirectory().then((dir) => dir.path);
  final appDir = await getApplicationDocumentsDirectory().then((dir) => dir.path);

  // * Create the AppContext, setup the FCM and run the app
  final AppContext appContext = AppContext(
      heads: heads,
      allUsers: allUsers,
      prefInstance: prefInstance,
      user: currentUser,
      cacheDir: cacheDir,
      appDir: appDir);
  runApp(ChangeNotifierProvider(create: (_) => appContext, child: MyApp(settingsController: settingsController)));
}

Future<List<ctrim.User>> _fetchAllUsers(SharedPreferences pref) async {
  final IDTrackerDBManager trackerDBManager = IDTrackerDBManager();
  final LocalDataManager dataManager = LocalDataManager();

  final String currentID = await trackerDBManager.getCurrentUserID();
  final usersData = await dataManager.readUsers();
  final lastUserFetch = await dataManager.readLastUserFetch();
  final bool lastFetchWasNotAWhileAgo = lastUserFetch != null && DateTime.now().difference(lastUserFetch).inDays <= 7;

  // only use the local data if the count is the same in the DB and the last time has been multiple days ago (7 days)
  // TODO also make sure that the saved version of the app matches the current one
  final bool shouldReadLocalData = usersData.isNotEmpty && usersData[0] == currentID && lastFetchWasNotAWhileAgo;

  if (shouldReadLocalData) {
    debugPrint('--fetching users from Local Data');

    usersData.removeAt(0); // remove the first line that tells the current ID
    const int chunkSize = 7;
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
          location: userEntry[6]);
      result.add(thisUser);
    }

    return result;
  } else {
    debugPrint('--fetching users from DB');
    final UserDBManager userDBManager = UserDBManager();
    final allUsers = await userDBManager.fetchAllUsers();

    String allUsersContent = currentID; // start with the current count / uID
    for (final user in allUsers) {
      allUsersContent += '\n${user.id}';
      allUsersContent += '\n${user.forname}';
      allUsersContent += '\n${user.surname}';
      allUsersContent += '\n${user.imgSrc}';
      allUsersContent += '\n${user.isLeader ? '1' : '0'}';
      allUsersContent += '\n${user.isAreaAdmin ? '1' : '0'}';
      allUsersContent += '\n${user.location}';
    }

    debugPrint('--writing users from DB');
    // this write thing should be updated when we register users
    await dataManager.writeUsersList(allUsersContent);
    await dataManager.writeLastUsersFetch();
    pref.setBool('FetchUserImages', true); // refresh user image fetch

    return allUsers;
  }
}
