import 'dart:collection';

class EventMedia {
  // * a media entry will have the following fields
  // type - string id of the user performing the update (img or vid)
  // src - the short string explaining the change
  // title - short string to give it some description (optional)
  late final List<Map<String, String>> _media;

  EventMedia() {
    _media = List.empty(growable: true);
  }

  EventMedia.fromMap(Map<String, dynamic> data) {
    _media = _toMedia(List<Map<String, dynamic>>.from(data['Media']));
  }

  toJson() {
    return {'Media': _media};
  }

  List<Map<String, String>> _toMedia(List<Map<String, dynamic>> data) {
    final List<Map<String, String>> results = List<Map<String, String>>.empty(growable: true);

    for (final entry in data) {
      results.add({
        'title': entry['title'],
        'src': entry['src'],
        'type': entry['type'],
      });
    }

    return results;
  }

  List<Map<String, String>> get allMedia => UnmodifiableListView(_media);
  void clearAllMedia() => _media.clear();
  void addMediaFile(Map<String, String> file) => _media.add(file);
  void removeMediaFile(Map<String, String> file) => _media.remove(file); // test this kind of approach!
}
