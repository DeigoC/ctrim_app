import '../models/user_location.dart';

/// Known volunteer locations used for registration, filtering, and display.
///
/// Prefer [assignableFrom] / [filterOptionsFrom] with admin-managed definitions;
/// [fallbackAssignable] is used when Firestore locations are empty or unavailable.
class VolunteerLocations {
  VolunteerLocations._();

  static const String all = 'All';
  static const String belfast = 'Belfast';
  static const String portadown = 'Portadown';
  static const String northCoast = 'North Coast';

  static const List<String> fallbackAssignable = [belfast, portadown, northCoast];

  /// Legacy alias — prefer [assignableFrom] when AppContext locations are loaded.
  static const List<String> assignable = fallbackAssignable;

  /// Legacy alias — prefer [filterOptionsFrom] when AppContext locations are loaded.
  static const List<String> filterOptions = [all, belfast, portadown, northCoast];

  static List<String> assignableFrom(final List<UserLocation> locations) {
    final active = locations.where((l) => l.isActive).map((l) => l.name).toList();
    return active.isEmpty ? List<String>.from(fallbackAssignable) : active;
  }

  static List<String> filterOptionsFrom(final List<UserLocation> locations) {
    return [all, ...assignableFrom(locations)];
  }

  static String defaultFilterForUser(
    final String userLocation, [
    final List<String>? assignableNames,
  ]) {
    final options = assignableNames ?? fallbackAssignable;
    if (options.contains(userLocation)) return userLocation;
    return options.isNotEmpty ? options.first : belfast;
  }

  static const String onlineSuffix = ' (Online)';

  /// Strips the online suffix from [EventHead.location] for comparisons.
  static String normalizePostLocation(final String location) {
    return location.replaceAll(onlineSuffix, '').trim();
  }

  /// Bulletin / list filter against a post's [Location] field.
  static bool postLocationMatchesFilter({
    required String postLocation,
    required String locationFilter,
  }) {
    if (locationFilter == all) return true;
    return normalizePostLocation(postLocation) == locationFilter;
  }
}
