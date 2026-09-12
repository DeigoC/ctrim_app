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

  /// Title for the people directory when showing all locations
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get volunteersTitle;

  /// Title for the people directory filtered by location
  ///
  /// In en, this message translates to:
  /// **'{location} People'**
  String volunteersTitleLocation(String location);

  /// Filter chip label to show people from every location
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get volunteersFilterAll;

  /// Filter chip for people who serve (leaders, team tags, or cell-group leaders)
  ///
  /// In en, this message translates to:
  /// **'Serving'**
  String get volunteersFilterServing;

  /// Active filter summary when the serving-only toggle is off
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get volunteersFilterEveryone;

  /// Hint text for the people directory search field
  ///
  /// In en, this message translates to:
  /// **'Search people...'**
  String get volunteersSearchHint;

  /// Empty state when the people list has no entries
  ///
  /// In en, this message translates to:
  /// **'No people found'**
  String get volunteersEmpty;

  /// Empty state when search returns no people
  ///
  /// In en, this message translates to:
  /// **'No people match \"{query}\"'**
  String volunteersEmptySearch(String query);

  /// Banner when a refined people search is empty but name matches exist without filters
  ///
  /// In en, this message translates to:
  /// **'No matches with current filters. Showing {count, plural, =1{1 person} other{{count} people}} who match without filters (other locations, everyone, and placeholders you can see).'**
  String volunteersSearchWithoutFiltersBanner(int count);

  /// Clears location/serving/role filters so search matches are easier to find
  ///
  /// In en, this message translates to:
  /// **'Widen search'**
  String get volunteersWidenSearch;

  /// Empty state when a location filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No people in {location}'**
  String volunteersEmptyLocation(String location);

  /// Empty state when the Serving filter hides attendees
  ///
  /// In en, this message translates to:
  /// **'No serving people here. Turn off Serving to see everyone.'**
  String get volunteersEmptyServing;

  /// Empty state when Serving plus a location filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No serving people in {location}. Turn off Serving to see everyone.'**
  String volunteersEmptyServingLocation(String location);

  /// FAB label for registering a new person
  ///
  /// In en, this message translates to:
  /// **'Register person'**
  String get registerUser;

  /// Personal home menu item for the people directory
  ///
  /// In en, this message translates to:
  /// **'Who\'s who'**
  String get volunteersMenuTitle;

  /// Personal home menu subtitle for the people directory
  ///
  /// In en, this message translates to:
  /// **'Leaders, teams, and members'**
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

  /// Empty state on Personal home schedule dashboard card
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks assigned for now.'**
  String get personalScheduleEmpty;

  /// Opens the full schedule page from Personal home
  ///
  /// In en, this message translates to:
  /// **'View full schedule'**
  String get personalScheduleViewFull;

  /// Opens full schedule when more than three upcoming posts
  ///
  /// In en, this message translates to:
  /// **'View all {count} upcoming'**
  String personalScheduleViewAll(int count);

  /// Title for Personal home cell groups dashboard card
  ///
  /// In en, this message translates to:
  /// **'Cell groups'**
  String get personalCellGroupsTitle;

  /// Subtitle for Personal home cell groups dashboard card
  ///
  /// In en, this message translates to:
  /// **'Your groups and upcoming meetings'**
  String get personalCellGroupsSubtitle;

  /// Encouraging empty state when user belongs to no cell groups
  ///
  /// In en, this message translates to:
  /// **'You are not in a cell group yet. Browse groups to find one that fits you.'**
  String get personalCellGroupsEmpty;

  /// CTA on Personal home to open the Cell Groups section
  ///
  /// In en, this message translates to:
  /// **'Browse cell groups'**
  String get personalCellGroupsBrowse;

  /// Message when member has groups but no upcoming CG meetings
  ///
  /// In en, this message translates to:
  /// **'No upcoming meetings in the next 8 weeks.'**
  String get personalCellGroupsNoUpcoming;

  /// Leader line on Personal home cell group rows
  ///
  /// In en, this message translates to:
  /// **'Led by {leader}'**
  String personalCellGroupLedBy(String leader);

  /// Fallback when a cell group leader cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Leader TBC'**
  String get personalCellGroupLeaderTbc;

  /// Overflow hint when more than three CG meetings exist
  ///
  /// In en, this message translates to:
  /// **'And {count} more upcoming meetings'**
  String personalCellGroupsMoreMeetings(int count);

  /// Fallback when a schedule post has no event date
  ///
  /// In en, this message translates to:
  /// **'Date TBC'**
  String get personalScheduleDateTbc;

  /// Chip on schedule preview when user has multiple roles on one post
  ///
  /// In en, this message translates to:
  /// **'{count} roles'**
  String personalScheduleRolesCount(int count);

  /// Fallback title when event head is missing on schedule preview
  ///
  /// In en, this message translates to:
  /// **'Untitled event'**
  String get personalScheduleUntitledEvent;

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

  /// Section title on a profile for cell group membership
  ///
  /// In en, this message translates to:
  /// **'Cell groups'**
  String get userProfileCellGroups;

  /// Message when a person is not listed on any cell group roster or as a leader
  ///
  /// In en, this message translates to:
  /// **'Not in a cell group.'**
  String get userProfileNoCellGroups;

  /// Profile note when the person checked in at a cell group meeting in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'Attended in the past 3 weeks'**
  String get userProfileCellGroupAttendedRecent;

  /// Profile attendance summary with meeting count in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Attended 1 cell group meeting in the past 3 weeks} other{Attended {count} cell group meetings in the past 3 weeks}}'**
  String userProfileCellGroupMeetingsAttendedCount(int count);

  /// Suffix when attendance spans multiple cell groups
  ///
  /// In en, this message translates to:
  /// **'across {count, plural, =1{1 group} other{{count} groups}}'**
  String userProfileCellGroupGroupsAttendedSuffix(int count);

  /// Profile note when the person did not check in at a cell group meeting in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'No cell group attendance in the past 3 weeks'**
  String get userProfileCellGroupNoAttendanceRecent;

  /// Heading above the past few cell group meeting rows on a profile
  ///
  /// In en, this message translates to:
  /// **'Recent meetings'**
  String get userProfileCellGroupRecentMeetings;

  /// Collapsed subtitle showing how many recent cell group meetings are listed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 meeting} other{{count} meetings}}'**
  String userProfileCellGroupRecentMeetingsCount(int count);

  /// Subtitle when the person checked in at that cell group meeting
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get userProfileCellGroupMeetingAttended;

  /// Subtitle when the person did not check in at that cell group meeting
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get userProfileCellGroupMeetingMissed;

  /// Empty state when membership exists but no past-window CG posts were found
  ///
  /// In en, this message translates to:
  /// **'No linked cell group meetings in the past 3 weeks'**
  String get userProfileCellGroupNoRecentMeetings;

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
  /// **'No team tags yet. Create tags for teams like Worship, Technical, or Usher.'**
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
  /// **'Cannot delete — {count} people still have this tag. Deactivate it instead.'**
  String manageUserTagsDeleteBlocked(int count);

  /// Personal home admin menu item for managing tags
  ///
  /// In en, this message translates to:
  /// **'Team tags'**
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
  /// **'Cannot delete — {count} people still have this location. Deactivate it instead.'**
  String manageUserLocationsDeleteBlocked(int count);

  /// Error when creating or renaming to a duplicate location name
  ///
  /// In en, this message translates to:
  /// **'A location named \"{name}\" already exists.'**
  String manageUserLocationsDuplicate(String name);

  /// Personal home admin menu item for managing locations
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get manageUserLocationsMenuTitle;

  /// Personal home admin menu subtitle for managing locations
  ///
  /// In en, this message translates to:
  /// **'Create and edit place labels'**
  String get manageUserLocationsMenuSubtitle;

  /// Empty state when tag filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No people match the selected tags'**
  String get volunteersEmptyTags;

  /// Title for the multi-select people picker page
  ///
  /// In en, this message translates to:
  /// **'Select people'**
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

  /// Button on the people picker to merge roster members from cell groups
  ///
  /// In en, this message translates to:
  /// **'Add from cell group'**
  String get selectUsersAddFromCellGroup;

  /// Progress title while merging cell group roster members into selection
  ///
  /// In en, this message translates to:
  /// **'Adding from cell group…'**
  String get selectUsersAddingFromCellGroup;

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

  /// Filter chip to show only placeholder profiles in the people list
  ///
  /// In en, this message translates to:
  /// **'Placeholders'**
  String get volunteersShowPlaceholders;

  /// Filter toggle to include hidden and archived profiles in the people list (area admin)
  ///
  /// In en, this message translates to:
  /// **'Hidden & archived'**
  String get volunteersShowInactive;

  /// Volunteer profile status: visible in directory and pickers
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get volunteersStatusActive;

  /// Volunteer profile status: hidden from directory and new assignments
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get volunteersStatusHidden;

  /// Volunteer profile status: retired profile, hidden like hidden
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get volunteersStatusArchived;

  /// Label for volunteer profile status dropdown on edit user
  ///
  /// In en, this message translates to:
  /// **'Profile status'**
  String get volunteersStatusLabel;

  /// Helper text under profile status on edit user
  ///
  /// In en, this message translates to:
  /// **'Hidden and archived profiles stay out of People and new assignments. Past events still show their name. They cannot sign in.'**
  String get volunteersStatusHelper;

  /// Title when an admin sets a volunteer to hidden or archived
  ///
  /// In en, this message translates to:
  /// **'Change profile status?'**
  String get volunteersStatusConfirmTitle;

  /// Body when an admin sets a volunteer to hidden or archived
  ///
  /// In en, this message translates to:
  /// **'They will be removed from People and pickers, cannot sign in, and leader/admin permissions will be cleared. Past events and attendance still show their name.'**
  String get volunteersStatusConfirmMessage;

  /// Banner on profile when status is hidden
  ///
  /// In en, this message translates to:
  /// **'This profile is hidden from the directory'**
  String get volunteersInactiveProfileBanner;

  /// Banner on profile when status is archived
  ///
  /// In en, this message translates to:
  /// **'This profile is archived'**
  String get volunteersArchivedProfileBanner;

  /// Error when signing in with a hidden or archived volunteer profile
  ///
  /// In en, this message translates to:
  /// **'Your volunteer profile is no longer active. Please contact an admin if you think this is a mistake.'**
  String get volunteersLoginInactive;

  /// Empty state when show-inactive filter is on but none match
  ///
  /// In en, this message translates to:
  /// **'No hidden or archived profiles to show'**
  String get volunteersEmptyInactive;

  /// Empty state when the placeholders filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No placeholder profiles to show'**
  String get volunteersEmptyPlaceholders;

  /// Badge on placeholder volunteer cards
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get volunteersPlaceholderBadge;

  /// Label before sort mode chips on the people list
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get volunteersSortLabel;

  /// Sort people by surname
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get volunteersSortSurname;

  /// Sort people by primary team tag
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get volunteersSortTags;

  /// Filter chip to show people with the Leader permission
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get volunteersFilterLeaders;

  /// Filter chip to show people who are area admins
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get volunteersFilterAdmins;

  /// Filter chip to show people who lead a cell group
  ///
  /// In en, this message translates to:
  /// **'CG Leaders'**
  String get volunteersFilterCellGroupLeaders;

  /// Empty state when a role filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No people match the selected roles'**
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

  /// Tooltip for the people directory sort menu in the app bar
  ///
  /// In en, this message translates to:
  /// **'Sort people'**
  String get volunteersSortTooltip;

  /// App bar tooltip for the people directory filter button
  ///
  /// In en, this message translates to:
  /// **'Refine & sort'**
  String get volunteersFilterTooltip;

  /// Title for the people directory filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Refine & sort'**
  String get volunteersFilterSheetTitle;

  /// Subtitle for the people directory filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Location, sort, role, team, or who is shown'**
  String get volunteersFilterSheetSubtitle;

  /// Section label for serving / placeholder toggles in people filters
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get volunteersFilterShowSection;

  /// Section label for location chips in the people directory filter sheet
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get volunteersFilterLocationSection;

  /// Helper under the Serving toggle in people filters
  ///
  /// In en, this message translates to:
  /// **'People who serve on teams or lead groups'**
  String get volunteersFilterServingSubtitle;

  /// Section label for role filters in the people directory
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get volunteersFilterRolesSection;

  /// Section label for team tag filters in the people directory
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get volunteersFilterTeamsSection;

  /// Count label above the people directory list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String volunteersShowingCount(int count);

  /// Short intro on the people directory
  ///
  /// In en, this message translates to:
  /// **'Browse leaders and team members in the church family.'**
  String get volunteersDirectoryIntro;

  /// Resets people directory filters to defaults
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get volunteersClearFilters;

  /// Banner listing active people directory filters
  ///
  /// In en, this message translates to:
  /// **'Showing: {parts}'**
  String volunteersShowing(String parts);

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

  /// Bible reference for CG overview scripture card
  ///
  /// In en, this message translates to:
  /// **'Acts 2:42, 46–47'**
  String get cellGroupsOverviewVerseReference;

  /// Verse body for CG overview scripture card
  ///
  /// In en, this message translates to:
  /// **'\"They devoted themselves to the apostles’ teaching and to fellowship, to the breaking of bread and to prayer… They continued to meet together… And the Lord added to their number daily those who were being saved.\"'**
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

  /// Filter chip label for attendance sum on activity trend charts
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get activityTrendMetricAttendance;

  /// Hint under metric chips on weekly activity line charts
  ///
  /// In en, this message translates to:
  /// **'Weekly · last 3 months'**
  String get activityTrendWeeklyHint;

  /// Empty state when weekly activity chart has no data
  ///
  /// In en, this message translates to:
  /// **'No activity in this period.'**
  String get activityTrendEmpty;

  /// Title for church hub weekly activity line chart
  ///
  /// In en, this message translates to:
  /// **'Activity over time'**
  String get churchHubActivityTrendTitle;

  /// Subtitle for church hub weekly activity line chart
  ///
  /// In en, this message translates to:
  /// **'Bulletin posts at this location'**
  String get churchHubActivityTrendSubtitle;

  /// Count metric chip on church hub activity chart
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get churchHubActivityTrendMetricPosts;

  /// Title for cell groups weekly activity line chart
  ///
  /// In en, this message translates to:
  /// **'Meetings over time'**
  String get cellGroupsActivityTrendTitle;

  /// Subtitle for cell groups weekly activity line chart
  ///
  /// In en, this message translates to:
  /// **'Cell group meetings linked on the bulletin'**
  String get cellGroupsActivityTrendSubtitle;

  /// Count metric chip on cell groups activity chart
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get cellGroupsActivityTrendMetricMeetings;

  /// Section title for per-group activity on cell group detail
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get cellGroupsDetailActivityTitle;

  /// Chart title on cell group detail activity card
  ///
  /// In en, this message translates to:
  /// **'Meetings over time'**
  String get cellGroupsDetailActivityTrendTitle;

  /// Chart subtitle on cell group detail activity card
  ///
  /// In en, this message translates to:
  /// **'Bulletin posts linked to this group'**
  String get cellGroupsDetailActivityTrendSubtitle;

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

  /// Label for church-area location on create/edit cell group
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get cellGroupsLocationLabel;

  /// Helper under cell group location dropdown
  ///
  /// In en, this message translates to:
  /// **'Church area this group belongs to (Belfast, Portadown, or North Coast).'**
  String get cellGroupsLocationHelper;

  /// Label for optional UK postcode on create/edit cell group
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get cellGroupsPostcodeLabel;

  /// Placeholder example for cell group postcode or outcode
  ///
  /// In en, this message translates to:
  /// **'e.g. BT37 or BT37 0AB'**
  String get cellGroupsPostcodeHint;

  /// Helper under optional cell group postcode field
  ///
  /// In en, this message translates to:
  /// **'Optional. A full postcode or just the first half (BT37) is public and used to find the nearest group. Leave blank to stay off the map.'**
  String get cellGroupsPostcodeHelper;

  /// Validation when cell group postcode is not a full postcode or outcode
  ///
  /// In en, this message translates to:
  /// **'Enter a UK postcode or area code (e.g. BT37), or leave this blank.'**
  String get cellGroupsPostcodeInvalid;

  /// Error when postcodes.io lookup fails on save
  ///
  /// In en, this message translates to:
  /// **'Could not check that postcode. Check it and try again.'**
  String get cellGroupsPostcodeLookupFailed;

  /// Hint on the Groups tab search field
  ///
  /// In en, this message translates to:
  /// **'Search by name or postcode'**
  String get cellGroupsListSearchHint;

  /// Empty-state title when nearest search postcode is invalid
  ///
  /// In en, this message translates to:
  /// **'Not a valid postcode'**
  String get cellGroupsSearchInvalidPostcodeTitle;

  /// Empty-state body when nearest search postcode is invalid
  ///
  /// In en, this message translates to:
  /// **'Try a full UK postcode such as BT9 6AB, or an area code such as BT9.'**
  String get cellGroupsSearchInvalidPostcodeBody;

  /// Empty-state title when no groups have a postcode pin
  ///
  /// In en, this message translates to:
  /// **'No groups near that postcode'**
  String get cellGroupsSearchNoNearbyTitle;

  /// Empty-state body when nearest search has no opted-in groups
  ///
  /// In en, this message translates to:
  /// **'Only groups that have added a postcode can appear in nearest results. Search by name, or browse the full list.'**
  String get cellGroupsSearchNoNearbyBody;

  /// Empty-state title when name search has no matches
  ///
  /// In en, this message translates to:
  /// **'No matching groups'**
  String get cellGroupsSearchNoNameMatchesTitle;

  /// Empty-state body when name search has no matches
  ///
  /// In en, this message translates to:
  /// **'Try another name, or enter a postcode to see the nearest groups.'**
  String get cellGroupsSearchNoNameMatchesBody;

  /// Empty-state title when postcodes.io fails on Groups search
  ///
  /// In en, this message translates to:
  /// **'Could not look up that postcode'**
  String get cellGroupsSearchLookupFailedTitle;

  /// Empty-state body when postcodes.io fails on Groups search
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get cellGroupsSearchLookupFailedBody;

  /// Distance from the seeker's postcode to a cell group
  ///
  /// In en, this message translates to:
  /// **'{miles} miles'**
  String cellGroupsDistanceMiles(String miles);

  /// Distance label when a cell group is under 0.1 miles away
  ///
  /// In en, this message translates to:
  /// **'< 0.1 miles'**
  String get cellGroupsDistanceUnderPointOne;

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

  /// Title of the bulletin sort and filter sheet
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get bulletinSortFilterTitle;

  /// Subtitle of the bulletin sort and filter sheet
  ///
  /// In en, this message translates to:
  /// **'Choose how to organize your events'**
  String get bulletinSortFilterSubtitle;

  /// App bar tooltip for the bulletin sort and filter button
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get bulletinSortTooltip;

  /// Section label for bulletin sort order
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get bulletinSortSection;

  /// Default bulletin sort: today, then upcoming, then the rest
  ///
  /// In en, this message translates to:
  /// **'Relevancy'**
  String get bulletinSortRelevancy;

  /// Explains relevancy sort on the bulletin
  ///
  /// In en, this message translates to:
  /// **'Next few events, then recent past'**
  String get bulletinSortRelevancySubtitle;

  /// Bulletin sort: upcoming events by date, then recent past
  ///
  /// In en, this message translates to:
  /// **'Soonest first'**
  String get bulletinSortSoonest;

  /// Explains soonest-first sort
  ///
  /// In en, this message translates to:
  /// **'Upcoming events first, then recent past'**
  String get bulletinSortSoonestSubtitle;

  /// Bulletin sort: recent past first, then upcoming
  ///
  /// In en, this message translates to:
  /// **'Latest first'**
  String get bulletinSortLatest;

  /// Explains latest-first sort
  ///
  /// In en, this message translates to:
  /// **'Recent past first, then upcoming'**
  String get bulletinSortLatestSubtitle;

  /// Section label for bulletin time and bookmark filters
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get bulletinShowSection;

  /// Time filter that does not hide past or upcoming posts
  ///
  /// In en, this message translates to:
  /// **'All posts'**
  String get bulletinShowAll;

  /// Filter the bulletin to upcoming events
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bulletinShowUpcoming;

  /// Filter the bulletin to past events
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bulletinShowPast;

  /// Filter the bulletin to bookmarked posts
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bulletinShowBookmarks;

  /// Section label for bulletin location filter
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get bulletinLocationSection;

  /// Helper under bulletin location chips
  ///
  /// In en, this message translates to:
  /// **'Show posts for a specific place'**
  String get bulletinLocationSubtitle;

  /// Helper under bulletin content tag chips
  ///
  /// In en, this message translates to:
  /// **'Narrow the bulletin by content type'**
  String get bulletinTagsSubtitle;

  /// Banner listing the active bulletin sort and filters
  ///
  /// In en, this message translates to:
  /// **'Showing: {parts}'**
  String bulletinShowing(String parts);

  /// Clears bulletin sort and filters back to defaults
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get bulletinClearFilters;

  /// Empty state title when no bulletin posts match
  ///
  /// In en, this message translates to:
  /// **'No Events Found'**
  String get bulletinEmptyTitle;

  /// Empty state body when bulletin filters hide every post
  ///
  /// In en, this message translates to:
  /// **'There are no events matching your current filters.\nTry adjusting your sort or filters.'**
  String get bulletinEmptyBody;

  /// Button on the empty bulletin to open sort and filter
  ///
  /// In en, this message translates to:
  /// **'Change Filter'**
  String get bulletinChangeFilter;

  /// Title of the bookmarks help dialog
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Posts'**
  String get bulletinBookmarksHelpTitle;

  /// Explains how bookmarks work on the bulletin
  ///
  /// In en, this message translates to:
  /// **'You will be notified of updates made to the posts you bookmark.\n\nTo bookmark a post, tap and hold on any event card.'**
  String get bulletinBookmarksHelpBody;

  /// Tooltip on the bookmarks help button
  ///
  /// In en, this message translates to:
  /// **'Learn about bookmarks'**
  String get bulletinBookmarksHelpTooltip;

  /// App bar fallback title for a church hub page
  ///
  /// In en, this message translates to:
  /// **'Church Info'**
  String get churchInfoPageTitle;

  /// Empty state when a church record cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'No church information found.'**
  String get churchInfoNotFound;

  /// Tooltip on the church hub edit button
  ///
  /// In en, this message translates to:
  /// **'Edit church info'**
  String get churchInfoEditTooltip;

  /// Error title when the church hub fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load church'**
  String get churchInfoLoadError;

  /// Button that opens the church maps URL
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get churchHubOpenMaps;

  /// Chip when a church has no linked location
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get churchHubLocationUnset;

  /// Hint on the church hub when location is missing
  ///
  /// In en, this message translates to:
  /// **'Set a location when editing to show posts, cell groups, and people for this church.'**
  String get churchHubSetLocationHint;

  /// Section title for church location snapshot counts
  ///
  /// In en, this message translates to:
  /// **'At this location'**
  String get churchHubSnapshotTitle;

  /// Count tile label for bulletin posts
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get churchHubPostsLabel;

  /// Hint under the posts count on a church hub
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get churchHubPostsHint;

  /// Count tile label for cell groups at the church location
  ///
  /// In en, this message translates to:
  /// **'Cell Groups'**
  String get churchHubCellGroupsLabel;

  /// Hint under the cell groups count on a church hub
  ///
  /// In en, this message translates to:
  /// **'Active and paused'**
  String get churchHubCellGroupsHint;

  /// Count tile label for registered people at the church location
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get churchHubPeopleLabel;

  /// Hint under the people count on a church hub
  ///
  /// In en, this message translates to:
  /// **'Profiles here'**
  String get churchHubPeopleHint;

  /// Heading above recent bulletin posts on a church hub
  ///
  /// In en, this message translates to:
  /// **'Recent posts'**
  String get churchHubRecentPosts;

  /// Heading above cell groups listed on a church hub
  ///
  /// In en, this message translates to:
  /// **'Cell Groups here'**
  String get churchHubCellGroupsHere;

  /// Empty state when the church location has no recent posts
  ///
  /// In en, this message translates to:
  /// **'No posts in the last 3 months.'**
  String get churchHubNoRecentPosts;

  /// Empty state when the church location has no cell groups
  ///
  /// In en, this message translates to:
  /// **'No cell groups at this location yet.'**
  String get churchHubNoCellGroups;

  /// Shown when the church hub truncates the recent posts list
  ///
  /// In en, this message translates to:
  /// **'And {count} more'**
  String churchHubMorePosts(int count);

  /// Error when the church hub snapshot query fails
  ///
  /// In en, this message translates to:
  /// **'Could not load location activity.'**
  String get churchHubStatsError;

  /// Retry loading church location snapshot
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get churchHubStatsRetry;

  /// Section title for the church hub Quill overview
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get churchHubAboutTitle;

  /// Section title for extra church hub pages
  ///
  /// In en, this message translates to:
  /// **'More about this church'**
  String get churchHubPagesTitle;

  /// Empty state when a church hub has no nested pages
  ///
  /// In en, this message translates to:
  /// **'No extra pages yet.'**
  String get churchHubNoPages;

  /// Button for area admins to add a nested church page
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get churchHubAddPage;

  /// Helper text on the add church page card
  ///
  /// In en, this message translates to:
  /// **'Add a page for getting here, Sunday service, or other details.'**
  String get churchHubAddPageDescription;

  /// Error when nested church pages fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load extra pages.'**
  String get churchHubPagesError;

  /// Retry loading nested church pages
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get churchHubPagesRetry;

  /// Heading for the pastors section on a church hub page
  ///
  /// In en, this message translates to:
  /// **'Pastors'**
  String get churchHubPastorsTitle;

  /// Heading for church planters on an outreach hub
  ///
  /// In en, this message translates to:
  /// **'Church planters'**
  String get churchHubPlantersTitle;

  /// Fallback label when a pastor user record cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Unknown pastor'**
  String get churchHubUnknownPastor;

  /// Fallback label when a church planter user cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Unknown planter'**
  String get churchHubUnknownPlanter;

  /// Dashboard card title for church location, address, and maps
  ///
  /// In en, this message translates to:
  /// **'Find us'**
  String get churchHubFindUsTitle;

  /// Dashboard card subtitle for the visit / find-us card
  ///
  /// In en, this message translates to:
  /// **'Location, address, and maps'**
  String get churchHubFindUsSubtitle;

  /// Dashboard card subtitle for the pastors card
  ///
  /// In en, this message translates to:
  /// **'Meet the team'**
  String get churchHubPastorsSubtitle;

  /// Dashboard card subtitle for church planters on an outreach
  ///
  /// In en, this message translates to:
  /// **'Leading this outreach'**
  String get churchHubPlantersSubtitle;

  /// Button on the church hub pastors card that opens the pastors page
  ///
  /// In en, this message translates to:
  /// **'Learn about them'**
  String get churchHubLearnAboutPastors;

  /// Button on the outreach hub that opens the planters write-up
  ///
  /// In en, this message translates to:
  /// **'Learn about them'**
  String get churchHubLearnAboutPlanters;

  /// App bar title for the church pastors write-up page
  ///
  /// In en, this message translates to:
  /// **'Pastors'**
  String get churchPastorsPageTitle;

  /// App bar title for the outreach planters write-up page
  ///
  /// In en, this message translates to:
  /// **'Church planters'**
  String get churchPlantersPageTitle;

  /// Label under the title when viewing an outreach hub
  ///
  /// In en, this message translates to:
  /// **'Outreach'**
  String get churchHubOutreachBadge;

  /// Subtitle on Churches tab cards for an outreach
  ///
  /// In en, this message translates to:
  /// **'Outreach of {parentTitle}'**
  String churchesTabOutreachOf(String parentTitle);

  /// Card title linking an outreach back to its parent church
  ///
  /// In en, this message translates to:
  /// **'Parent church'**
  String get churchHubParentChurchTitle;

  /// Card subtitle for the parent church link
  ///
  /// In en, this message translates to:
  /// **'This outreach belongs to'**
  String get churchHubParentChurchSubtitle;

  /// Card title listing baby churches under a full church
  ///
  /// In en, this message translates to:
  /// **'Outreaches'**
  String get churchHubOutreachesTitle;

  /// Card subtitle for outreaches on a church hub
  ///
  /// In en, this message translates to:
  /// **'Growing toward a full church'**
  String get churchHubOutreachesSubtitle;

  /// Empty state when a church has no outreaches
  ///
  /// In en, this message translates to:
  /// **'No outreaches yet.'**
  String get churchHubNoOutreaches;

  /// CTA to create an outreach under a church
  ///
  /// In en, this message translates to:
  /// **'Add outreach'**
  String get churchHubAddOutreach;

  /// Description under Add outreach on the church hub
  ///
  /// In en, this message translates to:
  /// **'Add a baby church with church planters.'**
  String get churchHubAddOutreachDescription;

  /// Empty Find us card when an outreach has no visit details
  ///
  /// In en, this message translates to:
  /// **'No address or maps link yet.'**
  String get churchHubOutreachFindUsEmpty;

  /// Dashboard card title for church gallery photos
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get churchHubGalleryTitle;

  /// Dashboard card subtitle for the gallery card
  ///
  /// In en, this message translates to:
  /// **'Photos from this church'**
  String get churchHubGallerySubtitle;

  /// Dashboard card subtitle for location snapshot counts
  ///
  /// In en, this message translates to:
  /// **'Activity at this location'**
  String get churchHubSnapshotSubtitle;

  /// Dashboard card subtitle for extra church pages
  ///
  /// In en, this message translates to:
  /// **'Getting here, Sunday service, and more'**
  String get churchHubPagesSubtitle;

  /// Dashboard card subtitle for recent bulletin posts
  ///
  /// In en, this message translates to:
  /// **'From the last 3 months'**
  String get churchHubRecentPostsSubtitle;

  /// Dashboard card subtitle for cell groups at this church
  ///
  /// In en, this message translates to:
  /// **'Meeting at this location'**
  String get churchHubCellGroupsSubtitle;

  /// Editor card title for church name and summary
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get churchEditorChurchCardTitle;

  /// Editor card subtitle for church identity fields
  ///
  /// In en, this message translates to:
  /// **'Name and how it appears in the list'**
  String get churchEditorChurchCardSubtitle;

  /// Editor card title for outreach name and summary
  ///
  /// In en, this message translates to:
  /// **'Outreach'**
  String get churchEditorOutreachCardTitle;

  /// Editor card subtitle for outreach identity fields
  ///
  /// In en, this message translates to:
  /// **'Name and how it appears under the parent church'**
  String get churchEditorOutreachCardSubtitle;

  /// Editor card for church vs outreach and parent
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get churchEditorStatusCardTitle;

  /// Editor card subtitle for kind and parent
  ///
  /// In en, this message translates to:
  /// **'Full church or outreach under a parent'**
  String get churchEditorStatusCardSubtitle;

  /// Label when editing a full church hub
  ///
  /// In en, this message translates to:
  /// **'Full church'**
  String get churchEditorKindChurch;

  /// Hint for full church status
  ///
  /// In en, this message translates to:
  /// **'Appears in the Churches list and uses its own location.'**
  String get churchEditorKindChurchHint;

  /// Label when editing an outreach
  ///
  /// In en, this message translates to:
  /// **'Outreach'**
  String get churchEditorKindOutreach;

  /// Hint for outreach status
  ///
  /// In en, this message translates to:
  /// **'Listed on the parent church hub until promoted.'**
  String get churchEditorKindOutreachHint;

  /// Dropdown label for outreach parent
  ///
  /// In en, this message translates to:
  /// **'Parent church'**
  String get churchEditorParentChurchLabel;

  /// Helper under parent church dropdown
  ///
  /// In en, this message translates to:
  /// **'The full church this outreach belongs to.'**
  String get churchEditorParentChurchHelper;

  /// Button to turn an outreach into a full church
  ///
  /// In en, this message translates to:
  /// **'Promote to full church'**
  String get churchEditorPromoteToChurch;

  /// Button to turn a full church into an outreach
  ///
  /// In en, this message translates to:
  /// **'Demote to outreach'**
  String get churchEditorDemoteToOutreach;

  /// Cancel button on church promote/demote dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get churchEditorCancel;

  /// Confirm dialog title when promoting an outreach
  ///
  /// In en, this message translates to:
  /// **'Promote to full church?'**
  String get churchEditorPromoteConfirmTitle;

  /// Confirm dialog body when promoting an outreach
  ///
  /// In en, this message translates to:
  /// **'This outreach will leave its parent and need its own location before you save.'**
  String get churchEditorPromoteConfirmBody;

  /// Alert title when promote is blocked
  ///
  /// In en, this message translates to:
  /// **'Cannot promote'**
  String get churchEditorPromoteBlockedTitle;

  /// Confirm dialog title when demoting a church
  ///
  /// In en, this message translates to:
  /// **'Demote to outreach?'**
  String get churchEditorDemoteConfirmTitle;

  /// Confirm dialog body when demoting a church
  ///
  /// In en, this message translates to:
  /// **'This church will sit under a parent and lose its location assignment. Choose the parent church.'**
  String get churchEditorDemoteConfirmBody;

  /// Alert title when demote is blocked
  ///
  /// In en, this message translates to:
  /// **'Cannot demote'**
  String get churchEditorDemoteBlockedTitle;

  /// Alert when demote has no eligible parent
  ///
  /// In en, this message translates to:
  /// **'Add another full church first to use as the parent.'**
  String get churchEditorDemoteNoParent;

  /// Alert title when church hierarchy validation fails
  ///
  /// In en, this message translates to:
  /// **'Check church details'**
  String get churchEditorValidationTitle;

  /// Alert title when two churches share a location
  ///
  /// In en, this message translates to:
  /// **'Location already used'**
  String get churchEditorLocationConflictTitle;

  /// Alert body when location is already taken
  ///
  /// In en, this message translates to:
  /// **'Location “{location}” is already used by {churchTitle}. Each church must have its own location.'**
  String churchEditorLocationConflictBody(String location, String churchTitle);

  /// Alert title when deleting a church with outreaches
  ///
  /// In en, this message translates to:
  /// **'Cannot delete'**
  String get churchEditorDeleteBlockedTitle;

  /// Alert body when deleting a church that still has outreaches
  ///
  /// In en, this message translates to:
  /// **'Promote or delete this church’s outreaches first.'**
  String get churchEditorDeleteBlockedBody;

  /// Location dropdown label on church editor
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get churchEditorLocationLabel;

  /// Helper under location dropdown
  ///
  /// In en, this message translates to:
  /// **'Each church must use a unique location from the catalogue.'**
  String get churchEditorLocationHelper;

  /// Shown instead of location dropdown on outreach editor
  ///
  /// In en, this message translates to:
  /// **'Outreaches do not use a catalogue location until they are promoted to a full church. You can still add an address and maps link.'**
  String get churchEditorOutreachLocationHint;

  /// Address field label on church editor
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get churchEditorAddressLabel;

  /// Helper under address field
  ///
  /// In en, this message translates to:
  /// **'Optional street address shown on the church page.'**
  String get churchEditorAddressHelper;

  /// Maps URL field label on church editor
  ///
  /// In en, this message translates to:
  /// **'Maps URL'**
  String get churchEditorMapsLabel;

  /// Helper under maps URL field
  ///
  /// In en, this message translates to:
  /// **'Optional Google Maps (or similar) link.'**
  String get churchEditorMapsHelper;

  /// Tooltip for maps URL help button
  ///
  /// In en, this message translates to:
  /// **'Maps URL help'**
  String get churchEditorMapsHelpTooltip;

  /// Editor card title for location, address, and maps
  ///
  /// In en, this message translates to:
  /// **'Find us'**
  String get churchEditorVisitCardTitle;

  /// Editor card subtitle for visit fields
  ///
  /// In en, this message translates to:
  /// **'Location, address, and maps'**
  String get churchEditorVisitCardSubtitle;

  /// Editor card title for pastors, photo, and write-up
  ///
  /// In en, this message translates to:
  /// **'Pastors'**
  String get churchEditorPastorsCardTitle;

  /// Editor card subtitle for pastors fields and Quill body
  ///
  /// In en, this message translates to:
  /// **'People listed as pastors, plus their write-up'**
  String get churchEditorPastorsCardSubtitle;

  /// Editor card title for planters on an outreach
  ///
  /// In en, this message translates to:
  /// **'Church planters'**
  String get churchEditorPlantersCardTitle;

  /// Editor card subtitle for planters fields
  ///
  /// In en, this message translates to:
  /// **'People leading this outreach, plus their write-up'**
  String get churchEditorPlantersCardSubtitle;

  /// Button to pick pastor users
  ///
  /// In en, this message translates to:
  /// **'Choose pastors'**
  String get churchEditorChoosePastors;

  /// Button to pick church planter users
  ///
  /// In en, this message translates to:
  /// **'Choose church planters'**
  String get churchEditorChoosePlanters;

  /// Label for pastors team photo URL
  ///
  /// In en, this message translates to:
  /// **'Pastors image URL'**
  String get churchEditorPastorsImageLabel;

  /// Helper for pastors image URL
  ///
  /// In en, this message translates to:
  /// **'Optional team photo shown in the pastors card.'**
  String get churchEditorPastorsImageHelper;

  /// Label for planters team photo URL
  ///
  /// In en, this message translates to:
  /// **'Planters image URL'**
  String get churchEditorPlantersImageLabel;

  /// Helper for planters image URL
  ///
  /// In en, this message translates to:
  /// **'Optional team photo shown in the planters card.'**
  String get churchEditorPlantersImageHelper;

  /// Editor card title for hero and gallery images
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get churchEditorMediaCardTitle;

  /// Editor card subtitle for church media URLs
  ///
  /// In en, this message translates to:
  /// **'Cover photo and gallery'**
  String get churchEditorMediaCardSubtitle;

  /// Label above the pastors Quill editor on the church form
  ///
  /// In en, this message translates to:
  /// **'About the pastors'**
  String get churchEditorPastorsBodyLabel;

  /// Label above the planters Quill editor on the outreach form
  ///
  /// In en, this message translates to:
  /// **'About the church planters'**
  String get churchEditorPlantersBodyLabel;

  /// Primary save button on the church add/edit form
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get churchEditorSave;

  /// App bar title while resolving a post permalink
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get openPostPageTitle;

  /// Progress message while fetching a post from a link
  ///
  /// In en, this message translates to:
  /// **'Loading post…'**
  String get openPostLoading;

  /// Title when a post permalink does not match a post
  ///
  /// In en, this message translates to:
  /// **'Post not found'**
  String get openPostNotFoundTitle;

  /// Explanation when a post permalink cannot be opened
  ///
  /// In en, this message translates to:
  /// **'This post may have been removed, or the link may be incorrect.'**
  String get openPostNotFoundBody;

  /// Title when fetching a post permalink fails
  ///
  /// In en, this message translates to:
  /// **'Could not load post'**
  String get openPostLoadErrorTitle;

  /// Tooltip for the share control on a post body
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharePostTooltip;

  /// App bar title while resolving a person permalink
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get openPersonPageTitle;

  /// Progress message while fetching a profile from a link
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get openPersonLoading;

  /// Title when a person permalink cannot be shown
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get openPersonNotFoundTitle;

  /// Explanation when a person permalink cannot be opened
  ///
  /// In en, this message translates to:
  /// **'This profile may be hidden, or the link may be incorrect.'**
  String get openPersonNotFoundBody;

  /// Title when fetching a person permalink fails
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get openPersonLoadErrorTitle;

  /// Opens the related post from a push notification dialog
  ///
  /// In en, this message translates to:
  /// **'View post'**
  String get notificationViewPost;

  /// Opens the related info page from a push notification dialog
  ///
  /// In en, this message translates to:
  /// **'View page'**
  String get notificationViewPage;

  /// Closes the in-app push notification dialog
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get notificationDismiss;

  /// Empty state title on the post schedule timeline
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled yet'**
  String get scheduleEmptyTitle;

  /// Empty schedule message for authors and contributors
  ///
  /// In en, this message translates to:
  /// **'Add schedule items from the edit menu and they will appear here on the timeline.'**
  String get scheduleEmptyBodyEditor;

  /// Empty schedule message for people who cannot edit the post
  ///
  /// In en, this message translates to:
  /// **'The running order for this post has not been shared yet.'**
  String get scheduleEmptyBodyViewer;

  /// Heading for roles that run for most of the event rather than a slot in the running order
  ///
  /// In en, this message translates to:
  /// **'All event'**
  String get scheduleAllEventSectionTitle;

  /// Shown when tapping an all-event role on the arrange schedule page
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" runs for most of the event, so it stays out of the running order'**
  String scheduleAllEventArrangeHint(String title);

  /// Heading for schedule items that have no start or end time
  ///
  /// In en, this message translates to:
  /// **'Without a time'**
  String get scheduleUntimedSectionTitle;

  /// Shown instead of a time range when a schedule item is untimed
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get scheduleNoTimeSet;

  /// Marks a schedule item that guests cannot see
  ///
  /// In en, this message translates to:
  /// **'Not shown to guests'**
  String get scheduleStaffOnly;

  /// Opens the editor for one schedule item
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get scheduleEditTask;

  /// Marker for schedule items that did not fit in the visible lanes
  ///
  /// In en, this message translates to:
  /// **'+{count} parallel'**
  String scheduleParallelCount(int count);

  /// Title of the sheet listing overlapping schedule items
  ///
  /// In en, this message translates to:
  /// **'Running in parallel'**
  String get scheduleParallelSheetTitle;

  /// Subtitle of the sheet listing overlapping schedule items
  ///
  /// In en, this message translates to:
  /// **'These items overlap others already on the timeline'**
  String get scheduleParallelSheetSubtitle;

  /// Title and button label for the drag-to-rearrange schedule page
  ///
  /// In en, this message translates to:
  /// **'Arrange schedule'**
  String get scheduleArrangeTitle;

  /// Edit sheet subtitle for the arrange schedule action
  ///
  /// In en, this message translates to:
  /// **'Drag items to reorder the running time'**
  String get scheduleArrangeSubtitle;

  /// Keeps the new arrangement and closes the arrange schedule page
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scheduleArrangeDone;

  /// Shown when the arrange schedule page has nothing to lay out
  ///
  /// In en, this message translates to:
  /// **'Add timed schedule items before arranging them.'**
  String get scheduleArrangeEmpty;

  /// Drag mode where later schedule items move out of the way
  ///
  /// In en, this message translates to:
  /// **'Cascade'**
  String get scheduleArrangeModeCascade;

  /// Drag mode where other schedule items keep their times
  ///
  /// In en, this message translates to:
  /// **'Parallel'**
  String get scheduleArrangeModeParallel;

  /// Helper text for cascade drag mode
  ///
  /// In en, this message translates to:
  /// **'Long press an item and drag it. Anything it lands on moves later to keep the running order.'**
  String get scheduleArrangeCascadeHint;

  /// Helper text for parallel drag mode
  ///
  /// In en, this message translates to:
  /// **'Long press an item and drag it. Everything else keeps its time, so items can run at the same time.'**
  String get scheduleArrangeParallelHint;

  /// Snackbar telling the user how to move a schedule item
  ///
  /// In en, this message translates to:
  /// **'Long press \"{title}\" to drag it'**
  String scheduleArrangeDragHint(String title);
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
