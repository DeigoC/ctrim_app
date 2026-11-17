import 'catalog/volunteer_locations.dart';

/// Starting filters for the people picker on a schedule role.
///
/// A role with ministries opens on those ministries and the post's location.
/// An untagged role leaves both unset so the picker keeps its usual defaults.
class ScheduleMemberPickerSeed {
  const ScheduleMemberPickerSeed({
    this.location,
    this.tagIDs = const [],
  });

  /// Known site name, or null when the post location is empty or unknown.
  final String? location;

  /// Ministries already on the role.
  final List<String> tagIDs;

  static const ScheduleMemberPickerSeed none = ScheduleMemberPickerSeed();

  static ScheduleMemberPickerSeed forRole({
    required Iterable<String> tagIDs,
    required String postLocation,
    required Iterable<String> assignableLocations,
  }) {
    final tags = [
      for (final id in tagIDs)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (tags.isEmpty) return none;

    final normalized = VolunteerLocations.normalizePostLocation(postLocation);
    final location =
        assignableLocations.contains(normalized) ? normalized : null;
    return ScheduleMemberPickerSeed(location: location, tagIDs: tags);
  }
}
