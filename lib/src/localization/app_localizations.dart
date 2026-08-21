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

  /// Badge shown when a volunteer leads an active or paused cell group
  ///
  /// In en, this message translates to:
  /// **'CG Leader'**
  String get userProfileCellGroupLeaderBadge;

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

  /// Section title for the last few volunteer activity records
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get userProfileRecentActivity;

  /// Empty state when a volunteer has no recorded activity
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get userProfileNoRecentActivity;

  /// Area-admin button to open the full activity paper trail
  ///
  /// In en, this message translates to:
  /// **'View all activity'**
  String get userProfileViewAllActivity;

  /// App bar title for the full volunteer activity log
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get userActivityPageTitle;

  /// Access denied copy on the full activity page
  ///
  /// In en, this message translates to:
  /// **'Only area admins can view the full activity log.'**
  String get userActivityDenied;

  /// Subtitle showing the Firestore document ID for paper trailing
  ///
  /// In en, this message translates to:
  /// **'Record {id}'**
  String userActivityDocumentId(String id);

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

  /// Button to clear selected post tag filters on the bulletin
  ///
  /// In en, this message translates to:
  /// **'Clear tags'**
  String get postTagsFilterClear;

  /// Section label for assigning content tags to a post or template
  ///
  /// In en, this message translates to:
  /// **'Content tags'**
  String get postTagsAssignLabel;

  /// Message when no post tags exist for assignment
  ///
  /// In en, this message translates to:
  /// **'No post tags yet. Area admins can create tags in Admin Tools.'**
  String get postTagsNoneAvailable;

  /// Summary when a post has no content tags assigned
  ///
  /// In en, this message translates to:
  /// **'No tags selected'**
  String get postTagsNoneSelected;

  /// Opens the searchable post tag picker
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get postTagsManage;

  /// Title for the full-screen post tag picker
  ///
  /// In en, this message translates to:
  /// **'Select content tags'**
  String get postTagsSelectTitle;

  /// Search hint on the post tag picker
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get postTagsSearchHint;

  /// Filter chip to show only post tags that drive push streams
  ///
  /// In en, this message translates to:
  /// **'Notification streams'**
  String get postTagsNotifiableFilter;

  /// Title for the admin page that manages post content tag definitions
  ///
  /// In en, this message translates to:
  /// **'Manage Post Tags'**
  String get managePostTagsTitle;

  /// Action to create a new post content tag
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get managePostTagsAdd;

  /// Empty state on the manage post tags page
  ///
  /// In en, this message translates to:
  /// **'No post tags yet. Create tags like Sunday Worship or Youth for bulletin filtering and optional notifications.'**
  String get managePostTagsEmpty;

  /// Button to seed default post tags with Belfast stream kinds
  ///
  /// In en, this message translates to:
  /// **'Add starter tags'**
  String get managePostTagsSeedDefaults;

  /// Status label for an active post tag
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get managePostTagsActive;

  /// Status label for a deactivated post tag
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get managePostTagsInactive;

  /// Reorder a post tag higher in the list
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get managePostTagsMoveUp;

  /// Reorder a post tag lower in the list
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get managePostTagsMoveDown;

  /// Edit an existing post tag
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get managePostTagsEdit;

  /// Deactivate a post tag so it cannot be assigned
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get managePostTagsDeactivate;

  /// Reactivate a deactivated post tag
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get managePostTagsActivate;

  /// Delete a post tag definition
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get managePostTagsDelete;

  /// Label for the post tag name field
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get managePostTagsNameLabel;

  /// Label for the optional post tag color hex field
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get managePostTagsColorLabel;

  /// Label for optional FCM stream kind on a post tag
  ///
  /// In en, this message translates to:
  /// **'Notify stream kind (optional)'**
  String get managePostTagsStreamKindLabel;

  /// Helper text explaining location + stream kind FCM topic derivation
  ///
  /// In en, this message translates to:
  /// **'Combined with post location, e.g. sunday-service → belfast-sunday-service'**
  String get managePostTagsStreamKindHelper;

  /// Shows the stream kind on a post tag list tile
  ///
  /// In en, this message translates to:
  /// **'Notifies: {kind}'**
  String managePostTagsStreamKindHint(String kind);

  /// Shown when a post tag has no stream kind
  ///
  /// In en, this message translates to:
  /// **'Filter only (no notifications)'**
  String get managePostTagsNoStream;

  /// Create a new post tag
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get managePostTagsCreate;

  /// Confirmation before deleting a post tag
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String managePostTagsDeleteConfirm(String name);

  /// Error when trying to delete a post tag that is still assigned
  ///
  /// In en, this message translates to:
  /// **'Cannot delete — {count} posts still have this tag. Deactivate it instead.'**
  String managePostTagsDeleteBlocked(int count);

  /// Personal home admin menu item for managing post tags
  ///
  /// In en, this message translates to:
  /// **'Post Tags'**
  String get managePostTagsMenuTitle;

  /// Personal home admin menu subtitle for managing post tags
  ///
  /// In en, this message translates to:
  /// **'Labels for bulletin filtering & notify streams'**
  String get managePostTagsMenuSubtitle;

  /// Title for the admin page that manages volunteer location definitions
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get manageUserLocationsTitle;

  /// Action to create a new volunteer location
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get manageUserLocationsAdd;

  /// Empty state on the manage locations page
  ///
  /// In en, this message translates to:
  /// **'No locations yet. Add places like Belfast, Portadown, or North Coast.'**
  String get manageUserLocationsEmpty;

  /// Button to seed default volunteer locations
  ///
  /// In en, this message translates to:
  /// **'Add starter locations'**
  String get manageUserLocationsSeedDefaults;

  /// Status label for an active location
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get manageUserLocationsActive;

  /// Status label for a deactivated location
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get manageUserLocationsInactive;

  /// Reorder a location higher in the list
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get manageUserLocationsMoveUp;

  /// Reorder a location lower in the list
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get manageUserLocationsMoveDown;

  /// Edit an existing location
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get manageUserLocationsEdit;

  /// Deactivate a location so it cannot be assigned
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get manageUserLocationsDeactivate;

  /// Reactivate a deactivated location
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get manageUserLocationsActivate;

  /// Delete a location definition
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageUserLocationsDelete;

  /// Label for the location name field
  ///
  /// In en, this message translates to:
  /// **'Location name'**
  String get manageUserLocationsNameLabel;

  /// Create a new location
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get manageUserLocationsCreate;

  /// Confirmation before deleting a location
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String manageUserLocationsDeleteConfirm(String name);

  /// Error when trying to delete a location that is still assigned
  ///
  /// In en, this message translates to:
  /// **'Cannot delete — {count} volunteers still have this location. Deactivate it instead.'**
  String manageUserLocationsDeleteBlocked(int count);

  /// Error when creating or renaming to a duplicate location name
  ///
  /// In en, this message translates to:
  /// **'A location named \"{name}\" already exists.'**
  String manageUserLocationsDuplicate(String name);

  /// Personal home admin menu item for managing locations
  ///
  /// In en, this message translates to:
  /// **'Volunteer Locations'**
  String get manageUserLocationsMenuTitle;

  /// Personal home admin menu subtitle for managing locations
  ///
  /// In en, this message translates to:
  /// **'Create and edit place labels'**
  String get manageUserLocationsMenuSubtitle;

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

  /// Selected count on a catalog tag/group picker page
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectCatalogSelected(int count);

  /// Empty state when catalog picker filters hide every item
  ///
  /// In en, this message translates to:
  /// **'No matches for your search or filters.'**
  String get selectCatalogNoResults;

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

  /// Button offered when picker search finds no matching volunteer
  ///
  /// In en, this message translates to:
  /// **'Create placeholder'**
  String get selectUsersCreatePlaceholder;

  /// Dialog title for creating a placeholder volunteer profile
  ///
  /// In en, this message translates to:
  /// **'Create placeholder'**
  String get selectUsersCreatePlaceholderTitle;

  /// Explains placeholder create from the user picker
  ///
  /// In en, this message translates to:
  /// **'Create a temporary profile with no login. You can link their account later after they register.'**
  String get selectUsersCreatePlaceholderBody;

  /// Forename field label in placeholder create dialog
  ///
  /// In en, this message translates to:
  /// **'Forename'**
  String get selectUsersForename;

  /// Surname field label in placeholder create dialog
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get selectUsersSurname;

  /// Confirm create placeholder in picker dialog
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get selectUsersCreate;

  /// Validation when placeholder create names are blank
  ///
  /// In en, this message translates to:
  /// **'Enter both forename and surname'**
  String get selectUsersNameRequired;

  /// Progress dialog title while creating a placeholder user
  ///
  /// In en, this message translates to:
  /// **'Creating placeholder'**
  String get selectUsersCreatingPlaceholder;

  /// Progress dialog subtitle while creating a placeholder user
  ///
  /// In en, this message translates to:
  /// **'Saving profile…'**
  String get selectUsersCreatingPlaceholderSubtitle;

  /// Error title when placeholder create fails
  ///
  /// In en, this message translates to:
  /// **'Could not create placeholder'**
  String get selectUsersCreatePlaceholderFailed;

  /// SnackBar after successful placeholder create from picker
  ///
  /// In en, this message translates to:
  /// **'Placeholder created and selected'**
  String get selectUsersPlaceholderCreated;

  /// Subtitle for placeholder users in the picker list
  ///
  /// In en, this message translates to:
  /// **'Placeholder · {location}'**
  String selectUsersPlaceholderSubtitle(String location);

  /// Filter chip to show only placeholder profiles in the Volunteers list
  ///
  /// In en, this message translates to:
  /// **'Placeholders'**
  String get volunteersShowPlaceholders;

  /// Empty state when the placeholders filter returns no volunteers
  ///
  /// In en, this message translates to:
  /// **'No placeholder profiles to show'**
  String get volunteersEmptyPlaceholders;

  /// Badge on placeholder volunteer cards
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get volunteersPlaceholderBadge;

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

  /// Filter chip to show volunteers with the Leader permission
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get volunteersFilterLeaders;

  /// Filter chip to show volunteers who are area admins
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get volunteersFilterAdmins;

  /// Filter chip to show volunteers who lead a cell group
  ///
  /// In en, this message translates to:
  /// **'CG Leaders'**
  String get volunteersFilterCellGroupLeaders;

  /// Empty state when a role filter returns no volunteers
  ///
  /// In en, this message translates to:
  /// **'No volunteers match the selected roles'**
  String get volunteersEmptyRoles;

  /// Button that opens the volunteer tag filter sheet
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get volunteersFilterTags;

  /// Tag filter button when one or more tags are selected
  ///
  /// In en, this message translates to:
  /// **'Tags ({count})'**
  String volunteersFilterTagsCount(int count);

  /// Title for the volunteer tag filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter by tags'**
  String get volunteersFilterTagsSheetTitle;

  /// Subtitle for the volunteer tag filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Show people with any of these team tags'**
  String get volunteersFilterTagsSheetSubtitle;

  /// Tooltip for the volunteers sort menu in the app bar
  ///
  /// In en, this message translates to:
  /// **'Sort volunteers'**
  String get volunteersSortTooltip;

  /// Section label for linking a post or template to cell groups
  ///
  /// In en, this message translates to:
  /// **'Cell groups'**
  String get cellGroupsAssignLabel;

  /// Hint under the cell group picker on post edit
  ///
  /// In en, this message translates to:
  /// **'Link this meeting to one or more cell groups (joint sessions allowed)'**
  String get cellGroupsAssignHint;

  /// Empty state when no cell groups exist for assignment
  ///
  /// In en, this message translates to:
  /// **'No active cell groups yet. Area admins can create them in the Cell Groups section.'**
  String get cellGroupsNoneAvailable;

  /// Summary when a post is not linked to any cell groups
  ///
  /// In en, this message translates to:
  /// **'No cell groups selected'**
  String get cellGroupsNoneSelected;

  /// Opens the searchable cell group picker
  ///
  /// In en, this message translates to:
  /// **'Manage cell groups'**
  String get cellGroupsManage;

  /// Title for the full-screen cell group picker
  ///
  /// In en, this message translates to:
  /// **'Select cell groups'**
  String get cellGroupsSelectTitle;

  /// Search hint on the cell group picker
  ///
  /// In en, this message translates to:
  /// **'Search cell groups...'**
  String get cellGroupsSearchHint;

  /// Main nav / home title for the Cell Groups section
  ///
  /// In en, this message translates to:
  /// **'Cell Groups'**
  String get cellGroupsSectionTitle;

  /// Cell Groups section tab: teaching / overview content
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get cellGroupsTabOverview;

  /// Cell Groups section tab: catalogue list of groups
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get cellGroupsTabGroups;

  /// Headline on the Cell Groups overview tab
  ///
  /// In en, this message translates to:
  /// **'Life in small groups'**
  String get cellGroupsOverviewHeadline;

  /// Short intro blurb on the Cell Groups overview tab
  ///
  /// In en, this message translates to:
  /// **'Cell groups are small gatherings that meet regularly outside the main service — focused on Bible study, care, prayer, and discipleship, usually in homes and led by trained members.'**
  String get cellGroupsOverviewIntro;

  /// Title above the verse card on CG overview
  ///
  /// In en, this message translates to:
  /// **'Scripture'**
  String get cellGroupsOverviewVerseTitle;

  /// Placeholder Bible reference for CG overview
  ///
  /// In en, this message translates to:
  /// **'[Verse reference placeholder]'**
  String get cellGroupsOverviewVerseReference;

  /// Placeholder verse body for CG overview
  ///
  /// In en, this message translates to:
  /// **'\"[Verse text placeholder — replace with the passage that underpins cell group life.]\"'**
  String get cellGroupsOverviewVerseBody;

  /// Placeholder label where overview hero image will go
  ///
  /// In en, this message translates to:
  /// **'Image coming soon'**
  String get cellGroupsOverviewImagePlaceholder;

  /// Title for the Cell Groups overview activity dashboard
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get cellGroupsActivityTitle;

  /// Subtitle under the activity dashboard title
  ///
  /// In en, this message translates to:
  /// **'Meetings linked to cell groups'**
  String get cellGroupsActivitySubtitle;

  /// Primary metric: CG meetings in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'Recent meetings'**
  String get cellGroupsActivityPastMeetings;

  /// Hint under the past meetings count
  ///
  /// In en, this message translates to:
  /// **'Past 3 weeks'**
  String get cellGroupsActivityPastMeetingsHint;

  /// Primary metric: sum of attendees for past-window CG meetings
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get cellGroupsActivityPastAttendees;

  /// Hint under the past attendees total
  ///
  /// In en, this message translates to:
  /// **'Checked in · past 3 weeks'**
  String get cellGroupsActivityPastAttendeesHint;

  /// Primary metric: CG meetings in the coming week including today
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get cellGroupsActivityUpcoming;

  /// Hint under the upcoming meetings count
  ///
  /// In en, this message translates to:
  /// **'Today + next 6 days'**
  String get cellGroupsActivityUpcomingHint;

  /// Secondary metric label for active cell group count
  ///
  /// In en, this message translates to:
  /// **'Active groups'**
  String get cellGroupsActivityActiveGroupsLabel;

  /// Secondary metric label for total MemberCount across active groups
  ///
  /// In en, this message translates to:
  /// **'Members in active groups'**
  String get cellGroupsActivityTotalMembersLabel;

  /// Secondary metric label for distinct groups with a past-window meeting
  ///
  /// In en, this message translates to:
  /// **'Groups that met · past 3 weeks'**
  String get cellGroupsActivityGroupsMetLabel;

  /// Secondary metric label for average attendees per past meeting
  ///
  /// In en, this message translates to:
  /// **'Avg attendance · past 3 weeks'**
  String get cellGroupsActivityAvgAttendanceLabel;

  /// Secondary metric label shown when some groups are paused
  ///
  /// In en, this message translates to:
  /// **'Paused groups'**
  String get cellGroupsActivityPausedGroupsLabel;

  /// Error message when activity stats fail to load
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load activity right now.'**
  String get cellGroupsActivityLoadError;

  /// Retry button for activity stats load failure
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cellGroupsActivityRetry;

  /// Empty state on the Cell Groups list
  ///
  /// In en, this message translates to:
  /// **'No cell groups yet.'**
  String get cellGroupsEmpty;

  /// FAB / action to create a cell group (area admin)
  ///
  /// In en, this message translates to:
  /// **'New cell group'**
  String get cellGroupsCreate;

  /// Action to edit a cell group profile
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get cellGroupsEdit;

  /// Action to manage cell group members (UI: Cell Members, not Roster)
  ///
  /// In en, this message translates to:
  /// **'Manage cell members'**
  String get cellGroupsManageRoster;

  /// Section title for linked bulletin posts on CG detail
  ///
  /// In en, this message translates to:
  /// **'Recent meetings'**
  String get cellGroupsMeetingTrail;

  /// Empty state for CG meeting trail
  ///
  /// In en, this message translates to:
  /// **'No linked meeting posts yet.'**
  String get cellGroupsMeetingTrailEmpty;

  /// Member count shown to signed-in users
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String cellGroupsMemberCount(int count);

  /// Label for leaders list on CG detail
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get cellGroupsLeadersLabel;

  /// Section title for CG members on detail (UI label; code/Firestore may still say roster)
  ///
  /// In en, this message translates to:
  /// **'Cell Members'**
  String get cellGroupsRosterTitle;

  /// Button to open user picker for roster
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get cellGroupsAddMembers;

  /// Hint under Add members: use picker / Create placeholder
  ///
  /// In en, this message translates to:
  /// **'Search for someone, or create a temporary profile if they are not listed.'**
  String get cellGroupsRosterAddHint;

  /// Cell group status: active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get cellGroupsStatusActive;

  /// Cell group status: paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get cellGroupsStatusPaused;

  /// Cell group status: archived
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get cellGroupsStatusArchived;

  /// Hint on CG detail for guests
  ///
  /// In en, this message translates to:
  /// **'Sign in to see more details about this group.'**
  String get cellGroupsGuestSignInHint;

  /// Section title for CG summary / cadence on detail
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get cellGroupsAboutTitle;

  /// Section title for cell group photo gallery
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get cellGroupsPhotosTitle;

  /// Helper under Photos on edit cell group
  ///
  /// In en, this message translates to:
  /// **'Add a wide group photo as the cover for the detail page. Catalogue tiles still show the first leader’s portrait.'**
  String get cellGroupsPhotosHint;

  /// Empty state when editing CG photos
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get cellGroupsPhotosEmpty;

  /// Button to add a cell group photo
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get cellGroupsAddPhoto;

  /// Badge / label for the key graphic on a cell group
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cellGroupsCoverPhoto;

  /// Hint on a non-cover photo in CG edit
  ///
  /// In en, this message translates to:
  /// **'Tap to set as cover'**
  String get cellGroupsSetAsCover;

  /// SnackBar when a video is added to a cell group
  ///
  /// In en, this message translates to:
  /// **'Cell groups only support images for now.'**
  String get cellGroupsPhotosImagesOnly;

  /// Label for cell group name on create/edit
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cellGroupsNameLabel;

  /// Placeholder example for cell group name
  ///
  /// In en, this message translates to:
  /// **'e.g. Young Adults'**
  String get cellGroupsNameHint;

  /// Helper under cell group name field
  ///
  /// In en, this message translates to:
  /// **'The public title on the Groups list and the group page.'**
  String get cellGroupsNameHelper;

  /// Validation when cell group name is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get cellGroupsNameRequired;

  /// Label for cell group summary on create/edit
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get cellGroupsSummaryLabel;

  /// Placeholder for cell group summary
  ///
  /// In en, this message translates to:
  /// **'Who this group is for, and what you usually do'**
  String get cellGroupsSummaryHint;

  /// Helper under cell group summary field
  ///
  /// In en, this message translates to:
  /// **'Short description on the catalogue card and in About.'**
  String get cellGroupsSummaryHelper;

  /// Label for usual meeting weekday on create/edit
  ///
  /// In en, this message translates to:
  /// **'Meeting weekday'**
  String get cellGroupsWeekdayLabel;

  /// Helper under cell group weekday dropdown
  ///
  /// In en, this message translates to:
  /// **'Usual day this group meets. Leave unset if it varies.'**
  String get cellGroupsWeekdayHelper;

  /// Dropdown option when no meeting weekday is chosen
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cellGroupsWeekdayNotSet;

  /// Label for usual meeting time on create/edit
  ///
  /// In en, this message translates to:
  /// **'Meeting time'**
  String get cellGroupsTimeLabel;

  /// Placeholder example for meeting time
  ///
  /// In en, this message translates to:
  /// **'e.g. 19:30'**
  String get cellGroupsTimeHint;

  /// Helper under cell group meeting time field
  ///
  /// In en, this message translates to:
  /// **'Usual start time, shown with the weekday on the Groups list.'**
  String get cellGroupsTimeHelper;

  /// Label for cell group status on create/edit
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get cellGroupsStatusLabel;

  /// Helper under cell group status dropdown
  ///
  /// In en, this message translates to:
  /// **'Active groups appear in the catalogue. Paused groups stay listed as paused. Archived groups are hidden.'**
  String get cellGroupsStatusHelper;

  /// Helper under leaders on create/edit cell group
  ///
  /// In en, this message translates to:
  /// **'People who lead this group. Catalogue tiles use the first leader’s portrait.'**
  String get cellGroupsLeadersHint;

  /// Button to pick cell group leaders
  ///
  /// In en, this message translates to:
  /// **'Choose leaders'**
  String get cellGroupsChooseLeaders;
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
