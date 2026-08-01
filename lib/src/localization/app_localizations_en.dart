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
  String get volunteersTitle => 'Volunteers';

  @override
  String volunteersTitleLocation(String location) {
    return '$location Volunteers';
  }

  @override
  String get volunteersFilterAll => 'All';

  @override
  String get volunteersSearchHint => 'Search volunteers...';

  @override
  String get volunteersEmpty => 'No volunteers found';

  @override
  String volunteersEmptySearch(String query) {
    return 'No volunteers match \"$query\"';
  }

  @override
  String volunteersEmptyLocation(String location) {
    return 'No volunteers in $location';
  }

  @override
  String get registerUser => 'Register User';

  @override
  String get volunteersMenuTitle => 'Volunteers';

  @override
  String get volunteersMenuSubtitle => 'View community members';

  @override
  String get mySchedule => 'My Schedule';

  @override
  String get myScheduleSubtitle => 'View your tasks and roles';

  @override
  String get userProfileLeaderBadge => 'Leader';

  @override
  String get userProfileAdminBadge => 'Admin';

  @override
  String get userProfileUpcomingTasks => 'Upcoming tasks';

  @override
  String get userProfileNoUpcomingTasks => 'No upcoming tasks assigned.';

  @override
  String get userProfileViewFullSchedule => 'View full schedule';

  @override
  String get userProfileViewPosts => 'View posts';

  @override
  String get userProfileEditUser => 'Edit user';

  @override
  String get userProfileUntitledEvent => 'Untitled event';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get userTagsFilterClear => 'Clear tags';

  @override
  String get userTagsAssignLabel => 'Teams & tags';

  @override
  String get userTagsNoneAvailable =>
      'No tags defined yet. Area admins can create tags in Admin Tools.';

  @override
  String get manageUserTagsTitle => 'Manage Tags';

  @override
  String get manageUserTagsAdd => 'Add tag';

  @override
  String get manageUserTagsEmpty =>
      'No volunteer tags yet. Create tags for teams like Worship, Technical, or Usher.';

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
  String get manageUserTagsCreate => 'Create';

  @override
  String manageUserTagsDeleteConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String manageUserTagsDeleteBlocked(int count) {
    return 'Cannot delete — $count volunteers still have this tag. Deactivate it instead.';
  }

  @override
  String get manageUserTagsMenuTitle => 'Volunteer Tags';

  @override
  String get manageUserTagsMenuSubtitle => 'Create and edit team labels';

  @override
  String get postTagsFilterClear => 'Clear tags';

  @override
  String get postTagsAssignLabel => 'Content tags';

  @override
  String get postTagsNoneAvailable =>
      'No post tags yet. Area admins can create tags in Admin Tools.';

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
    return 'Cannot delete — $count volunteers still have this location. Deactivate it instead.';
  }

  @override
  String manageUserLocationsDuplicate(String name) {
    return 'A location named \"$name\" already exists.';
  }

  @override
  String get manageUserLocationsMenuTitle => 'Volunteer Locations';

  @override
  String get manageUserLocationsMenuSubtitle => 'Create and edit place labels';

  @override
  String get volunteersEmptyTags => 'No volunteers match the selected tags';

  @override
  String get selectUsersTitle => 'Select members';

  @override
  String get selectUsersDone => 'Done';

  @override
  String selectUsersSelected(int count) {
    return '$count selected';
  }

  @override
  String get selectUsersManageMembers => 'Manage members';

  @override
  String get selectUsersContributorsTitle => 'Select contributors';

  @override
  String get selectUsersManageContributors => 'Manage contributors';

  @override
  String get volunteersSortLabel => 'Sort';

  @override
  String get volunteersSortSurname => 'Surname';

  @override
  String get volunteersSortTags => 'Team';

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
  String get volunteersSortTooltip => 'Sort volunteers';
}
