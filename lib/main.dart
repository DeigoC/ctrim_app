import 'package:ctrim_app/firebase/auth_manager.dart';
import 'package:ctrim_app/firebase/db_managers/user_contact_db_manager.dart';
import 'package:ctrim_app/firebase/db_managers/user_db_manager.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/db_managers/event_db_manager.dart';
import 'models/user.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

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

  // * First up, we log the returning user in
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
  User user = User(id: '0', forname: 'Guest', surname: 'Account');
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
