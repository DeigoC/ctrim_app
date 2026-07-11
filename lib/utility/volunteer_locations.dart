/// Known volunteer locations used for registration, filtering, and display.
class VolunteerLocations {
  VolunteerLocations._();

  static const String all = 'All';
  static const String belfast = 'Belfast';
  static const String portadown = 'Portadown';
  static const String northCoast = 'North Coast';

  static const List<String> filterOptions = [all, belfast, portadown, northCoast];
  static const List<String> assignable = [belfast, portadown, northCoast];

  static String defaultFilterForUser(final String userLocation) {
    return assignable.contains(userLocation) ? userLocation : belfast;
  }
}
