import 'dart:collection';

class EventMedia {
  late final Map<String, String> _srcTypes;

  EventMedia({required Map<String, String> srcTypes}) : _srcTypes = srcTypes;

  Map<String, String> get srcTypes => UnmodifiableMapView(_srcTypes);
  void addMediaFile(String src, String type) => _srcTypes[src] = type;
  void removeMediaFile(String srcToRemove) => _srcTypes.remove(srcToRemove);
}
