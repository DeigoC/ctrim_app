// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CTRIM App';

  @override
  String get volunteersTitle => 'People';

  @override
  String volunteersTitleLocation(String location) {
    return '$location People';
  }

  @override
  String get volunteersFilterAll => 'All';

  @override
  String get volunteersFilterServing => 'Serving';

  @override
  String get volunteersFilterEveryone => 'Everyone';

  @override
  String get volunteersSearchHint => 'Search people...';

  @override
  String get volunteersEmpty => 'No people found';

  @override
  String volunteersEmptySearch(String query) {
    return 'No people match \"$query\"';
  }

  @override
  String volunteersSearchWithoutFiltersBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return 'No matches with current filters. Showing $_temp0 who match without filters (other locations, everyone, and placeholders you can see).';
  }

  @override
  String get volunteersWidenSearch => 'Widen search';

  @override
  String volunteersEmptyLocation(String location) {
    return 'No people in $location';
  }

  @override
  String get volunteersEmptyServing =>
      'No serving people here. Turn off Serving to see everyone.';

  @override
  String volunteersEmptyServingLocation(String location) {
    return 'No serving people in $location. Turn off Serving to see everyone.';
  }

  @override
  String get registerUser => 'Register person';

  @override
  String get volunteersMenuTitle => 'Who\'s who';

  @override
  String get volunteersMenuSubtitle => 'Leaders, teams, and members';

  @override
  String get peopleAndTeamsSectionTitle => 'People & teams';

  @override
  String get mySchedule => 'My Schedule';

  @override
  String get myScheduleSubtitle => 'View your tasks and roles';

  @override
  String get personalScheduleEmpty => 'No upcoming tasks assigned for now.';

  @override
  String get personalScheduleViewFull => 'View full schedule';

  @override
  String personalScheduleViewAll(int count) {
    return 'View all $count upcoming';
  }

  @override
  String get personalCellGroupsTitle => 'Cell groups';

  @override
  String get personalCellGroupsSubtitle => 'Your groups and upcoming meetings';

  @override
  String get personalCellGroupsEmpty =>
      'You are not in a cell group yet. Browse groups to find one that fits you.';

  @override
  String get personalCellGroupsBrowse => 'Browse cell groups';

  @override
  String get personalCellGroupsNoUpcoming =>
      'No upcoming meetings in the next 8 weeks.';

  @override
  String personalCellGroupLedBy(String leader) {
    return 'Led by $leader';
  }

  @override
  String get personalCellGroupLeaderTbc => 'Leader TBC';

  @override
  String personalCellGroupsMoreMeetings(int count) {
    return 'And $count more upcoming meetings';
  }

  @override
  String get personalScheduleDateTbc => 'Date TBC';

  @override
  String personalScheduleRolesCount(int count) {
    return '$count roles';
  }

  @override
  String get personalScheduleUntitledEvent => 'Untitled event';

  @override
  String get teamRota => 'Team rota';

  @override
  String get teamRotaSubtitle => 'What your teams are down for';

  @override
  String teamRotaHorizon(int months) {
    return 'Next $months months';
  }

  @override
  String get teamRotaLoadingHeads => 'Loading upcoming posts…';

  @override
  String get teamRotaLoadingProgrammes => 'Loading programmes…';

  @override
  String get teamRotaCouldNotLoad => 'Could not load team rota';

  @override
  String get teamRotaEmptyTitle => 'No team slots in this window';

  @override
  String get teamRotaEmptyBody =>
      'Tagged programme roles for the selected teams will show here, including slots that still need people. Open a post to edit.';

  @override
  String get teamRotaEmptyNoTeamsTitle => 'Pick a team';

  @override
  String get teamRotaEmptyNoTeamsBody =>
      'Choose one or more team tags to see their upcoming slots. Empty slots still belong to that team.';

  @override
  String get teamRotaUnassigned => 'Unassigned';

  @override
  String get teamRotaFilterLocation => 'Location';

  @override
  String get teamRotaFilterTeams => 'Teams';

  @override
  String get userProfileLeaderBadge => 'Leader';

  @override
  String get userProfileAdminBadge => 'Admin';

  @override
  String get userProfileCellGroupLeaderBadge => 'CG Leader';

  @override
  String get userProfileCellGroups => 'Cell groups';

  @override
  String get userProfileNoCellGroups => 'Not in a cell group.';

  @override
  String get userProfileCellGroupAttendedRecent =>
      'Attended in the past 3 weeks';

  @override
  String userProfileCellGroupMeetingsAttendedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attended $count cell group meetings in the past 3 weeks',
      one: 'Attended 1 cell group meeting in the past 3 weeks',
    );
    return '$_temp0';
  }

  @override
  String userProfileCellGroupMeetingsHostedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hosted $count cell group meetings in the past 3 weeks',
      one: 'Hosted 1 cell group meeting in the past 3 weeks',
    );
    return '$_temp0';
  }

  @override
  String userProfileCellGroupMeetingsParticipatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Took part in $count cell group meetings in the past 3 weeks',
      one: 'Took part in 1 cell group meeting in the past 3 weeks',
    );
    return '$_temp0';
  }

  @override
  String userProfileCellGroupGroupsAttendedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
    );
    return 'across $_temp0';
  }

  @override
  String get userProfileCellGroupNoAttendanceRecent =>
      'No cell group attendance in the past 3 weeks';

  @override
  String get userProfileCellGroupRecentMeetings => 'Recent meetings';

  @override
  String userProfileCellGroupRecentMeetingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meetings',
      one: '1 meeting',
    );
    return '$_temp0';
  }

  @override
  String get userProfileCellGroupMeetingAttended => 'Attended';

  @override
  String get userProfileCellGroupMeetingHosted => 'Hosted';

  @override
  String get userProfileCellGroupMeetingMissed => 'Not checked in';

  @override
  String get userProfileCellGroupNoRecentMeetings =>
      'No linked cell group meetings in the past 3 weeks';

  @override
  String get userProfileUpcomingTasks => 'Upcoming tasks';

  @override
  String get userProfileNoUpcomingTasks => 'No upcoming tasks assigned.';

  @override
  String get userProfileViewFullSchedule => 'View full schedule';

  @override
  String get userProfileViewPosts => 'View posts';

  @override
  String get userProfileContributorPosts => 'Recent contributor posts';

  @override
  String get userProfileNoContributorPosts =>
      'Not a contributor on any posts yet.';

  @override
  String get userProfileEditUser => 'Edit user';

  @override
  String get userProfileUntitledEvent => 'Untitled event';

  @override
  String get userProfileRecentActivity => 'Recent activity';

  @override
  String get userProfileNoRecentActivity => 'No recent activity';

  @override
  String get userProfileViewAllActivity => 'View all activity';

  @override
  String get userActivityPageTitle => 'Activity';

  @override
  String get userActivityDenied =>
      'Only area admins can view the full activity log.';

  @override
  String userActivityDocumentId(String id) {
    return 'Record $id';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get userTagsFilterClear => 'Clear tags';

  @override
  String get userTagsAssignLabel => 'Teams & tags';

  @override
  String get userTagsScheduleHint =>
      'Which teams this slot belongs to — separate from who is assigned.';

  @override
  String get userTagsNoneAvailable =>
      'No tags defined yet. Area admins can create tags in Admin Tools.';

  @override
  String get manageUserTagsTitle => 'Manage Tags';

  @override
  String get manageUserTagsAdd => 'Add tag';

  @override
  String get manageUserTagsEmpty =>
      'No team tags yet. Create tags for teams like Worship, Technical, or Usher.';

  @override
  String get manageUserTagsSeedDefaults => 'Add starter tags';

  @override
  String get manageUserTagsActive => 'Active';

  @override
  String get manageUserTagsInactive => 'Inactive';

  @override
  String get manageUserTagsMoveUp => 'Move up';

  @override
  String get manageUserTagsMoveDown => 'Move down';

  @override
  String get manageUserTagsEdit => 'Edit';

  @override
  String get manageUserTagsDeactivate => 'Deactivate';

  @override
  String get manageUserTagsActivate => 'Activate';

  @override
  String get manageUserTagsDelete => 'Delete';

  @override
  String get manageUserTagsNameLabel => 'Tag name';

  @override
  String get manageUserTagsColorLabel => 'Color (optional)';

  @override
  String get catalogColorNone => 'None';

  @override
  String get catalogColorHue => 'Hue';

  @override
  String get catalogColorShade => 'Shade';

  @override
  String get manageUserTagsCreate => 'Create';

  @override
  String manageUserTagsDeleteConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String manageUserTagsDeleteBlocked(int count) {
    return 'Cannot delete — $count people still have this tag. Deactivate it instead.';
  }

  @override
  String get manageUserTagsMenuTitle => 'Team tags';

  @override
  String get manageUserTagsMenuSubtitle => 'Create and edit team labels';

  @override
  String get manageUserTagsVisibleToGuests => 'Visible to guests';

  @override
  String get manageUserTagsVisibleToGuestsSubtitle =>
      'Turn off to hide this label from guests on profiles, schedule details, and the team tags page. People and schedule lines still show.';

  @override
  String get manageUserTagsHiddenFromGuests => 'Hidden from guests';

  @override
  String get manageUserTagsDescriptionLabel => 'Short description';

  @override
  String get manageUserTagsImageUrlLabel => 'Image URL';

  @override
  String get manageUserTagsImageUrlHint => 'https://…';

  @override
  String get manageUserTagsDescriptionHint => 'What this team does';

  @override
  String get manageUserTagsDescriptionMissing => 'No description yet';

  @override
  String get userTagsBrowseSubtitle => 'What each team is for';

  @override
  String get userTagsBrowseEmpty => 'No team tags to show yet.';

  @override
  String get userTagsLoading => 'Loading team tags…';

  @override
  String get userTagsDetailEmpty => 'More about this team will be added here.';

  @override
  String get userTagsUnavailable => 'This team tag is no longer available.';

  @override
  String get userTagDetailLocation => 'Location';

  @override
  String get userTagDetailNoLocations =>
      'Church locations are not set up yet, so heads, members, and photos cannot be shown by site.';

  @override
  String get userTagDetailHeads => 'Heads';

  @override
  String userTagDetailHeadsSubtitle(String location) {
    return 'Who leads this team at $location';
  }

  @override
  String userTagDetailHeadsEmpty(String location) {
    return 'No heads listed for $location yet.';
  }

  @override
  String get userTagDetailChooseHeads => 'Choose heads';

  @override
  String get userTagDetailMembers => 'Members';

  @override
  String userTagDetailMembersSubtitle(String location) {
    return 'People on this team at $location';
  }

  @override
  String userTagDetailMembersEmpty(String location) {
    return 'No one at $location has this team tag yet.';
  }

  @override
  String get userTagDetailGallery => 'Photos';

  @override
  String userTagDetailGallerySubtitle(String location) {
    return 'Photos from $location';
  }

  @override
  String userTagDetailGalleryEmpty(String location) {
    return 'No photos for $location yet.';
  }

  @override
  String get userTagDetailAddPhoto => 'Add photo';

  @override
  String get userTagDetailRemovePhoto => 'Remove photo';

  @override
  String userTagDetailRemovePhotoConfirm(String location) {
    return 'Remove this photo from $location?';
  }

  @override
  String get userTagDetailPhotosImagesOnly =>
      'Team tag albums only support images.';

  @override
  String userTagDetailGalleryFull(int count) {
    return 'This location already has the maximum of $count photos.';
  }

  @override
  String get userTagDetailUpcoming => 'Upcoming';

  @override
  String userTagDetailUpcomingSubtitle(int months, String location) {
    return 'Next $months months at $location';
  }

  @override
  String get userTagDetailPast => 'Already done';

  @override
  String userTagDetailPastSubtitle(int months, String location) {
    return 'Previous $months months at $location';
  }

  @override
  String userTagDetailScheduleEmptyUpcoming(String location) {
    return 'No upcoming slots for this team at $location.';
  }

  @override
  String userTagDetailScheduleEmptyPast(String location) {
    return 'No past slots for this team at $location in this window.';
  }

  @override
  String get userTagDetailScheduleLoading => 'Loading posts…';

  @override
  String get userTagDetailScheduleLoadingProgrammes => 'Loading programmes…';

  @override
  String get userTagDetailScheduleCouldNotLoad =>
      'Could not load this team\'s schedule';

  @override
  String get userTagDetailCouldNotSave =>
      'Could not save this team tag. Try again.';

  @override
  String get postTagsFilterClear => 'Clear tags';

  @override
  String get postTagsAssignLabel => 'Content tags';

  @override
  String get postTagsNoneAvailable =>
      'No post tags yet. Area admins can create tags in Admin Tools.';

  @override
  String get postTagsNoneSelected => 'No tags selected';

  @override
  String get postTagsManage => 'Manage tags';

  @override
  String get postTagsSelectTitle => 'Select content tags';

  @override
  String get postTagsSearchHint => 'Search tags...';

  @override
  String get postTagsNotifiableFilter => 'Notification streams';

  @override
  String get managePostTagsTitle => 'Manage Post Tags';

  @override
  String get managePostTagsAdd => 'Add tag';

  @override
  String get managePostTagsEmpty =>
      'No post tags yet. Create tags like Sunday Worship or Youth for bulletin filtering and optional notifications.';

  @override
  String get managePostTagsSeedDefaults => 'Add starter tags';

  @override
  String get managePostTagsActive => 'Active';

  @override
  String get managePostTagsInactive => 'Inactive';

  @override
  String get managePostTagsMoveUp => 'Move up';

  @override
  String get managePostTagsMoveDown => 'Move down';

  @override
  String get managePostTagsEdit => 'Edit';

  @override
  String get managePostTagsDeactivate => 'Deactivate';

  @override
  String get managePostTagsActivate => 'Activate';

  @override
  String get managePostTagsDelete => 'Delete';

  @override
  String get managePostTagsNameLabel => 'Tag name';

  @override
  String get managePostTagsColorLabel => 'Color (optional)';

  @override
  String get managePostTagsStreamKindLabel => 'Notify stream kind (optional)';

  @override
  String get managePostTagsStreamKindHelper =>
      'Combined with post location, e.g. sunday-service → belfast-sunday-service';

  @override
  String managePostTagsStreamKindHint(String kind) {
    return 'Notifies: $kind';
  }

  @override
  String get managePostTagsNoStream => 'Filter only (no notifications)';

  @override
  String get managePostTagsCreate => 'Create';

  @override
  String managePostTagsDeleteConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String managePostTagsDeleteBlocked(int count) {
    return 'Cannot delete — $count posts still have this tag. Deactivate it instead.';
  }

  @override
  String get managePostTagsMenuTitle => 'Post Tags';

  @override
  String get managePostTagsMenuSubtitle =>
      'Labels for bulletin filtering & notify streams';

  @override
  String get manageUserLocationsTitle => 'Manage Locations';

  @override
  String get manageUserLocationsAdd => 'Add location';

  @override
  String get manageUserLocationsEmpty =>
      'No locations yet. Add places like Belfast, Portadown, or North Coast.';

  @override
  String get manageUserLocationsSeedDefaults => 'Add starter locations';

  @override
  String get manageUserLocationsActive => 'Active';

  @override
  String get manageUserLocationsInactive => 'Inactive';

  @override
  String get manageUserLocationsMoveUp => 'Move up';

  @override
  String get manageUserLocationsMoveDown => 'Move down';

  @override
  String get manageUserLocationsEdit => 'Edit';

  @override
  String get manageUserLocationsDeactivate => 'Deactivate';

  @override
  String get manageUserLocationsActivate => 'Activate';

  @override
  String get manageUserLocationsDelete => 'Delete';

  @override
  String get manageUserLocationsNameLabel => 'Location name';

  @override
  String get manageUserLocationsCreate => 'Create';

  @override
  String manageUserLocationsDeleteConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String manageUserLocationsDeleteBlocked(int count) {
    return 'Cannot delete — $count people still have this location. Deactivate it instead.';
  }

  @override
  String manageUserLocationsDuplicate(String name) {
    return 'A location named \"$name\" already exists.';
  }

  @override
  String get manageUserLocationsMenuTitle => 'Locations';

  @override
  String get manageUserLocationsMenuSubtitle => 'Create and edit place labels';

  @override
  String get volunteersEmptyTags => 'No people match the selected tags';

  @override
  String get selectUsersTitle => 'Select people';

  @override
  String get selectUsersFilterSheetSubtitle =>
      'Location, team, or who is shown';

  @override
  String get selectUsersDone => 'Done';

  @override
  String selectUsersSelected(int count) {
    return '$count selected';
  }

  @override
  String get selectUsersAddFromCellGroup => 'Add from cell group';

  @override
  String get selectUsersAddingFromCellGroup => 'Adding from cell group…';

  @override
  String get selectUsersSelectAll => 'Select all';

  @override
  String get selectUsersUnselectAll => 'Unselect all';

  @override
  String selectCatalogSelected(int count) {
    return '$count selected';
  }

  @override
  String get selectCatalogNoResults => 'No matches for your search or filters.';

  @override
  String get selectUsersManageMembers => 'Manage members';

  @override
  String get selectUsersContributorsTitle => 'Select contributors';

  @override
  String get selectUsersManageContributors => 'Manage contributors';

  @override
  String get selectUsersCreatePlaceholder => 'Create placeholder';

  @override
  String get selectUsersCreatePlaceholderTitle => 'Create placeholder';

  @override
  String get selectUsersCreatePlaceholderBody =>
      'Create a temporary profile with no login. You can link their account later after they register.';

  @override
  String get selectUsersForename => 'Forename';

  @override
  String get selectUsersSurname => 'Surname';

  @override
  String get selectUsersCreate => 'Create';

  @override
  String get selectUsersNameRequired => 'Enter both forename and surname';

  @override
  String get selectUsersCreatingPlaceholder => 'Creating placeholder';

  @override
  String get selectUsersCreatingPlaceholderSubtitle => 'Saving profile…';

  @override
  String get selectUsersCreatePlaceholderFailed =>
      'Could not create placeholder';

  @override
  String get selectUsersPlaceholderCreated =>
      'Placeholder created and selected';

  @override
  String selectUsersPlaceholderSubtitle(String location) {
    return 'Placeholder · $location';
  }

  @override
  String get volunteersShowPlaceholders => 'Placeholders';

  @override
  String get volunteersShowInactive => 'Hidden & archived';

  @override
  String get volunteersStatusActive => 'Active';

  @override
  String get volunteersStatusHidden => 'Hidden';

  @override
  String get volunteersStatusArchived => 'Archived';

  @override
  String get volunteersStatusLabel => 'Profile status';

  @override
  String get volunteersStatusHelper =>
      'Hidden and archived profiles stay out of People and new assignments. Past events still show their name. They cannot sign in.';

  @override
  String get volunteersStatusConfirmTitle => 'Change profile status?';

  @override
  String get volunteersStatusConfirmMessage =>
      'They will be removed from People and pickers, cannot sign in, and leader/admin permissions will be cleared. Past events and attendance still show their name.';

  @override
  String get volunteersInactiveProfileBanner =>
      'This profile is hidden from the directory';

  @override
  String get volunteersArchivedProfileBanner => 'This profile is archived';

  @override
  String get volunteersLoginInactive =>
      'Your volunteer profile is no longer active. Please contact an admin if you think this is a mistake.';

  @override
  String get volunteersEmptyInactive =>
      'No hidden or archived profiles to show';

  @override
  String get volunteersEmptyPlaceholders => 'No placeholder profiles to show';

  @override
  String get volunteersPlaceholderBadge => 'Placeholder';

  @override
  String get volunteersSortLabel => 'Sort';

  @override
  String get volunteersSortSurname => 'Surname';

  @override
  String get volunteersSortTags => 'Team';

  @override
  String get volunteersFilterLeaders => 'Leaders';

  @override
  String get volunteersFilterAdmins => 'Admins';

  @override
  String get volunteersFilterCellGroupLeaders => 'CG Leaders';

  @override
  String get volunteersEmptyRoles => 'No people match the selected roles';

  @override
  String get volunteersFilterTags => 'Tags';

  @override
  String volunteersFilterTagsCount(int count) {
    return 'Tags ($count)';
  }

  @override
  String get volunteersFilterTagsSheetTitle => 'Filter by tags';

  @override
  String get volunteersFilterTagsSheetSubtitle =>
      'Show people with any of these team tags';

  @override
  String get volunteersSortTooltip => 'Sort people';

  @override
  String get volunteersFilterTooltip => 'Refine & sort';

  @override
  String get volunteersFilterSheetTitle => 'Refine & sort';

  @override
  String get volunteersFilterSheetSubtitle =>
      'Location, sort, role, team, or who is shown';

  @override
  String get volunteersFilterShowSection => 'Show';

  @override
  String get volunteersFilterLocationSection => 'Location';

  @override
  String get volunteersFilterServingSubtitle =>
      'People who serve on teams or lead groups';

  @override
  String get volunteersFilterRolesSection => 'Roles';

  @override
  String get volunteersFilterTeamsSection => 'Teams';

  @override
  String volunteersShowingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get volunteersDirectoryIntro =>
      'Browse leaders and team members in the church family.';

  @override
  String get volunteersClearFilters => 'Clear filters';

  @override
  String volunteersShowing(String parts) {
    return 'Showing: $parts';
  }

  @override
  String get cellGroupsAssignLabel => 'Cell groups';

  @override
  String get cellGroupsAssignHint =>
      'Link this meeting to one or more cell groups (joint sessions allowed)';

  @override
  String get cellGroupsNoneAvailable =>
      'No active cell groups yet. Area admins can create them in the Cell Groups section.';

  @override
  String get cellGroupsNoneSelected => 'No cell groups selected';

  @override
  String get cellGroupsManage => 'Manage cell groups';

  @override
  String get cellGroupsSelectTitle => 'Select cell groups';

  @override
  String get cellGroupsSearchHint => 'Search cell groups...';

  @override
  String get cellGroupsSectionTitle => 'Cell Groups';

  @override
  String get cellGroupsTabOverview => 'Overview';

  @override
  String get cellGroupsTabGroups => 'Groups';

  @override
  String get cellGroupsOverviewHeadline => 'Life in small groups';

  @override
  String get cellGroupsOverviewIntro =>
      'Cell groups are small gatherings that meet regularly outside the main service — focused on Bible study, care, prayer, and discipleship, usually in homes and led by trained members.';

  @override
  String get cellGroupsOverviewVerseTitle => 'Scripture';

  @override
  String get cellGroupsOverviewVerseReference => 'Acts 2:42, 46–47';

  @override
  String get cellGroupsOverviewVerseBody =>
      '\"They devoted themselves to the apostles’ teaching and to fellowship, to the breaking of bread and to prayer… They continued to meet together… And the Lord added to their number daily those who were being saved.\"';

  @override
  String get cellGroupsOverviewImagePlaceholder => 'Image coming soon';

  @override
  String get cellGroupsActivityTitle => 'Activity';

  @override
  String get cellGroupsActivitySubtitle => 'Meetings linked to cell groups';

  @override
  String get cellGroupsActivityPastMeetings => 'Recent meetings';

  @override
  String get cellGroupsActivityPastMeetingsHint => 'Past 3 weeks';

  @override
  String get cellGroupsActivityPastAttendees => 'Attendees';

  @override
  String get cellGroupsActivityPastAttendeesHint => 'Checked in · past 3 weeks';

  @override
  String get cellGroupsActivityUpcoming => 'Coming up';

  @override
  String get cellGroupsActivityUpcomingHint => 'Today + next 6 days';

  @override
  String get cellGroupsActivityActiveGroupsLabel => 'Active groups';

  @override
  String get cellGroupsActivityTotalMembersLabel => 'Members in active groups';

  @override
  String get cellGroupsActivityGroupsMetLabel =>
      'Groups that met · past 3 weeks';

  @override
  String get cellGroupsActivityAvgAttendanceLabel =>
      'Avg attendance · past 3 weeks';

  @override
  String get cellGroupsActivityPausedGroupsLabel => 'Paused groups';

  @override
  String get cellGroupsActivityLoadError => 'Couldn’t load activity right now.';

  @override
  String get cellGroupsActivityRetry => 'Retry';

  @override
  String get activityTrendMetricAttendance => 'Attendance';

  @override
  String get activityTrendWeeklyHint => 'Weekly · last 3 months';

  @override
  String get activityTrendEmpty => 'No activity in this period.';

  @override
  String get churchHubActivityTrendTitle => 'Activity over time';

  @override
  String get churchHubActivityTrendSubtitle =>
      'Bulletin posts at this location';

  @override
  String get churchHubActivityTrendMetricPosts => 'Posts';

  @override
  String get cellGroupsActivityTrendTitle => 'Meetings over time';

  @override
  String get cellGroupsActivityTrendSubtitle =>
      'Cell group meetings linked on the bulletin';

  @override
  String get cellGroupsActivityTrendMetricMeetings => 'Meetings';

  @override
  String get cellGroupsDetailActivityTitle => 'Activity';

  @override
  String get cellGroupsDetailActivityTrendTitle => 'Meetings over time';

  @override
  String get cellGroupsDetailActivityTrendSubtitle =>
      'Bulletin posts linked to this group';

  @override
  String get cellGroupsEmpty => 'No cell groups yet.';

  @override
  String cellGroupsEmptyLocation(String location) {
    return 'No cell groups at $location yet.';
  }

  @override
  String cellGroupsAtLocationTitle(String location) {
    return '$location cell groups';
  }

  @override
  String get cellGroupsCreate => 'New cell group';

  @override
  String get cellGroupsEdit => 'Edit group';

  @override
  String get cellGroupsManageRoster => 'Manage cell members';

  @override
  String get cellGroupsMeetingTrail => 'Recent meetings';

  @override
  String get cellGroupsMeetingTrailEmpty => 'No linked meeting posts yet.';

  @override
  String cellGroupsMemberCount(int count) {
    return '$count members';
  }

  @override
  String get cellGroupsLeadersLabel => 'Leaders';

  @override
  String get cellGroupsRosterTitle => 'Cell Members';

  @override
  String get cellGroupsAddMembers => 'Add members';

  @override
  String get cellGroupsRosterAddHint =>
      'Search for someone, or create a temporary profile if they are not listed.';

  @override
  String get cellGroupsStatusActive => 'Active';

  @override
  String get cellGroupsStatusPaused => 'Paused';

  @override
  String get cellGroupsStatusArchived => 'Archived';

  @override
  String get cellGroupsGuestSignInHint =>
      'Sign in to see more details about this group.';

  @override
  String get cellGroupsAboutTitle => 'About';

  @override
  String get cellGroupsPhotosTitle => 'Photos';

  @override
  String get cellGroupsPhotosHint =>
      'Add a wide group photo as the cover for the detail page. Catalogue tiles still show the first leader’s portrait.';

  @override
  String get cellGroupsPhotosEmpty => 'No photos yet.';

  @override
  String get cellGroupsAddPhoto => 'Add photo';

  @override
  String get cellGroupsCoverPhoto => 'Cover';

  @override
  String get cellGroupsSetAsCover => 'Tap to set as cover';

  @override
  String get cellGroupsPhotosImagesOnly =>
      'Cell groups only support images for now.';

  @override
  String get cellGroupsNameLabel => 'Name';

  @override
  String get cellGroupsNameHint => 'e.g. Young Adults';

  @override
  String get cellGroupsNameHelper =>
      'The public title on the Groups list and the group page.';

  @override
  String get cellGroupsNameRequired => 'Name is required';

  @override
  String get cellGroupsSummaryLabel => 'Summary';

  @override
  String get cellGroupsSummaryHint =>
      'Who this group is for, and what you usually do';

  @override
  String get cellGroupsSummaryHelper =>
      'Short description on the catalogue card and in About.';

  @override
  String get cellGroupsLocationLabel => 'Location';

  @override
  String get cellGroupsLocationHelper =>
      'Church area this group belongs to (Belfast, Portadown, or North Coast).';

  @override
  String get cellGroupsPostcodeLabel => 'Postcode';

  @override
  String get cellGroupsPostcodeHint => 'e.g. BT37 or BT37 0AB';

  @override
  String get cellGroupsPostcodeHelper =>
      'Optional. A full postcode or just the first half (BT37) is public and used to find the nearest group. Leave blank to stay off the map.';

  @override
  String get cellGroupsPostcodeInvalid =>
      'Enter a UK postcode or area code (e.g. BT37), or leave this blank.';

  @override
  String get cellGroupsPostcodeLookupFailed =>
      'Could not check that postcode. Check it and try again.';

  @override
  String get cellGroupsListSearchHint => 'Search by name or postcode';

  @override
  String get cellGroupsSearchInvalidPostcodeTitle => 'Not a valid postcode';

  @override
  String get cellGroupsSearchInvalidPostcodeBody =>
      'Try a full UK postcode such as BT9 6AB, or an area code such as BT9.';

  @override
  String get cellGroupsSearchNoNearbyTitle => 'No groups near that postcode';

  @override
  String get cellGroupsSearchNoNearbyBody =>
      'Only groups that have added a postcode can appear in nearest results. Search by name, or browse the full list.';

  @override
  String get cellGroupsSearchNoNameMatchesTitle => 'No matching groups';

  @override
  String get cellGroupsSearchNoNameMatchesBody =>
      'Try another name, or enter a postcode to see the nearest groups.';

  @override
  String get cellGroupsSearchLookupFailedTitle =>
      'Could not look up that postcode';

  @override
  String get cellGroupsSearchLookupFailedBody =>
      'Check your connection and try again.';

  @override
  String cellGroupsDistanceMiles(String miles) {
    return '$miles miles';
  }

  @override
  String get cellGroupsDistanceUnderPointOne => '< 0.1 miles';

  @override
  String get cellGroupsWeekdayLabel => 'Meeting weekday';

  @override
  String get cellGroupsWeekdayHelper =>
      'Usual day this group meets. Leave unset if it varies.';

  @override
  String get cellGroupsWeekdayNotSet => 'Not set';

  @override
  String get cellGroupsTimeLabel => 'Meeting time';

  @override
  String get cellGroupsTimeHint => 'e.g. 19:30';

  @override
  String get cellGroupsTimeHelper =>
      'Usual start time, shown with the weekday on the Groups list.';

  @override
  String get cellGroupsStatusLabel => 'Status';

  @override
  String get cellGroupsStatusHelper =>
      'Active groups appear in the catalogue. Paused groups stay listed as paused. Archived groups are hidden.';

  @override
  String get cellGroupsLeadersHint =>
      'People who lead this group. Catalogue tiles use the first leader’s portrait.';

  @override
  String get cellGroupsChooseLeaders => 'Choose leaders';

  @override
  String get bulletinSortFilterTitle => 'Sort & Filter';

  @override
  String get bulletinSortFilterSubtitle => 'Choose how to organize your events';

  @override
  String get bulletinSortTooltip => 'Sort & Filter';

  @override
  String get bulletinSortSection => 'Sort';

  @override
  String get bulletinSortRelevancy => 'Relevancy';

  @override
  String get bulletinSortRelevancySubtitle =>
      'Next few events, then recent past';

  @override
  String get bulletinSortSoonest => 'Soonest first';

  @override
  String get bulletinSortSoonestSubtitle =>
      'Upcoming events first, then recent past';

  @override
  String get bulletinSortLatest => 'Latest first';

  @override
  String get bulletinSortLatestSubtitle => 'Recent past first, then upcoming';

  @override
  String get bulletinSortRecent => 'Recently updated';

  @override
  String get bulletinSortRecentSubtitle => 'Newest creates and edits first';

  @override
  String get bulletinShowSection => 'Show';

  @override
  String get bulletinShowAll => 'All posts';

  @override
  String get bulletinShowUpcoming => 'Upcoming';

  @override
  String get bulletinShowPast => 'Past';

  @override
  String get bulletinShowUndated => 'No date';

  @override
  String get bulletinShowBookmarks => 'Bookmarks';

  @override
  String get bulletinLocationSection => 'Location';

  @override
  String get bulletinLocationSubtitle => 'Show posts for a specific place';

  @override
  String get bulletinTagsSubtitle => 'Narrow the bulletin by content type';

  @override
  String bulletinShowing(String parts) {
    return 'Showing: $parts';
  }

  @override
  String get bulletinClearFilters => 'Clear filters';

  @override
  String get bulletinEmptyTitle => 'No Events Found';

  @override
  String get bulletinEmptyBody =>
      'There are no events matching your current filters.\nTry adjusting your sort or filters.';

  @override
  String get bulletinChangeFilter => 'Change Filter';

  @override
  String get bulletinBookmarksHelpTitle => 'Bookmarked Posts';

  @override
  String get bulletinBookmarksHelpBody =>
      'You will be notified of updates made to the posts you bookmark.\n\nTo bookmark a post, tap and hold on any event card.';

  @override
  String get bulletinBookmarksHelpTooltip => 'Learn about bookmarks';

  @override
  String get myPostsTitle => 'My Posts';

  @override
  String get myPostsHelpTitle => 'My Posts';

  @override
  String get myPostsHelpBody =>
      'Posts where you are the author or a contributor appear here — handy for finding posts you can edit.\n\nUse sort and filter to narrow by date, location, or tags. The list defaults to recently updated.';

  @override
  String get myPostsEmptyTitle => 'No posts yet';

  @override
  String get myPostsEmptyBody =>
      'When you create or contribute to a post, it will show up here.';

  @override
  String get myPostsLoading => 'Loading posts…';

  @override
  String get myPostsFetching => 'Fetching posts…';

  @override
  String get myPostsCleaning => 'Cleaning up posts…';

  @override
  String get myPostsDone => 'Done';

  @override
  String get myPostsLoadError => 'Could not load posts';

  @override
  String get churchInfoPageTitle => 'Church Info';

  @override
  String get churchInfoNotFound => 'No church information found.';

  @override
  String get churchInfoEditTooltip => 'Edit church info';

  @override
  String get churchInfoLoadError => 'Could not load church';

  @override
  String get churchHubOpenMaps => 'Open in Maps';

  @override
  String get churchHubLocationUnset => 'Location not set';

  @override
  String get churchHubSetLocationHint =>
      'Set a location when editing to show posts, cell groups, and people for this church.';

  @override
  String get churchHubSnapshotTitle => 'At this location';

  @override
  String get churchHubPostsLabel => 'Posts';

  @override
  String get churchHubPostsHint => 'Last 3 months';

  @override
  String get churchHubCellGroupsLabel => 'Cell Groups';

  @override
  String get churchHubCellGroupsHint => 'Active and paused';

  @override
  String get churchHubPeopleLabel => 'People';

  @override
  String get churchHubPeopleHint => 'Profiles here';

  @override
  String get churchHubRecentPosts => 'Recent posts';

  @override
  String get churchHubCellGroupsHere => 'Cell Groups here';

  @override
  String get churchHubNoRecentPosts => 'No posts in the last 3 months.';

  @override
  String get churchHubNoCellGroups => 'No cell groups at this location yet.';

  @override
  String churchHubMorePosts(int count) {
    return 'And $count more';
  }

  @override
  String churchHubViewAllCellGroups(int count) {
    return 'View all $count cell groups';
  }

  @override
  String get churchHubStatsError => 'Could not load location activity.';

  @override
  String get churchHubStatsRetry => 'Retry';

  @override
  String get churchHubAboutTitle => 'About';

  @override
  String get churchHubPagesTitle => 'More about this church';

  @override
  String get churchHubNoPages => 'No extra pages yet.';

  @override
  String get churchHubAddPage => 'Add page';

  @override
  String get churchHubAddPageDescription =>
      'Add a page for getting here, Sunday service, or other details.';

  @override
  String get churchHubPagesError => 'Could not load extra pages.';

  @override
  String get churchHubPagesRetry => 'Retry';

  @override
  String get churchHubPastorsTitle => 'Pastors & History';

  @override
  String get churchHubPlantersTitle => 'Planters & History';

  @override
  String get churchHubUnknownPastor => 'Unknown pastor';

  @override
  String get churchHubUnknownPlanter => 'Unknown planter';

  @override
  String get churchHubFindUsTitle => 'Find us';

  @override
  String get churchHubFindUsSubtitle => 'Location, address, and maps';

  @override
  String get churchHubPastorsSubtitle =>
      'The team and the story of this church';

  @override
  String get churchHubPlantersSubtitle =>
      'The team and the story of this outreach';

  @override
  String get churchHubLearnAboutPastors => 'Read more';

  @override
  String get churchHubLearnAboutPlanters => 'Read more';

  @override
  String get churchPastorsPageTitle => 'Pastors & History';

  @override
  String get churchPlantersPageTitle => 'Planters & History';

  @override
  String get churchHubOutreachBadge => 'Outreach';

  @override
  String churchesTabOutreachOf(String parentTitle) {
    return 'Outreach of $parentTitle';
  }

  @override
  String get churchHubParentChurchTitle => 'Parent church';

  @override
  String get churchHubParentChurchSubtitle => 'This outreach belongs to';

  @override
  String get churchHubOutreachesTitle => 'Outreaches';

  @override
  String get churchHubOutreachesSubtitle => 'Growing toward a full church';

  @override
  String get churchHubNoOutreaches => 'No outreaches yet.';

  @override
  String get churchHubAddOutreach => 'Add outreach';

  @override
  String get churchHubAddOutreachDescription =>
      'Add a baby church with church planters.';

  @override
  String get churchHubOutreachFindUsEmpty => 'No address or maps link yet.';

  @override
  String get churchHubGalleryTitle => 'Gallery';

  @override
  String get churchHubGallerySubtitle => 'Photos from this church';

  @override
  String get churchHubSnapshotSubtitle => 'Activity at this location';

  @override
  String get churchHubPagesSubtitle => 'Getting here, Sunday service, and more';

  @override
  String get churchHubRecentPostsSubtitle => 'From the last 3 months';

  @override
  String get churchHubCellGroupsSubtitle => 'Meeting at this location';

  @override
  String get churchEditorChurchCardTitle => 'Church';

  @override
  String get churchEditorOutreachCardTitle => 'Outreach';

  @override
  String get churchEditorSummaryLabel => 'Subtitle';

  @override
  String get churchEditorSummaryHelperChurch =>
      'Shown under the title. Leave blank for the title only.';

  @override
  String get churchEditorSummaryHelperOutreach =>
      'Shown under the title. Leave blank to name the parent church.';

  @override
  String get churchEditorStatusCardTitle => 'Status';

  @override
  String get churchEditorKindChurch => 'Full church';

  @override
  String get churchEditorKindChurchHint =>
      'Appears in the Churches list and uses its own location.';

  @override
  String get churchEditorKindOutreach => 'Outreach';

  @override
  String get churchEditorKindOutreachHint =>
      'Listed on the parent church hub until promoted.';

  @override
  String get churchEditorParentChurchLabel => 'Parent church';

  @override
  String get churchEditorPromoteToChurch => 'Promote to full church';

  @override
  String get churchEditorDemoteToOutreach => 'Demote to outreach';

  @override
  String get churchEditorCancel => 'Cancel';

  @override
  String get churchEditorPromoteConfirmTitle => 'Promote to full church?';

  @override
  String get churchEditorPromoteConfirmBody =>
      'This outreach will leave its parent and need its own location before you save.';

  @override
  String get churchEditorPromoteBlockedTitle => 'Cannot promote';

  @override
  String get churchEditorDemoteConfirmTitle => 'Demote to outreach?';

  @override
  String get churchEditorDemoteConfirmBody =>
      'This church will sit under a parent and lose its location assignment. Choose the parent church.';

  @override
  String get churchEditorDemoteBlockedTitle => 'Cannot demote';

  @override
  String get churchEditorDemoteNoParent =>
      'Add another full church first to use as the parent.';

  @override
  String get churchEditorValidationTitle => 'Check church details';

  @override
  String get churchEditorLocationConflictTitle => 'Location already used';

  @override
  String churchEditorLocationConflictBody(String location, String churchTitle) {
    return 'Location “$location” is already used by $churchTitle. Each church must have its own location.';
  }

  @override
  String get churchEditorDeleteBlockedTitle => 'Cannot delete';

  @override
  String get churchEditorDeleteBlockedBody =>
      'Promote or delete this church’s outreaches first.';

  @override
  String get churchEditorLocationLabel => 'Location';

  @override
  String get churchEditorLocationHelper =>
      'Each church must use a unique location from the catalogue.';

  @override
  String get churchEditorOutreachLocationHint =>
      'No catalogue location until this is a full church.';

  @override
  String get churchEditorAddressLabel => 'Address';

  @override
  String get churchEditorMapsLabel => 'Maps URL';

  @override
  String get churchEditorMapsHelpTooltip => 'Maps URL help';

  @override
  String get churchEditorVisitCardTitle => 'Find us';

  @override
  String get churchEditorSocialsCardTitle => 'Socials';

  @override
  String get churchEditorSocialsEmptyHint => 'No social links yet.';

  @override
  String get churchEditorAddSocial => 'Add social link';

  @override
  String get churchEditorRemoveSocial => 'Remove';

  @override
  String get churchEditorSocialPlatformLabel => 'Platform';

  @override
  String get churchEditorSocialUrlLabel => 'Link or email';

  @override
  String get churchHubSocialsTitle => 'Socials';

  @override
  String get churchHubSocialsSubtitle => 'Follow and get in touch';

  @override
  String get churchSocialFacebook => 'Facebook';

  @override
  String get churchSocialInstagram => 'Instagram';

  @override
  String get churchSocialYoutube => 'YouTube';

  @override
  String get churchSocialX => 'X';

  @override
  String get churchSocialTiktok => 'TikTok';

  @override
  String get churchSocialWhatsapp => 'WhatsApp';

  @override
  String get churchSocialWebsite => 'Website';

  @override
  String get churchSocialEmail => 'Email';

  @override
  String get churchSocialOther => 'Link';

  @override
  String get churchEditorPastorsCardTitle => 'Pastors & History';

  @override
  String get churchEditorPlantersCardTitle => 'Planters & History';

  @override
  String get churchEditorChoosePastors => 'Choose pastors';

  @override
  String get churchEditorChoosePlanters => 'Choose church planters';

  @override
  String get churchEditorPastorsImageLabel => 'Pastors image URL';

  @override
  String get churchEditorPlantersImageLabel => 'Planters image URL';

  @override
  String get churchEditorMediaCardTitle => 'Media';

  @override
  String get churchEditorPastorsBodyLabel =>
      'About the pastors and this church';

  @override
  String get churchEditorPlantersBodyLabel =>
      'About the planters and this outreach';

  @override
  String get churchEditorSave => 'Save';

  @override
  String get openPostPageTitle => 'Post';

  @override
  String get openPostLoading => 'Loading post…';

  @override
  String get openPostNotFoundTitle => 'Post not found';

  @override
  String get openPostNotFoundBody =>
      'This post may have been removed, or the link may be incorrect.';

  @override
  String get openPostLoadErrorTitle => 'Could not load post';

  @override
  String get sharePostTooltip => 'Share';

  @override
  String get openPersonPageTitle => 'Profile';

  @override
  String get openPersonLoading => 'Loading profile…';

  @override
  String get openPersonNotFoundTitle => 'Profile not found';

  @override
  String get openPersonNotFoundBody =>
      'This profile may be hidden, or the link may be incorrect.';

  @override
  String get openPersonLoadErrorTitle => 'Could not load profile';

  @override
  String get notificationViewPost => 'View post';

  @override
  String get notificationViewPage => 'View page';

  @override
  String get notificationDismiss => 'Ok';

  @override
  String get scheduleEmptyTitle => 'Nothing scheduled yet';

  @override
  String get scheduleEmptyBodyEditor =>
      'Add schedule items from the edit menu and they will appear here on the timeline.';

  @override
  String get scheduleEmptyBodyViewer =>
      'The running order for this post has not been shared yet.';

  @override
  String get scheduleAllEventSectionTitle => 'All event';

  @override
  String scheduleAllEventArrangeHint(String title) {
    return '\"$title\" runs for most of the event, so it stays out of the running order';
  }

  @override
  String get scheduleUntimedSectionTitle => 'Without a time';

  @override
  String get scheduleNoTimeSet => 'No time set';

  @override
  String get scheduleStaffOnly => 'Not shown to guests';

  @override
  String get scheduleEditTask => 'Edit Task';

  @override
  String scheduleParallelCount(int count) {
    return '+$count parallel';
  }

  @override
  String get scheduleParallelSheetTitle => 'Running in parallel';

  @override
  String get scheduleParallelSheetSubtitle =>
      'These items overlap others already on the timeline';

  @override
  String get scheduleArrangeTitle => 'Arrange schedule';

  @override
  String get scheduleArrangeSubtitle =>
      'Drag items to reorder the running time';

  @override
  String get scheduleArrangeDone => 'Done';

  @override
  String get scheduleArrangeEmpty =>
      'Add timed schedule items before arranging them.';

  @override
  String get scheduleArrangeModeCascade => 'Cascade';

  @override
  String get scheduleArrangeModeParallel => 'Parallel';

  @override
  String get scheduleArrangeCascadeHint =>
      'Long press an item and drag it. Anything it lands on moves later to keep the running order.';

  @override
  String get scheduleArrangeParallelHint =>
      'Long press an item and drag it. Everything else keeps its time, so items can run at the same time.';

  @override
  String scheduleArrangeDragHint(String title) {
    return 'Long press \"$title\" to drag it';
  }
}
