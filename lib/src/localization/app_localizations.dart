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

  /// Title on the opening progress screen
  ///
  /// In en, this message translates to:
  /// **'CTRIM'**
  String get startupTitle;

  /// Status shown when the app first opens, before a load step finishes
  ///
  /// In en, this message translates to:
  /// **'Opening CTRIM…'**
  String get startupOpening;

  /// Startup progress after churches, groups, and related catalogues finish loading
  ///
  /// In en, this message translates to:
  /// **'Loading churches and groups…'**
  String get startupCatalogs;

  /// Startup progress after bulletin posts finish loading
  ///
  /// In en, this message translates to:
  /// **'Loading the bulletin…'**
  String get startupPosts;

  /// Startup progress after the people directory finishes loading
  ///
  /// In en, this message translates to:
  /// **'Loading people…'**
  String get startupPeople;

  /// Startup progress while stored credentials sign the user in
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get startupSigningIn;

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

  /// Filter chip for people who serve (leaders, ministries, or cell-group leaders)
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
  /// **'Who\'s Who'**
  String get volunteersMenuTitle;

  /// Personal home menu subtitle for the people directory
  ///
  /// In en, this message translates to:
  /// **'Leaders, ministries, and members'**
  String get volunteersMenuSubtitle;

  /// Personal home section for Who's Who, team rota, and ministries
  ///
  /// In en, this message translates to:
  /// **'People & Teams'**
  String get peopleAndTeamsSectionTitle;

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
  /// **'View Full Schedule'**
  String get personalScheduleViewFull;

  /// Opens full schedule when more than three upcoming posts
  ///
  /// In en, this message translates to:
  /// **'View All {count} Upcoming'**
  String personalScheduleViewAll(int count);

  /// Title for Personal home cell groups dashboard card
  ///
  /// In en, this message translates to:
  /// **'Cell Groups'**
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
  /// **'Browse Cell Groups'**
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

  /// Personal home item and page title for the team serving rota
  ///
  /// In en, this message translates to:
  /// **'Ministry Schedule'**
  String get teamRota;

  /// Personal home subtitle for the team rota page
  ///
  /// In en, this message translates to:
  /// **'What your ministries are down for'**
  String get teamRotaSubtitle;

  /// Date window shown on the team rota page
  ///
  /// In en, this message translates to:
  /// **'Next {months} months'**
  String teamRotaHorizon(int months);

  /// Progress message while fetching dated posts for the team rota
  ///
  /// In en, this message translates to:
  /// **'Loading upcoming posts…'**
  String get teamRotaLoadingHeads;

  /// Progress message while fetching post programmes for the team rota
  ///
  /// In en, this message translates to:
  /// **'Loading programmes…'**
  String get teamRotaLoadingProgrammes;

  /// Error title when the team rota fetch fails
  ///
  /// In en, this message translates to:
  /// **'Could not load ministry schedule'**
  String get teamRotaCouldNotLoad;

  /// Empty state title when filters yield no tagged programme roles
  ///
  /// In en, this message translates to:
  /// **'No ministry slots in this window'**
  String get teamRotaEmptyTitle;

  /// Empty state body when the team rota has no matching slots
  ///
  /// In en, this message translates to:
  /// **'Programme roles for the selected ministries will show here, including slots that still need people. Clear the ministry filters to see every tagged slot. Tap a slot to see who is on it.'**
  String get teamRotaEmptyBody;

  /// Label when a team rota slot has no people yet
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get teamRotaUnassigned;

  /// Section label for location chips on the team rota
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get teamRotaFilterLocation;

  /// Section label for ministry chips on the team rota
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get teamRotaFilterTeams;

  /// App bar button that opens the team rota location and ministry sheet
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get teamRotaFilterTooltip;

  /// Title of the team rota filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter schedule'**
  String get teamRotaFilterSheetTitle;

  /// Subtitle of the team rota filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Choose a location and ministries'**
  String get teamRotaFilterSheetSubtitle;

  /// Clears every selected ministry on the team rota
  ///
  /// In en, this message translates to:
  /// **'Clear ministries'**
  String get teamRotaClearMinistries;

  /// Empty-state button that opens the team rota filter sheet
  ///
  /// In en, this message translates to:
  /// **'Change filter'**
  String get teamRotaChangeFilter;

  /// Expands the remaining programme slots on a team rota post card
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, =1{1 more} other{{count} more}}'**
  String teamRotaShowMore(int count);

  /// Collapses a team rota post card back to its preview slots
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get teamRotaShowFewer;

  /// Count of empty programme slots in the current team rota filters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 slot still needs people} other{{count} slots still need people}}'**
  String teamRotaGaps(int count);

  /// Section label in the team rota filter sheet
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get teamRotaFilterShow;

  /// Filter that keeps only empty programme slots on the team rota
  ///
  /// In en, this message translates to:
  /// **'Needs people'**
  String get teamRotaNeedsPeople;

  /// Explains the Needs people filter on the team rota
  ///
  /// In en, this message translates to:
  /// **'Only slots that still need someone'**
  String get teamRotaNeedsPeopleSubtitle;

  /// Marks a team rota slot the signed-in person is assigned to
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get teamRotaYou;

  /// Opens the people picker for one team rota slot
  ///
  /// In en, this message translates to:
  /// **'Assign people'**
  String get teamRotaAssignPeople;

  /// Confirms before editing people on a slot tagged for more than one ministry
  ///
  /// In en, this message translates to:
  /// **'This slot is shared'**
  String get teamRotaSharedSlotTitle;

  /// Names the ministries that share one programme slot
  ///
  /// In en, this message translates to:
  /// **'This slot is tagged for {ministries}. Saving updates the people for every ministry on it.'**
  String teamRotaSharedSlotBody(String ministries);

  /// Shared-slot confirmation when ministry names are unavailable
  ///
  /// In en, this message translates to:
  /// **'This slot belongs to more than one ministry. Saving updates the people for every ministry on it.'**
  String get teamRotaSharedSlotBodyGeneric;

  /// Progress title while team rota assignments are saved
  ///
  /// In en, this message translates to:
  /// **'Saving lineup'**
  String get teamRotaSavingAssignees;

  /// Error title when a team rota assignment fails to save
  ///
  /// In en, this message translates to:
  /// **'Could not save the lineup'**
  String get teamRotaCouldNotSave;

  /// Shown when the programme role disappeared before the lineup was saved
  ///
  /// In en, this message translates to:
  /// **'That slot is no longer on the post.'**
  String get teamRotaRoleMissing;

  /// Heading for the people who lead the one ministry selected on the team rota
  ///
  /// In en, this message translates to:
  /// **'{ministry} heads'**
  String teamRotaMinistryHeads(String ministry);

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

  /// Profile summary when the person led linked cell group meetings in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Hosted 1 cell group meeting in the past 3 weeks} other{Hosted {count} cell group meetings in the past 3 weeks}}'**
  String userProfileCellGroupMeetingsHostedCount(int count);

  /// Profile summary when the person both hosted and attended as a guest in the past 3 weeks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Took part in 1 cell group meeting in the past 3 weeks} other{Took part in {count} cell group meetings in the past 3 weeks}}'**
  String userProfileCellGroupMeetingsParticipatedCount(int count);

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

  /// Subtitle when the person led the cell group for that meeting
  ///
  /// In en, this message translates to:
  /// **'Hosted'**
  String get userProfileCellGroupMeetingHosted;

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

  /// Section title for recent bulletin posts this person contributes to
  ///
  /// In en, this message translates to:
  /// **'Recent contributor posts'**
  String get userProfileContributorPosts;

  /// Empty state when this person has no contributor posts in the loaded bulletin
  ///
  /// In en, this message translates to:
  /// **'Not a contributor on any posts yet.'**
  String get userProfileNoContributorPosts;

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
  /// **'Clear'**
  String get userTagsFilterClear;

  /// Section label for assigning tags to a volunteer
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get userTagsAssignLabel;

  /// Hint on the programme-role editor that ministries mark slot ownership, not named people
  ///
  /// In en, this message translates to:
  /// **'Which ministries this slot belongs to — separate from who is assigned.'**
  String get userTagsScheduleHint;

  /// Message when no user tags exist for assignment
  ///
  /// In en, this message translates to:
  /// **'No ministries yet. Area admins can add them from View Ministries.'**
  String get userTagsNoneAvailable;

  /// Title for the admin page that manages volunteer tag definitions
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get manageUserTagsTitle;

  /// Action to create a new volunteer tag
  ///
  /// In en, this message translates to:
  /// **'Add ministry'**
  String get manageUserTagsAdd;

  /// Empty state on the manage tags page
  ///
  /// In en, this message translates to:
  /// **'No ministries yet. Add ministries like Worship, Technical, or Usher.'**
  String get manageUserTagsEmpty;

  /// Button to seed default volunteer tags
  ///
  /// In en, this message translates to:
  /// **'Add starter ministries'**
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
  /// **'Name'**
  String get manageUserTagsNameLabel;

  /// Label for the optional tag color picker
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get manageUserTagsColorLabel;

  /// Clears the optional tag color
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get catalogColorNone;

  /// Semantic label for the color picker hue bar
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get catalogColorHue;

  /// Semantic label for the saturation and brightness square
  ///
  /// In en, this message translates to:
  /// **'Shade'**
  String get catalogColorShade;

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
  /// **'Cannot delete — {count} people are still in this ministry. Deactivate it instead.'**
  String manageUserTagsDeleteBlocked(int count);

  /// Personal home admin menu item for managing tags
  ///
  /// In en, this message translates to:
  /// **'View Ministries'**
  String get manageUserTagsMenuTitle;

  /// Personal home admin menu subtitle for managing tags
  ///
  /// In en, this message translates to:
  /// **'Create and edit ministries'**
  String get manageUserTagsMenuSubtitle;

  /// Switch on the ministry editor so guests can see this label
  ///
  /// In en, this message translates to:
  /// **'Visible to guests'**
  String get manageUserTagsVisibleToGuests;

  /// Explains that hiding a ministry only hides the label
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide this label from guests on profiles, schedule details, and View Ministries. People and schedule lines still show.'**
  String get manageUserTagsVisibleToGuestsSubtitle;

  /// Status on the ministry list when guests do not see the label
  ///
  /// In en, this message translates to:
  /// **'Hidden from guests'**
  String get manageUserTagsHiddenFromGuests;

  /// Label for the ministry description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get manageUserTagsDescriptionLabel;

  /// Label for the ministry main graphic URL
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get manageUserTagsImageUrlLabel;

  /// Hint for the ministry main graphic URL
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get manageUserTagsImageUrlHint;

  /// Hint for the ministry description field
  ///
  /// In en, this message translates to:
  /// **'What this ministry does'**
  String get manageUserTagsDescriptionHint;

  /// Admin list note when a ministry has no description
  ///
  /// In en, this message translates to:
  /// **'No description yet'**
  String get manageUserTagsDescriptionMissing;

  /// Personal menu subtitle for the public ministry page
  ///
  /// In en, this message translates to:
  /// **'What each ministry is for'**
  String get userTagsBrowseSubtitle;

  /// Empty state on the ministry page for people who cannot manage tags
  ///
  /// In en, this message translates to:
  /// **'No ministries to show yet.'**
  String get userTagsBrowseEmpty;

  /// Loading message on the ministry page
  ///
  /// In en, this message translates to:
  /// **'Loading ministries…'**
  String get userTagsLoading;

  /// Placeholder on a ministry detail page when there is no description
  ///
  /// In en, this message translates to:
  /// **'More about this ministry will be added here.'**
  String get userTagsDetailEmpty;

  /// Shown when a ministry was removed while its detail page is open
  ///
  /// In en, this message translates to:
  /// **'This ministry is no longer available.'**
  String get userTagsUnavailable;

  /// Heading above the church-location chips on a ministry page
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get userTagDetailLocation;

  /// Shown on a ministry page when there are no active locations
  ///
  /// In en, this message translates to:
  /// **'Church locations are not set up yet, so heads, members, and photos cannot be shown by site.'**
  String get userTagDetailNoLocations;

  /// Section title for department heads at the selected church location
  ///
  /// In en, this message translates to:
  /// **'Heads'**
  String get userTagDetailHeads;

  /// Subtitle under the heads section on a ministry page
  ///
  /// In en, this message translates to:
  /// **'Who leads this ministry at {location}'**
  String userTagDetailHeadsSubtitle(String location);

  /// Empty state when a ministry has no heads at the selected location
  ///
  /// In en, this message translates to:
  /// **'No heads listed for {location} yet.'**
  String userTagDetailHeadsEmpty(String location);

  /// Button for an area admin to pick department heads at one location
  ///
  /// In en, this message translates to:
  /// **'Choose heads'**
  String get userTagDetailChooseHeads;

  /// Section title for people who have this ministry at the selected location
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get userTagDetailMembers;

  /// Subtitle under the members section on a ministry page
  ///
  /// In en, this message translates to:
  /// **'People in this ministry at {location}'**
  String userTagDetailMembersSubtitle(String location);

  /// Empty state when no active people at the location carry the tag
  ///
  /// In en, this message translates to:
  /// **'No one at {location} is in this ministry yet.'**
  String userTagDetailMembersEmpty(String location);

  /// Section title for the ministry photo album at one location
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get userTagDetailGallery;

  /// Subtitle under the photo album on a ministry page
  ///
  /// In en, this message translates to:
  /// **'Photos from {location}'**
  String userTagDetailGallerySubtitle(String location);

  /// Empty photo album shown to area admins on a ministry page
  ///
  /// In en, this message translates to:
  /// **'No photos for {location} yet.'**
  String userTagDetailGalleryEmpty(String location);

  /// Button to add a photo to a ministry album
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get userTagDetailAddPhoto;

  /// Title of the confirmation dialog that removes a ministry photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get userTagDetailRemovePhoto;

  /// Confirmation body before deleting a ministry photo
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from {location}?'**
  String userTagDetailRemovePhotoConfirm(String location);

  /// Shown when someone tries to add a video to a ministry album
  ///
  /// In en, this message translates to:
  /// **'Ministry albums only support images.'**
  String get userTagDetailPhotosImagesOnly;

  /// Shown when a ministry album is at the photo cap
  ///
  /// In en, this message translates to:
  /// **'This location already has the maximum of {count} photos.'**
  String userTagDetailGalleryFull(int count);

  /// Section title for future schedule roles of a ministry
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get userTagDetailUpcoming;

  /// Window shown under upcoming ministry schedule roles
  ///
  /// In en, this message translates to:
  /// **'Next {months} months at {location}'**
  String userTagDetailUpcomingSubtitle(int months, String location);

  /// Section title for past schedule roles of a ministry
  ///
  /// In en, this message translates to:
  /// **'Already done'**
  String get userTagDetailPast;

  /// Window shown under past ministry schedule roles
  ///
  /// In en, this message translates to:
  /// **'Previous {months} months at {location}'**
  String userTagDetailPastSubtitle(int months, String location);

  /// Empty state for future ministry schedule roles
  ///
  /// In en, this message translates to:
  /// **'No upcoming slots for this ministry at {location}.'**
  String userTagDetailScheduleEmptyUpcoming(String location);

  /// Empty state for past ministry schedule roles
  ///
  /// In en, this message translates to:
  /// **'No past slots for this ministry at {location} in this window.'**
  String userTagDetailScheduleEmptyPast(String location);

  /// Progress message while a ministry page loads dated posts
  ///
  /// In en, this message translates to:
  /// **'Loading posts…'**
  String get userTagDetailScheduleLoading;

  /// Progress message while a ministry page loads programme roles
  ///
  /// In en, this message translates to:
  /// **'Loading programmes…'**
  String get userTagDetailScheduleLoadingProgrammes;

  /// Error title when the ministry schedule fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load this ministry\'s schedule'**
  String get userTagDetailScheduleCouldNotLoad;

  /// Shown when saving heads or photos on a ministry fails
  ///
  /// In en, this message translates to:
  /// **'Could not save this ministry. Try again.'**
  String get userTagDetailCouldNotSave;

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

  /// Title for the signed-in page that lists post content tags
  ///
  /// In en, this message translates to:
  /// **'Post Tags'**
  String get managePostTagsTitle;

  /// Action to create a new post content tag
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get managePostTagsAdd;

  /// Empty state on the post tags page for area admins
  ///
  /// In en, this message translates to:
  /// **'No post tags yet. Add labels such as Sunday Worship or Midweek so people can filter the bulletin.'**
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

  /// Label for the optional post tag color picker
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

  /// Personal home menu item for the post tags page
  ///
  /// In en, this message translates to:
  /// **'Post Tags'**
  String get managePostTagsMenuTitle;

  /// Personal home menu subtitle for the post tags page
  ///
  /// In en, this message translates to:
  /// **'Attendance and recent posts'**
  String get managePostTagsMenuSubtitle;

  /// Label for the short post tag description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get managePostTagsDescriptionLabel;

  /// Hint for the short post tag description
  ///
  /// In en, this message translates to:
  /// **'What these posts are for'**
  String get managePostTagsDescriptionHint;

  /// Label for the post tag cover image URL
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get managePostTagsImageUrlLabel;

  /// Hint for the post tag cover image URL
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get managePostTagsImageUrlHint;

  /// Empty state on the post tags page for people who cannot manage tags
  ///
  /// In en, this message translates to:
  /// **'No post tags to show yet.'**
  String get postTagsBrowseEmpty;

  /// Shown when a guest opens the post tags page
  ///
  /// In en, this message translates to:
  /// **'Sign in to view post tags.'**
  String get postTagsSignedInOnly;

  /// Status while the post tags list is loading
  ///
  /// In en, this message translates to:
  /// **'Loading post tags…'**
  String get postTagsLoading;

  /// Section title for post tag event and attendance totals
  ///
  /// In en, this message translates to:
  /// **'By location'**
  String get postTagDetailStatsTitle;

  /// Window shown under post tag location totals
  ///
  /// In en, this message translates to:
  /// **'Already held, and what\'s still ahead'**
  String get postTagDetailStatsSubtitle;

  /// Placeholder when a post tag has no description
  ///
  /// In en, this message translates to:
  /// **'More about this tag will be added here.'**
  String get postTagDetailDescriptionEmpty;

  /// Heading above the location chips on a post tag
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get postTagDetailLocation;

  /// Chip that clears the location filter on a post tag
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get postTagDetailAllLocations;

  /// Section title for past post tag totals
  ///
  /// In en, this message translates to:
  /// **'So far'**
  String get postTagDetailProgressTitle;

  /// Window for past post tag totals across every location
  ///
  /// In en, this message translates to:
  /// **'Past 2 months'**
  String get postTagDetailProgressSubtitle;

  /// Window for past post tag totals at one location
  ///
  /// In en, this message translates to:
  /// **'Past 2 months at {location}'**
  String postTagDetailProgressSubtitleAt(String location);

  /// Explains that upcoming posts are left out of the past totals
  ///
  /// In en, this message translates to:
  /// **'Today and the next 3 weeks are listed under Coming up, and are not part of these totals.'**
  String get postTagDetailProgressFootnote;

  /// Stat tile for how many tagged posts have already been held
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get postTagDetailEventsLabel;

  /// Hint under the events stat on a post tag
  ///
  /// In en, this message translates to:
  /// **'Already held'**
  String get postTagDetailEventsHint;

  /// Stat tile for attendance on a post tag
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get postTagDetailAttendedLabel;

  /// Hint under the attendance stat on a post tag
  ///
  /// In en, this message translates to:
  /// **'Total on these posts'**
  String get postTagDetailAttendedHint;

  /// Stat tile for average attendance on a post tag
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get postTagDetailAverageLabel;

  /// Hint under the average attendance stat on a post tag
  ///
  /// In en, this message translates to:
  /// **'Per event, including none recorded'**
  String get postTagDetailAverageHint;

  /// Compact average attendance on a location row
  ///
  /// In en, this message translates to:
  /// **'avg {value}'**
  String postTagDetailAverageShort(String value);

  /// Stat tile for interest on a post tag
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get postTagDetailInterestedLabel;

  /// Hint under the interested stat on a post tag
  ///
  /// In en, this message translates to:
  /// **'Total on these posts'**
  String get postTagDetailInterestedHint;

  /// Upcoming post count on a location row
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 coming up} other{{count} coming up}}'**
  String postTagDetailComingUp(int count);

  /// Subtitle for the weekly chart on a post tag
  ///
  /// In en, this message translates to:
  /// **'Weekly posts with this tag'**
  String get postTagDetailTrendSubtitle;

  /// Caption under the weekly chart on a post tag
  ///
  /// In en, this message translates to:
  /// **'Weekly · past 2 months'**
  String get postTagDetailTrendWeeklyHint;

  /// Section title for upcoming posts with this tag
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get postTagDetailUpcomingTitle;

  /// Window for upcoming posts with this tag
  ///
  /// In en, this message translates to:
  /// **'Next 3 weeks'**
  String get postTagDetailUpcomingSubtitle;

  /// Window for upcoming posts with this tag at one location
  ///
  /// In en, this message translates to:
  /// **'Next 3 weeks at {location}'**
  String postTagDetailUpcomingSubtitleAt(String location);

  /// Empty state when a post tag has no upcoming posts
  ///
  /// In en, this message translates to:
  /// **'Nothing dated with this tag in the next 3 weeks.'**
  String get postTagDetailUpcomingEmpty;

  /// Section title for past posts with this tag
  ///
  /// In en, this message translates to:
  /// **'Recent posts'**
  String get postTagDetailRecentTitle;

  /// Window for recent posts with this tag
  ///
  /// In en, this message translates to:
  /// **'Past 2 months'**
  String get postTagDetailRecentSubtitle;

  /// Window for recent posts with this tag at one location
  ///
  /// In en, this message translates to:
  /// **'Past 2 months at {location}'**
  String postTagDetailRecentSubtitleAt(String location);

  /// Empty state when a post tag has no past posts
  ///
  /// In en, this message translates to:
  /// **'No dated posts with this tag in the past 2 months.'**
  String get postTagDetailRecentEmpty;

  /// How many posts or speakers are hidden below the preview
  ///
  /// In en, this message translates to:
  /// **'And {count} more'**
  String postTagDetailAndMore(int count);

  /// Section title for people who spoke at posts with this tag
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get postTagDetailSpeakersTitle;

  /// Window for speakers on a post tag
  ///
  /// In en, this message translates to:
  /// **'From the past 2 months'**
  String get postTagDetailSpeakersSubtitle;

  /// Window for speakers on a post tag at one location
  ///
  /// In en, this message translates to:
  /// **'From the past 2 months at {location}'**
  String postTagDetailSpeakersSubtitleAt(String location);

  /// How many recent posts a speaker appeared on
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post} other{{count} posts}}'**
  String postTagDetailSpeakerPosts(int count);

  /// Empty state when a post tag has no dated posts in the activity window
  ///
  /// In en, this message translates to:
  /// **'No dated posts with this tag in this window.'**
  String get postTagDetailEmpty;

  /// Dated post count for one location on a post tag
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String postTagDetailEvents(int count);

  /// Attendance total for one location on a post tag
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attended} other{{count} attended}}'**
  String postTagDetailAttendance(int count);

  /// Status while a post tag's location totals are loading
  ///
  /// In en, this message translates to:
  /// **'Loading tag activity…'**
  String get postTagDetailLoading;

  /// Error title when a post tag's location totals fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load tag activity'**
  String get postTagDetailLoadError;

  /// Shown when a post tag was removed before its page finished opening
  ///
  /// In en, this message translates to:
  /// **'This post tag is no longer available.'**
  String get postTagDetailUnavailable;

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
  /// **'Names and cover photos'**
  String get manageUserLocationsMenuSubtitle;

  /// Menu item and section title for a location photo gallery
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get manageUserLocationsPhotos;

  /// Hint under the location photos section
  ///
  /// In en, this message translates to:
  /// **'Add photos for this place. The cover appears on the locations list and at the top of Who\'s Who when this location is selected.'**
  String get manageUserLocationsPhotosHint;

  /// Empty state for a location photo gallery
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get manageUserLocationsPhotosEmpty;

  /// Button to add a photo to a location
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get manageUserLocationsAddPhoto;

  /// Label for the location photo chosen as the cover
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get manageUserLocationsCoverPhoto;

  /// Hint on a location photo that is not the cover
  ///
  /// In en, this message translates to:
  /// **'Tap to set as cover'**
  String get manageUserLocationsSetAsCover;

  /// SnackBar when a video is added to a location
  ///
  /// In en, this message translates to:
  /// **'Locations only support images for now.'**
  String get manageUserLocationsPhotosImagesOnly;

  /// Tooltip for removing a location photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get manageUserLocationsRemovePhoto;

  /// Title shown for a location photo that has no caption
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get manageUserLocationsPhotoFallback;

  /// Empty state when tag filter returns no people
  ///
  /// In en, this message translates to:
  /// **'No people match the selected ministries'**
  String get volunteersEmptyTags;

  /// Title for the multi-select people picker page
  ///
  /// In en, this message translates to:
  /// **'Select people'**
  String get selectUsersTitle;

  /// Subtitle for the people picker refine sheet
  ///
  /// In en, this message translates to:
  /// **'Location, ministry, or who is shown'**
  String get selectUsersFilterSheetSubtitle;

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

  /// Select every person currently matching the active tag filter on the people picker
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectUsersSelectAll;

  /// Unselect every person currently matching the active tag filter on the people picker
  ///
  /// In en, this message translates to:
  /// **'Unselect all'**
  String get selectUsersUnselectAll;

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

  /// Button that copies the linked account email on edit user
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get editUserCopyEmail;

  /// Confirmation after copying a user's email on edit user
  ///
  /// In en, this message translates to:
  /// **'Email copied'**
  String get editUserEmailCopied;

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

  /// Sort people by primary ministry
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
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
  /// **'Ministry'**
  String get volunteersFilterTags;

  /// Tag filter button when one or more tags are selected
  ///
  /// In en, this message translates to:
  /// **'Ministry ({count})'**
  String volunteersFilterTagsCount(int count);

  /// Title for the volunteer tag filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter by ministry'**
  String get volunteersFilterTagsSheetTitle;

  /// Subtitle for the volunteer tag filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Show people in any of these ministries'**
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
  /// **'Location, sort, role, ministry, or who is shown'**
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
  /// **'People who serve in a ministry or lead groups'**
  String get volunteersFilterServingSubtitle;

  /// Section label for role filters in the people directory
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get volunteersFilterRolesSection;

  /// Section label for ministry filters in the people directory
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get volunteersFilterTeamsSection;

  /// Count label above the people directory list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String volunteersShowingCount(int count);

  /// Short intro on the people directory
  ///
  /// In en, this message translates to:
  /// **'Browse leaders and ministry members in the church family.'**
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

  /// Title of the Cell Groups overview teaching card
  ///
  /// In en, this message translates to:
  /// **'What a meeting is like'**
  String get cellGroupsMeetingLikeTitle;

  /// First point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Bible study'**
  String get cellGroupsMeetingLikeBibleTitle;

  /// Body for the Bible study point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Read and talk through Scripture together'**
  String get cellGroupsMeetingLikeBibleBody;

  /// Second point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Care and prayer'**
  String get cellGroupsMeetingLikeCareTitle;

  /// Body for the care and prayer point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Look after one another and pray'**
  String get cellGroupsMeetingLikeCareBody;

  /// Third point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Fellowship'**
  String get cellGroupsMeetingLikeFellowshipTitle;

  /// Body for the fellowship point on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Share life in a small gathering, often in a home'**
  String get cellGroupsMeetingLikeFellowshipBody;

  /// Title of the Cell Groups overview find card
  ///
  /// In en, this message translates to:
  /// **'Find a group'**
  String get cellGroupsFindTitle;

  /// Hint under the browse action on the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Search by name or a postcode such as BT9.'**
  String get cellGroupsFindHint;

  /// Button that opens the Groups tab from the Cell Groups overview
  ///
  /// In en, this message translates to:
  /// **'Browse groups'**
  String get cellGroupsFindBrowse;

  /// Heading above the signed-in person's cell groups on the overview
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your group} other{Your groups}}'**
  String cellGroupsFindMembershipHeading(int count);

  /// Title for the Cell Groups overview activity card, shown to people who serve
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get cellGroupsActivityTitle;

  /// Subtitle under the Cell Groups overview activity card
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

  /// Secondary metric label shown when some groups are paused
  ///
  /// In en, this message translates to:
  /// **'Paused groups'**
  String get cellGroupsActivityPausedGroupsLabel;

  /// Secondary metric label for average attendees per past meeting
  ///
  /// In en, this message translates to:
  /// **'Avg attendance · past 3 weeks'**
  String get cellGroupsActivityAvgAttendanceLabel;

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

  /// Title for the Cell Groups overview weekly activity chart
  ///
  /// In en, this message translates to:
  /// **'Meetings over time'**
  String get cellGroupsActivityTrendTitle;

  /// Subtitle for the Cell Groups overview weekly activity chart
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

  /// Empty state when the Groups list is filtered to a church location
  ///
  /// In en, this message translates to:
  /// **'No cell groups at {location} yet.'**
  String cellGroupsEmptyLocation(String location);

  /// App bar title for the Groups catalogue filtered to one church location
  ///
  /// In en, this message translates to:
  /// **'{location} cell groups'**
  String cellGroupsAtLocationTitle(String location);

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

  /// Starts a new meeting post from the cell group page
  ///
  /// In en, this message translates to:
  /// **'Add meeting'**
  String get cellGroupsAddMeeting;

  /// Area-admin action when the group has no parent post or meeting template yet
  ///
  /// In en, this message translates to:
  /// **'Set up meeting posts'**
  String get cellGroupsSetupMeetingPosts;

  /// Caption under Recent meetings naming the period parent
  ///
  /// In en, this message translates to:
  /// **'Adds a meeting under {title}'**
  String cellGroupsMeetingParentCaption(String title);

  /// Shown when the stored parent post id no longer exists
  ///
  /// In en, this message translates to:
  /// **'The parent post for new meetings could not be found.'**
  String get cellGroupsMeetingParentMissing;

  /// Shown when the stored parent is no longer marked as a period parent
  ///
  /// In en, this message translates to:
  /// **'That parent post is no longer a period parent.'**
  String get cellGroupsMeetingParentNotPeriod;

  /// Shown when the parent post title fetch fails
  ///
  /// In en, this message translates to:
  /// **'The parent post title could not be loaded.'**
  String get cellGroupsMeetingParentLookupFailed;

  /// Shown on the edit form when a stored title cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Could not look this up. Try again.'**
  String get cellGroupsMeetingLookupFailed;

  /// Alert when Add meeting cannot load the stored template
  ///
  /// In en, this message translates to:
  /// **'The meeting template for this group could not be found. An area admin can choose another on the group.'**
  String get cellGroupsMeetingTemplateMissing;

  /// Progress title while verifying parent post and template
  ///
  /// In en, this message translates to:
  /// **'Checking the meeting setup…'**
  String get cellGroupsAddMeetingChecking;

  /// Section title on the edit cell group page
  ///
  /// In en, this message translates to:
  /// **'Meeting posts'**
  String get cellGroupsMeetingPostsTitle;

  /// Explains the parent post and template fields
  ///
  /// In en, this message translates to:
  /// **'Leaders can add a meeting from this group\'s page when both are set.'**
  String get cellGroupsMeetingPostsHelper;

  /// Field label for the current period parent
  ///
  /// In en, this message translates to:
  /// **'Parent post'**
  String get cellGroupsMeetingParentLabel;

  /// Helper for the parent post field
  ///
  /// In en, this message translates to:
  /// **'New meetings are filed under this period parent.'**
  String get cellGroupsMeetingParentHelper;

  /// Empty value for the parent post field
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cellGroupsMeetingParentNotSet;

  /// Alert title when the chosen parent cannot be used
  ///
  /// In en, this message translates to:
  /// **'Parent post'**
  String get cellGroupsMeetingParentInvalidTitle;

  /// Field label and picker title for the meeting template
  ///
  /// In en, this message translates to:
  /// **'Meeting template'**
  String get cellGroupsMeetingTemplateLabel;

  /// Helper for the meeting template field
  ///
  /// In en, this message translates to:
  /// **'New meetings use this template. Link this group on the template so they also appear when someone starts from the template.'**
  String get cellGroupsMeetingTemplateHelper;

  /// Empty value for the meeting template field
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cellGroupsMeetingTemplateNotSet;

  /// Alert title when the chosen template cannot be used
  ///
  /// In en, this message translates to:
  /// **'Meeting template'**
  String get cellGroupsMeetingTemplateInvalidTitle;

  /// Alert when the stored or chosen template is missing
  ///
  /// In en, this message translates to:
  /// **'That meeting template could not be found.'**
  String get cellGroupsMeetingTemplateInvalid;

  /// Placeholder while a stored parent or template title is loading
  ///
  /// In en, this message translates to:
  /// **'Looking up…'**
  String get cellGroupsMeetingLookingUp;

  /// Confirm title when the template does not list this cell group
  ///
  /// In en, this message translates to:
  /// **'Template is not linked to this group'**
  String get cellGroupsMeetingTemplateUnlinkedTitle;

  /// Confirm body when saving a template that does not list this group
  ///
  /// In en, this message translates to:
  /// **'Meetings added from this group will still show in Recent meetings. Meetings started from the template elsewhere will not, until the template lists this group.'**
  String get cellGroupsMeetingTemplateUnlinkedBody;

  /// Access denied on the meeting template picker
  ///
  /// In en, this message translates to:
  /// **'Only area admins can choose a meeting template.'**
  String get cellGroupsMeetingTemplateDenied;

  /// Progress message on the meeting template picker
  ///
  /// In en, this message translates to:
  /// **'Loading templates…'**
  String get cellGroupsMeetingTemplateLoading;

  /// Error title on the meeting template picker
  ///
  /// In en, this message translates to:
  /// **'Could not load templates'**
  String get cellGroupsMeetingTemplateLoadFailed;

  /// Search hint on the meeting template picker
  ///
  /// In en, this message translates to:
  /// **'Search templates'**
  String get cellGroupsMeetingTemplateSearch;

  /// Subtitle for clearing the meeting template
  ///
  /// In en, this message translates to:
  /// **'New meetings will not use a template'**
  String get cellGroupsMeetingTemplateClearHint;

  /// Empty search on the meeting template picker
  ///
  /// In en, this message translates to:
  /// **'No templates match.'**
  String get cellGroupsMeetingTemplateEmpty;

  /// Badge when a template already lists this cell group
  ///
  /// In en, this message translates to:
  /// **'Linked to this group'**
  String get cellGroupsMeetingTemplateLinked;

  /// Confirms a cell group picker
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cellGroupsPickerDone;

  /// Clears the parent post or meeting template
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cellGroupsMeetingClear;

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
  /// **'Regular members'**
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
  /// **'Shown on the catalogue card and in About.'**
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

  /// Card title for location, postcode, weekday, and time on edit cell group
  ///
  /// In en, this message translates to:
  /// **'When and where'**
  String get cellGroupsEditorWhenWhereTitle;

  /// Shown when a cell group leader profile cannot be found
  ///
  /// In en, this message translates to:
  /// **'Unknown leader'**
  String get cellGroupsUnknownLeader;

  /// Tooltip to remove a photo or leader while editing a cell group
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cellGroupsRemove;

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

  /// Bulletin sort: newest create/edit activity first
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get bulletinSortRecent;

  /// Explains recently-updated sort
  ///
  /// In en, this message translates to:
  /// **'Newest creates and edits first'**
  String get bulletinSortRecentSubtitle;

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

  /// Filter the bulletin to posts without an event date
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get bulletinShowUndated;

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

  /// App bar title for the personal My Posts page
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPostsTitle;

  /// Help dialog title on My Posts
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPostsHelpTitle;

  /// Help dialog body explaining My Posts
  ///
  /// In en, this message translates to:
  /// **'Posts where you are the author or a contributor appear here — handy for finding posts you can edit.\n\nUse sort and filter to narrow by date, location, or tags. The list defaults to recently updated.'**
  String get myPostsHelpBody;

  /// Empty state when the user has no editable posts
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get myPostsEmptyTitle;

  /// Empty state body when My Posts has no involvements
  ///
  /// In en, this message translates to:
  /// **'When you create or contribute to a post, it will show up here.'**
  String get myPostsEmptyBody;

  /// Status while My Posts fetches involvement list
  ///
  /// In en, this message translates to:
  /// **'Loading posts…'**
  String get myPostsLoading;

  /// Step status while loading My Posts
  ///
  /// In en, this message translates to:
  /// **'Fetching posts…'**
  String get myPostsFetching;

  /// Step status while pruning stale My Posts entries
  ///
  /// In en, this message translates to:
  /// **'Cleaning up posts…'**
  String get myPostsCleaning;

  /// Final step status after My Posts load
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get myPostsDone;

  /// Error title when My Posts fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load posts'**
  String get myPostsLoadError;

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

  /// Opens the Groups catalogue filtered to this church location
  ///
  /// In en, this message translates to:
  /// **'View all {count} cell groups'**
  String churchHubViewAllCellGroups(int count);

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

  /// Button on the church hub location card that opens location statistics
  ///
  /// In en, this message translates to:
  /// **'See statistics'**
  String get churchHubSeeStatistics;

  /// App bar title for the church location statistics page
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get churchLocationStatsTitle;

  /// Progress message while church location statistics load
  ///
  /// In en, this message translates to:
  /// **'Loading statistics…'**
  String get churchLocationStatsLoading;

  /// Section title for people at a church location
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get churchLocationStatsPeopleTitle;

  /// Section subtitle for people at a church location
  ///
  /// In en, this message translates to:
  /// **'Profiles at this location'**
  String get churchLocationStatsPeopleSubtitle;

  /// Empty state when a church location has no profiles
  ///
  /// In en, this message translates to:
  /// **'No profiles at this location yet.'**
  String get churchLocationStatsPeopleEmpty;

  /// Count tile for people at this location who are in a ministry
  ///
  /// In en, this message translates to:
  /// **'In a ministry'**
  String get churchLocationStatsInMinistry;

  /// Hint under the in-a-ministry count
  ///
  /// In en, this message translates to:
  /// **'At least one ministry'**
  String get churchLocationStatsInMinistryHint;

  /// Count tile for people at this location with no ministry
  ///
  /// In en, this message translates to:
  /// **'Not in a ministry'**
  String get churchLocationStatsNotInMinistry;

  /// Hint under the not-in-a-ministry count
  ///
  /// In en, this message translates to:
  /// **'No ministry listed'**
  String get churchLocationStatsNotInMinistryHint;

  /// Count tile for leaders at this church location
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get churchLocationStatsLeaders;

  /// Hint under the leaders count. Area admin counts as a leader.
  ///
  /// In en, this message translates to:
  /// **'Leader or area admin'**
  String get churchLocationStatsLeadersHint;

  /// Footnote under the ministry counts on location statistics
  ///
  /// In en, this message translates to:
  /// **'A person in more than one ministry is counted in each.'**
  String get churchLocationStatsMinistryHint;

  /// Count tile for the sum of cell group member counts at a location
  ///
  /// In en, this message translates to:
  /// **'Members listed'**
  String get churchLocationStatsMembersListed;

  /// Hint under the members listed count
  ///
  /// In en, this message translates to:
  /// **'Across these groups'**
  String get churchLocationStatsMembersListedHint;

  /// Count tile for average cell group size at a location
  ///
  /// In en, this message translates to:
  /// **'Average size'**
  String get churchLocationStatsAverageSize;

  /// Hint under the average cell group size
  ///
  /// In en, this message translates to:
  /// **'Members listed per group'**
  String get churchLocationStatsAverageSizeHint;

  /// Footnote under cell group member totals on location statistics
  ///
  /// In en, this message translates to:
  /// **'Someone in more than one group is counted in each.'**
  String get churchLocationStatsGroupsDoubleCount;

  /// Count tile for posts linked to a cell group
  ///
  /// In en, this message translates to:
  /// **'Cell group meetings'**
  String get churchLocationStatsMeetings;

  /// Hint under the cell group meetings count
  ///
  /// In en, this message translates to:
  /// **'Posts linked to a group'**
  String get churchLocationStatsMeetingsHint;

  /// Count tile for posts not linked to a cell group
  ///
  /// In en, this message translates to:
  /// **'Other posts'**
  String get churchLocationStatsOtherPosts;

  /// Hint under the other posts count
  ///
  /// In en, this message translates to:
  /// **'Not linked to a group'**
  String get churchLocationStatsOtherPostsHint;

  /// Count tile for total attendance on location posts
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get churchLocationStatsAttendance;

  /// Hint under the attendance total
  ///
  /// In en, this message translates to:
  /// **'Total on these posts'**
  String get churchLocationStatsAttendanceHint;

  /// Count tile for average attendance on location posts
  ///
  /// In en, this message translates to:
  /// **'Average attendance'**
  String get churchLocationStatsAverageAttendance;

  /// Hint under the average attendance. Posts with no attendance still count.
  ///
  /// In en, this message translates to:
  /// **'Per post, including none recorded'**
  String get churchLocationStatsAverageAttendanceHint;

  /// Count tile for total interested count on location posts
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get churchLocationStatsInterested;

  /// Hint under the interested total
  ///
  /// In en, this message translates to:
  /// **'Total on these posts'**
  String get churchLocationStatsInterestedHint;

  /// Row for posts at this location with no post tag
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get churchLocationStatsNoTag;

  /// Footnote under post tag counts on location statistics
  ///
  /// In en, this message translates to:
  /// **'A post with more than one tag is counted in each.'**
  String get churchLocationStatsPostTagHint;

  /// Posts card subtitle. The last 3 months and the 7-day upcoming window are separate.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months and the coming week'**
  String get churchLocationStatsPostsSubtitle;

  /// Heading for posts in the coming week on location statistics
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get churchLocationStatsUpcomingTitle;

  /// Count tile for posts in the coming week at this location
  ///
  /// In en, this message translates to:
  /// **'Upcoming posts'**
  String get churchLocationStatsUpcomingPosts;

  /// Same window as cell-group activity: today and the next 6 days
  ///
  /// In en, this message translates to:
  /// **'Today + next 6 days'**
  String get churchLocationStatsUpcomingPostsHint;

  /// Explains that upcoming posts stay out of the 90-day attendance average, and that today sits in both windows
  ///
  /// In en, this message translates to:
  /// **'Not added into the attendance average. A post today is also counted in the last 3 months.'**
  String get churchLocationStatsUpcomingFootnote;

  /// Chart subtitle on location statistics so the weekly chart is not read as the coming week
  ///
  /// In en, this message translates to:
  /// **'Last 3 months at this location'**
  String get churchLocationStatsTrendSubtitle;

  /// Count tile for distinct people across cell groups at this location
  ///
  /// In en, this message translates to:
  /// **'Different people'**
  String get churchLocationStatsUniquePeople;

  /// Hint under the distinct cell-group people count. Signed-in viewers only.
  ///
  /// In en, this message translates to:
  /// **'Each person once'**
  String get churchLocationStatsUniquePeopleHint;

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

  /// Heading for the pastors and church history section on a church hub
  ///
  /// In en, this message translates to:
  /// **'Pastors & History'**
  String get churchHubPastorsTitle;

  /// Heading for church planters and outreach history on an outreach hub
  ///
  /// In en, this message translates to:
  /// **'Planters & History'**
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

  /// Dashboard card subtitle for the pastors and history card
  ///
  /// In en, this message translates to:
  /// **'The team and the story of this church'**
  String get churchHubPastorsSubtitle;

  /// Dashboard card subtitle for planters and history on an outreach
  ///
  /// In en, this message translates to:
  /// **'The team and the story of this outreach'**
  String get churchHubPlantersSubtitle;

  /// Button on the church hub pastors card that opens the pastors and history page
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get churchHubLearnAboutPastors;

  /// Button on the outreach hub that opens the planters and history write-up
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get churchHubLearnAboutPlanters;

  /// App bar title for the church pastors and history write-up page
  ///
  /// In en, this message translates to:
  /// **'Pastors & History'**
  String get churchPastorsPageTitle;

  /// App bar title for the outreach planters and history write-up page
  ///
  /// In en, this message translates to:
  /// **'Planters & History'**
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

  /// Editor card title for outreach name and summary
  ///
  /// In en, this message translates to:
  /// **'Outreach'**
  String get churchEditorOutreachCardTitle;

  /// Label for the optional line under a church title
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get churchEditorSummaryLabel;

  /// Helper for a full church subtitle field
  ///
  /// In en, this message translates to:
  /// **'Shown under the title. Leave blank for the title only.'**
  String get churchEditorSummaryHelperChurch;

  /// Helper for an outreach subtitle field
  ///
  /// In en, this message translates to:
  /// **'Shown under the title. Leave blank to name the parent church.'**
  String get churchEditorSummaryHelperOutreach;

  /// Editor card for church vs outreach and parent
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get churchEditorStatusCardTitle;

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
  /// **'No catalogue location until this is a full church.'**
  String get churchEditorOutreachLocationHint;

  /// Address field label on church editor
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get churchEditorAddressLabel;

  /// Maps URL field label on church editor
  ///
  /// In en, this message translates to:
  /// **'Maps URL'**
  String get churchEditorMapsLabel;

  /// Tooltip for maps URL help button
  ///
  /// In en, this message translates to:
  /// **'Maps URL help'**
  String get churchEditorMapsHelpTooltip;

  /// Helper under the church location preview
  ///
  /// In en, this message translates to:
  /// **'Pin starts at the postcode. Adjust it if the building is nearby.'**
  String get churchEditorPinHint;

  /// Button that opens the church pin editor
  ///
  /// In en, this message translates to:
  /// **'Adjust pin'**
  String get churchEditorAdjustPin;

  /// Title of the church pin dialog
  ///
  /// In en, this message translates to:
  /// **'Adjust pin'**
  String get churchEditorAdjustPinTitle;

  /// Instructions in the church pin dialog
  ///
  /// In en, this message translates to:
  /// **'Move the map, then tap where the building is.'**
  String get churchEditorAdjustPinHelp;

  /// Shown when the address postcode is not in the lookup
  ///
  /// In en, this message translates to:
  /// **'That postcode could not be found. Check the address and try again.'**
  String get churchEditorPostcodeInvalid;

  /// Shown when the address postcode lookup fails
  ///
  /// In en, this message translates to:
  /// **'Could not place the pin. Check your connection and try again.'**
  String get churchEditorPostcodeLookupFailed;

  /// Caption under a single cell-group area map
  ///
  /// In en, this message translates to:
  /// **'Approximate area'**
  String get mapApproximateArea;

  /// Caption under the nearest cell-groups map
  ///
  /// In en, this message translates to:
  /// **'Approximate areas'**
  String get mapApproximateAreas;

  /// Tappable corner credit on embedded maps
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap'**
  String get mapAttribution;

  /// Shown when map tiles fail to load
  ///
  /// In en, this message translates to:
  /// **'Map could not be loaded.'**
  String get mapLoadFailed;

  /// Retry button when a map fails to load
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mapRetry;

  /// Editor card title for location, address, and maps
  ///
  /// In en, this message translates to:
  /// **'Find us'**
  String get churchEditorVisitCardTitle;

  /// Editor card title for church social links
  ///
  /// In en, this message translates to:
  /// **'Socials'**
  String get churchEditorSocialsCardTitle;

  /// Empty hint on church socials editor card
  ///
  /// In en, this message translates to:
  /// **'No social links yet.'**
  String get churchEditorSocialsEmptyHint;

  /// Button to add a social link on the church editor
  ///
  /// In en, this message translates to:
  /// **'Add social link'**
  String get churchEditorAddSocial;

  /// Tooltip to remove a social link row
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get churchEditorRemoveSocial;

  /// Dropdown label for social platform
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get churchEditorSocialPlatformLabel;

  /// URL field label for a social link
  ///
  /// In en, this message translates to:
  /// **'Link or email'**
  String get churchEditorSocialUrlLabel;

  /// Dashboard card title for church social links
  ///
  /// In en, this message translates to:
  /// **'Socials'**
  String get churchHubSocialsTitle;

  /// Dashboard card subtitle for church social links
  ///
  /// In en, this message translates to:
  /// **'Follow and get in touch'**
  String get churchHubSocialsSubtitle;

  /// Label for Facebook social platform
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get churchSocialFacebook;

  /// Label for Instagram social platform
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get churchSocialInstagram;

  /// Label for YouTube social platform
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get churchSocialYoutube;

  /// Label for X / Twitter social platform
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get churchSocialX;

  /// Label for TikTok social platform
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get churchSocialTiktok;

  /// Label for WhatsApp social platform
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get churchSocialWhatsapp;

  /// Label for website social platform
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get churchSocialWebsite;

  /// Label for email social platform
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get churchSocialEmail;

  /// Label for a generic social / web link
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get churchSocialOther;

  /// Editor card title for pastors, photo, and history write-up
  ///
  /// In en, this message translates to:
  /// **'Pastors & History'**
  String get churchEditorPastorsCardTitle;

  /// Editor card title for planters and history on an outreach
  ///
  /// In en, this message translates to:
  /// **'Planters & History'**
  String get churchEditorPlantersCardTitle;

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

  /// Label for planters team photo URL
  ///
  /// In en, this message translates to:
  /// **'Planters image URL'**
  String get churchEditorPlantersImageLabel;

  /// Editor card title for hero and gallery images
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get churchEditorMediaCardTitle;

  /// Label above the pastors and history Quill editor on the church form
  ///
  /// In en, this message translates to:
  /// **'About the pastors and this church'**
  String get churchEditorPastorsBodyLabel;

  /// Label above the planters and history Quill editor on the outreach form
  ///
  /// In en, this message translates to:
  /// **'About the planters and this outreach'**
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

  /// Tooltip for the share control on an open post
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharePostTooltip;

  /// Title of the sheet that shares an open post
  ///
  /// In en, this message translates to:
  /// **'Share post'**
  String get sharePostSheetTitle;

  /// Subtitle of the open-post share sheet
  ///
  /// In en, this message translates to:
  /// **'Send the link, or the write-up'**
  String get sharePostSheetSubtitle;

  /// Action that shares only the post address
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get sharePostLinkTitle;

  /// Explains that Share link sends the permalink
  ///
  /// In en, this message translates to:
  /// **'The address for this post'**
  String get sharePostLinkSubtitle;

  /// Action that shares the About text of a post
  ///
  /// In en, this message translates to:
  /// **'Share the write-up'**
  String get sharePostWriteUpTitle;

  /// Explains what the write-up share includes
  ///
  /// In en, this message translates to:
  /// **'Title, link, and the About text'**
  String get sharePostWriteUpSubtitle;

  /// Confirmation after the post address is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get sharePostLinkCopied;

  /// Title of the dialog that copies a post write-up
  ///
  /// In en, this message translates to:
  /// **'Share post'**
  String get sharePostCopyDialogTitle;

  /// Explains the clipboard fallback when sharing a write-up
  ///
  /// In en, this message translates to:
  /// **'Your browser may not support native sharing but you can still copy the content to your clipboard:'**
  String get sharePostCopyDialogMessage;

  /// Confirmation after a post write-up is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get sharePostCopied;

  /// Button that copies the post write-up
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get sharePostCopyAction;

  /// Fallback text when the About body cannot be turned into plain text
  ///
  /// In en, this message translates to:
  /// **'Unable to extract post content'**
  String get sharePostExtractFailed;

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

  /// A schedule role that covers the post rather than one timed slot. Also the time line when that role has no call time.
  ///
  /// In en, this message translates to:
  /// **'Whole event'**
  String get scheduleWholeEventLabel;

  /// Explains the Whole event switch on the schedule role editor
  ///
  /// In en, this message translates to:
  /// **'On for this post, not one turn in the running order. Leave both times empty, or set a start and leave the finish empty.'**
  String get scheduleWholeEventHint;

  /// Optional expected start for a whole-event schedule role
  ///
  /// In en, this message translates to:
  /// **'Call time'**
  String get scheduleCallTimeLabel;

  /// Optional finish for a whole-event schedule role. Leave empty when the duty runs to the end of the post.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get scheduleCallTimeFinishLabel;

  /// Clears the start or finish on a schedule role
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get scheduleClearTime;

  /// Empty optional schedule time on a whole-event role
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get scheduleTimeOptional;

  /// Whole-event schedule role that has a start and no finish
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String scheduleStartsAt(String time);

  /// Adds the people already assigned to another schedule line that shares a ministry
  ///
  /// In en, this message translates to:
  /// **'Use {title}'**
  String scheduleUseAssignees(String title);

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

  /// Setting that lets people who are not signed in see this person's full surname
  ///
  /// In en, this message translates to:
  /// **'Full Surname for Guests'**
  String get showFullSurnameToGuestsTitle;

  /// Explains the guest surname setting. Off shows a first name and initial.
  ///
  /// In en, this message translates to:
  /// **'People who are not signed in see your first name and surname initial, unless this is on.'**
  String get showFullSurnameToGuestsSubtitle;

  /// Guest surname setting is enabled
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get showFullSurnameToGuestsOn;

  /// Guest surname setting is disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get showFullSurnameToGuestsOff;

  /// Shown when saving the guest surname setting fails
  ///
  /// In en, this message translates to:
  /// **'Could not update that setting. Try again.'**
  String get showFullSurnameToGuestsSaveFailed;

  /// Snackbar telling the user how to move a schedule item
  ///
  /// In en, this message translates to:
  /// **'Long press \"{title}\" to drag it'**
  String scheduleArrangeDragHint(String title);

  /// Personal admin menu item for repeating post reminders
  ///
  /// In en, this message translates to:
  /// **'Scheduled Notifications'**
  String get notificationSchedulesMenuTitle;

  /// Personal admin menu subtitle for scheduled notifications
  ///
  /// In en, this message translates to:
  /// **'Reminders from tagged posts'**
  String get notificationSchedulesMenuSubtitle;

  /// Title of the scheduled notifications hub
  ///
  /// In en, this message translates to:
  /// **'Scheduled Notifications'**
  String get notificationSchedulesTitle;

  /// Empty state title on the scheduled notifications hub
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get notificationSchedulesEmptyTitle;

  /// Empty state body on the scheduled notifications hub
  ///
  /// In en, this message translates to:
  /// **'Add a reminder for a post tag at one location. The next matching post is sent on its own.'**
  String get notificationSchedulesEmptyBody;

  /// Button to create a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get notificationSchedulesAdd;

  /// Title of the sheet for a new scheduled notification
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get notificationSchedulesAddTitle;

  /// Title of the sheet for an existing scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get notificationSchedulesEditTitle;

  /// Subtitle of the scheduled notification editor
  ///
  /// In en, this message translates to:
  /// **'One post tag at one location. The next matching post is sent to that site, showing the post title and subtitle.'**
  String get notificationSchedulesEditSubtitle;

  /// Saves a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get notificationSchedulesSave;

  /// Progress title while a scheduled notification is saved
  ///
  /// In en, this message translates to:
  /// **'Saving reminder'**
  String get notificationSchedulesSaving;

  /// Deletes a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationSchedulesDelete;

  /// Confirmation title before deleting a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get notificationSchedulesDeleteTitle;

  /// Confirmation body before deleting a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'It will stop sending. Posts that already went out are unchanged.'**
  String get notificationSchedulesDeleteBody;

  /// Progress title while a scheduled notification is deleted
  ///
  /// In en, this message translates to:
  /// **'Deleting reminder'**
  String get notificationSchedulesDeleting;

  /// Label for the post tag on a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Post tag'**
  String get notificationSchedulesTagLabel;

  /// Label for the location on a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get notificationSchedulesLocationLabel;

  /// Label for the timing choice on a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'When to send'**
  String get notificationSchedulesTimingLabel;

  /// Timing choice: the day before the event
  ///
  /// In en, this message translates to:
  /// **'Day before'**
  String get notificationSchedulesTimingDayBefore;

  /// Timing choice: the morning of the event
  ///
  /// In en, this message translates to:
  /// **'Morning of'**
  String get notificationSchedulesTimingMorningOf;

  /// Timing choice: a number of hours before the start
  ///
  /// In en, this message translates to:
  /// **'Hours before'**
  String get notificationSchedulesTimingHoursBefore;

  /// Card summary for a day-before reminder
  ///
  /// In en, this message translates to:
  /// **'Day before at {time}'**
  String notificationSchedulesTimingDayBeforeAt(String time);

  /// Card summary for a morning-of reminder
  ///
  /// In en, this message translates to:
  /// **'Morning of the event at {time}'**
  String notificationSchedulesTimingMorningAt(String time);

  /// Card summary for an hours-before reminder
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour before the start} other{{hours} hours before the start}}'**
  String notificationSchedulesTimingHours(int hours);

  /// Label for the Europe/London clock time on a reminder
  ///
  /// In en, this message translates to:
  /// **'Time (UK)'**
  String get notificationSchedulesClockLabel;

  /// Label for how many hours before the event to send
  ///
  /// In en, this message translates to:
  /// **'Hours before the start'**
  String get notificationSchedulesHoursLabel;

  /// Validation message for the hours-before field
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to 48.'**
  String get notificationSchedulesHoursInvalid;

  /// Who receives a scheduled notification
  ///
  /// In en, this message translates to:
  /// **'Sends to {audience}'**
  String notificationSchedulesAudience(String audience);

  /// The next post a reminder will announce
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String notificationSchedulesNext(String title);

  /// When the next reminder will be sent
  ///
  /// In en, this message translates to:
  /// **'Sends {when}'**
  String notificationSchedulesSendsAt(String when);

  /// Shown when a morning-of clock is after the event start
  ///
  /// In en, this message translates to:
  /// **'This post starts before the chosen time, so it will not be sent.'**
  String get notificationSchedulesMorningAfterStart;

  /// Shown when a reminder has no matching post in the next two weeks
  ///
  /// In en, this message translates to:
  /// **'No upcoming post with this tag at this location.'**
  String get notificationSchedulesNoUpcoming;

  /// When this reminder last sent
  ///
  /// In en, this message translates to:
  /// **'Last sent {when}'**
  String notificationSchedulesLastSent(String when);

  /// Error from the last attempt to send this reminder
  ///
  /// In en, this message translates to:
  /// **'Last send failed: {error}'**
  String notificationSchedulesLastError(String error);

  /// Shown when a reminder's post tag no longer exists
  ///
  /// In en, this message translates to:
  /// **'Unknown tag'**
  String get notificationSchedulesUnknownTag;

  /// Shown if someone who is not an area admin opens the hub
  ///
  /// In en, this message translates to:
  /// **'Only area admins can manage scheduled notifications.'**
  String get notificationSchedulesNotAllowed;

  /// Shown when saving a scheduled notification fails
  ///
  /// In en, this message translates to:
  /// **'Could not save that reminder. Try again.'**
  String get notificationSchedulesSaveFailed;

  /// Title when the scheduled notifications hub fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load scheduled notifications'**
  String get notificationSchedulesLoadFailed;

  /// Shown when there are no post tags to attach a reminder to
  ///
  /// In en, this message translates to:
  /// **'Add a post tag before creating a reminder.'**
  String get notificationSchedulesNeedTag;

  /// Shown when there are no locations to attach a reminder to
  ///
  /// In en, this message translates to:
  /// **'Add a location before creating a reminder.'**
  String get notificationSchedulesNeedLocation;

  /// Sends a sample of this reminder to the current device only
  ///
  /// In en, this message translates to:
  /// **'Send test to me'**
  String get notificationSchedulesTest;

  /// Label while a scheduled-notification test is in flight
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get notificationSchedulesTestSending;

  /// Confirm before sending a scheduled-notification sample
  ///
  /// In en, this message translates to:
  /// **'Send a test to this device?'**
  String get notificationSchedulesTestTitle;

  /// Explains that a scheduled-notification test stays on this device
  ///
  /// In en, this message translates to:
  /// **'This sends “{title}” only to this device. Nobody else is notified, and the reminder still counts as unsent.'**
  String notificationSchedulesTestBody(String title);

  /// Success after a scheduled-notification test
  ///
  /// In en, this message translates to:
  /// **'Test sent — check for a notification on this device.'**
  String get notificationSchedulesTestSent;

  /// Shown when a scheduled-notification test has no device token
  ///
  /// In en, this message translates to:
  /// **'No push token on this device. Turn notifications on under Personal → Settings → Push Notifications.'**
  String get notificationSchedulesTestNoToken;

  /// Shown when a scheduled-notification test fails
  ///
  /// In en, this message translates to:
  /// **'Could not send that test. Try again.'**
  String get notificationSchedulesTestFailed;

  /// Progress message while scheduled notifications load
  ///
  /// In en, this message translates to:
  /// **'Loading reminders'**
  String get notificationSchedulesLoading;

  /// Closes the full-screen photo and video viewer
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get galleryClose;

  /// Which item is open in the photo and video viewer
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String galleryPosition(int current, int total);

  /// Shown when a photo in the viewer fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load this photo'**
  String get galleryImageFailed;

  /// Shown when a video in the viewer fails to start
  ///
  /// In en, this message translates to:
  /// **'Could not play this video'**
  String get galleryVideoFailed;

  /// Retries a photo or video that failed to load in the viewer
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get galleryRetry;

  /// Starts video playback in the viewer
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get galleryPlay;

  /// Pauses video playback in the viewer
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get galleryPause;

  /// Repeats the current video when it reaches the end
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get galleryLoop;

  /// Shown when a gallery item is neither a photo nor a video
  ///
  /// In en, this message translates to:
  /// **'This file cannot be shown'**
  String get galleryMediaUnsupported;

  /// Button on an existing post that appends shortened attendee names to the title
  ///
  /// In en, this message translates to:
  /// **'Add who attended'**
  String get postTitleAddAttendees;

  /// Hint under Add who attended on the post title editor
  ///
  /// In en, this message translates to:
  /// **'Shuffles shortened names into the title. People who do not fit are shown as +N.'**
  String get postTitleAddAttendeesHint;

  /// Shown when the attended list has no usable names for the title
  ///
  /// In en, this message translates to:
  /// **'No names to add'**
  String get postTitleAddAttendeesNoNames;

  /// Shown when Add who attended is used before the title is filled in
  ///
  /// In en, this message translates to:
  /// **'Enter a title first'**
  String get postTitleAddAttendeesNeedTitle;

  /// Shown when the post title has no room for a shortened attendee name
  ///
  /// In en, this message translates to:
  /// **'Title is already too long to add names'**
  String get postTitleAddAttendeesTooLong;

  /// App bar control that opens the main section when a shared link is the first page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get permalinkGoHome;
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
