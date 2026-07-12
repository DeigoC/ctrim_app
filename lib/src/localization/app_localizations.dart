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

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button to clear selected tag filters
  ///
  /// In en, this message translates to:
  /// **'Clear tags'**
  String get userTagsFilterClear;

  /// Section label for assigning tags to a volunteer
  ///
  /// In en, this message translates to:
  /// **'Teams & tags'**
  String get userTagsAssignLabel;

  /// Message when no user tags exist for assignment
  ///
  /// In en, this message translates to:
  /// **'No tags defined yet. Area admins can create tags in Admin Tools.'**
  String get userTagsNoneAvailable;

  /// Title for the admin page that manages volunteer tag definitions
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageUserTagsTitle;

  /// Action to create a new volunteer tag
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get manageUserTagsAdd;

  /// Empty state on the manage tags page
  ///
  /// In en, this message translates to:
  /// **'No volunteer tags yet. Create tags for teams like Worship, Technical, or Usher.'**
  String get manageUserTagsEmpty;

  /// Button to seed default volunteer tags
  ///
  /// In en, this message translates to:
  /// **'Add starter tags'**
  String get manageUserTagsSeedDefaults;

  /// Status label for an active tag
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get manageUserTagsActive;

  /// Status label for a deactivated tag
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get manageUserTagsInactive;

  /// Reorder a tag higher in the list
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get manageUserTagsMoveUp;

  /// Reorder a tag lower in the list
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get manageUserTagsMoveDown;

  /// Edit an existing tag
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get manageUserTagsEdit;

  /// Deactivate a tag so it cannot be assigned
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get manageUserTagsDeactivate;

  /// Reactivate a deactivated tag
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get manageUserTagsActivate;

  /// Delete a tag definition
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageUserTagsDelete;

  /// Label for the tag name field
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get manageUserTagsNameLabel;

  /// Label for the optional tag color hex field
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get manageUserTagsColorLabel;

  /// Create a new tag
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get manageUserTagsCreate;

  /// Confirmation before deleting a tag
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String manageUserTagsDeleteConfirm(String name);

  /// Error when trying to delete a tag that is still assigned
  ///
  /// In en, this message translates to:
  /// **'Cannot delete — {count} volunteers still have this tag. Deactivate it instead.'**
  String manageUserTagsDeleteBlocked(int count);

  /// Personal home admin menu item for managing tags
  ///
  /// In en, this message translates to:
  /// **'Volunteer Tags'**
  String get manageUserTagsMenuTitle;

  /// Personal home admin menu subtitle for managing tags
  ///
  /// In en, this message translates to:
  /// **'Create and edit team labels'**
  String get manageUserTagsMenuSubtitle;

  /// Empty state when tag filter returns no volunteers
  ///
  /// In en, this message translates to:
  /// **'No volunteers match the selected tags'**
  String get volunteersEmptyTags;

  /// Title for the multi-select volunteer picker page
  ///
  /// In en, this message translates to:
  /// **'Select members'**
  String get selectUsersTitle;

  /// Confirm button on the volunteer picker page
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selectUsersDone;

  /// Selected member count on the volunteer picker page
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectUsersSelected(int count);

  /// Button to open the volunteer picker from schedule assignment
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get selectUsersManageMembers;

  /// Title for the contributor multi-select picker page
  ///
  /// In en, this message translates to:
  /// **'Select contributors'**
  String get selectUsersContributorsTitle;

  /// Button to open the contributor picker
  ///
  /// In en, this message translates to:
  /// **'Manage contributors'**
  String get selectUsersManageContributors;

  /// Label before sort mode chips on the volunteers list
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get volunteersSortLabel;

  /// Sort volunteers by surname
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get volunteersSortSurname;

  /// Sort volunteers by primary team tag
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get volunteersSortTags;

  /// Title for the volunteers filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get volunteersFiltersTitle;

  /// Section label for location filters on the volunteers list
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get volunteersLocationFilterLabel;

  /// Button to clear all volunteer list filters
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get volunteersFiltersReset;
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
