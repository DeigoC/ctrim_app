import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The work in progress app for the CTRIM Church
  ///
  /// In en, this message translates to:
  /// **'CTRIM App'**
  String get appTitle;

  /// Title for the volunteers directory when showing all locations
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get volunteersTitle;

  /// Title for the volunteers directory filtered by location
  ///
  /// In en, this message translates to:
  /// **'{location} Volunteers'**
  String volunteersTitleLocation(String location);

  /// Filter chip label to show volunteers from every location
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get volunteersFilterAll;

  /// Hint text for the volunteers search field
  ///
  /// In en, this message translates to:
  /// **'Search volunteers...'**
  String get volunteersSearchHint;

  /// Empty state when the volunteers list has no entries
  ///
  /// In en, this message translates to:
  /// **'No volunteers found'**
  String get volunteersEmpty;

  /// Empty state when search returns no volunteers
  ///
  /// In en, this message translates to:
  /// **'No volunteers match \"{query}\"'**
  String volunteersEmptySearch(String query);

  /// Empty state when a location filter returns no volunteers
  ///
  /// In en, this message translates to:
  /// **'No volunteers in {location}'**
  String volunteersEmptyLocation(String location);

  /// FAB label for registering a new volunteer
  ///
  /// In en, this message translates to:
  /// **'Register User'**
  String get registerUser;

  /// Personal home menu item for the volunteers directory
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get volunteersMenuTitle;

  /// Personal home menu subtitle for the volunteers directory
  ///
  /// In en, this message translates to:
  /// **'View community members'**
  String get volunteersMenuSubtitle;

  /// Personal home menu item for the current user's schedule
  ///
  /// In en, this message translates to:
  /// **'My Schedule'**
  String get mySchedule;

  /// Personal home menu subtitle for the schedule page
  ///
  /// In en, this message translates to:
  /// **'View your tasks and roles'**
  String get myScheduleSubtitle;

  /// Badge shown when a volunteer can create events
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get userProfileLeaderBadge;

  /// Badge shown when a volunteer is an area admin
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get userProfileAdminBadge;

  /// Section title on a volunteer profile for schedule preview
  ///
  /// In en, this message translates to:
  /// **'Upcoming tasks'**
  String get userProfileUpcomingTasks;

  /// Message when a volunteer has no upcoming schedule items
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks assigned.'**
  String get userProfileNoUpcomingTasks;

  /// Button to open the full schedule page
  ///
  /// In en, this message translates to:
  /// **'View full schedule'**
  String get userProfileViewFullSchedule;

  /// Button to open posts the volunteer authors or contributes to
  ///
  /// In en, this message translates to:
  /// **'View posts'**
  String get userProfileViewPosts;

  /// App bar action for admins to edit a volunteer profile
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get userProfileEditUser;

  /// Fallback event title on profile schedule preview
  ///
  /// In en, this message translates to:
  /// **'Untitled event'**
  String get userProfileUntitledEvent;

  String get cancel;
  String get save;
  String get userTagsFilterClear;
  String get userTagsAssignLabel;
  String get userTagsNoneAvailable;
  String get manageUserTagsTitle;
  String get manageUserTagsAdd;
  String get manageUserTagsEmpty;
  String get manageUserTagsSeedDefaults;
  String get manageUserTagsActive;
  String get manageUserTagsInactive;
  String get manageUserTagsMoveUp;
  String get manageUserTagsMoveDown;
  String get manageUserTagsEdit;
  String get manageUserTagsDeactivate;
  String get manageUserTagsActivate;
  String get manageUserTagsDelete;
  String get manageUserTagsNameLabel;
  String get manageUserTagsColorLabel;
  String get manageUserTagsCreate;
  String manageUserTagsDeleteConfirm(String name);
  String manageUserTagsDeleteBlocked(int count);
  String get manageUserTagsMenuTitle;
  String get manageUserTagsMenuSubtitle;
  String get volunteersEmptyTags;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
