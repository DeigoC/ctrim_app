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
}
