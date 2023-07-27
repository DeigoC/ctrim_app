import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/auth_manager.dart';
import 'firebase/db_managers/event_db_manager.dart';
import 'firebase/db_managers/user_contact_db_manager.dart';
import 'firebase/db_managers/user_db_manager.dart';
import 'models/user.dart' as ctrim;
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'utility/app_context.dart';
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
      // ! Remember to change the line in "functions_manager.dart" !
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // * First up, we log the returning user in, otherwise it's a guest
  final SharedPreferences prefInstance = await SharedPreferences.getInstance();
  final AuthManager authManager = AuthManager();

  final String? email = prefInstance.getString('email'), pass = prefInstance.getString('password');
  String? uAuth;
  if (email != null && email != '' && pass != null && pass != '') {
    debugPrint('email is $email and pass is $pass');
    uAuth =
        await authManager.loginAndReturnAuthID(prefInstance.getString('email')!, prefInstance.getString('password')!);
  }

  final UserContactDBManager userContactDBManager = UserContactDBManager();
  final UserDBManager userDBManager = UserDBManager();
  ctrim.User user = ctrim.User(id: '0', forname: 'Guest', surname: 'Account');
  if (uAuth != null) {
    final uContact = await userContactDBManager.fetchUserContactByAuthID(uAuth);
    user = await userDBManager.fetchUserByID(uContact.id);
  }

  // * Then fetch the rest of the important data
  final EventHeadDBManager eventHeadDBManager = EventHeadDBManager(); // should this be here?
  final heads = await eventHeadDBManager.fetchEventHeads();
  final allUsers = await userDBManager.fetchAllUsers();

  // * Create the AppContext and run the app
  runApp(ChangeNotifierProvider(
      create: (_) => AppContext(heads: heads, allUsers: allUsers, prefInstance: prefInstance, user: user),
      child: MyApp(settingsController: settingsController)));
}
