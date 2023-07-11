import 'package:ctrim_app/utility/app_context.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/db_managers/event_db_manager.dart';
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
  final EventHeadDBManager eventHeadDBManager = EventHeadDBManager(); // should this be here?
  final heads = await eventHeadDBManager.fetchEventHeads();

  // * We will have all the loading logic take place here
  runApp(ChangeNotifierProvider(
      create: (_) => AppContext(heads: heads), child: MyApp(settingsController: settingsController)));
}
