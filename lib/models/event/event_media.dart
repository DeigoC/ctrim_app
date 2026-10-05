import 'dart:collection';

class EventMedia {
  // * a media entry will have the following fields
  // type - string id of the user performing the update (img or vid)
  // src - the short string explaining the change
  // title - short string to give it some description (optional)
  // thumbnailSrc - src for video thumbnail (optional)
  late final List<Map<String, dynamic>> _media;

  EventMedia() {
    _media = List.empty(growable: true);
  }

  EventMedia.fromMap(final Map<String, dynamic> data) {
    _media = _toMedia(List<Map<String, dynamic>>.from(data['Media']));
  }

  Map<String, List<dynamic>> toJson() {
    return {'Media': _media};
  }

  List<Map<String, dynamic>> _toMedia(final List<Map<String, dynamic>> data) {
    final List<Map<String, dynamic>> results =
        List<Map<String, dynamic>>.empty(growable: true);

    for (final entry in data) {
      results.add({
        'title': entry['title'],
        'src': entry['src'],
        'type': entry['type'],
        'thumbnailSrc': entry['thumbnailSrc']
      });
    }

    return results;
  }

  List<Map<String, dynamic>> get allMedia => UnmodifiableListView(_media);
  void clearAllMedia() => _media.clear();
  void addMediaFile(final Map<String, dynamic> file) => _media.add(file);
  void addAllMediaFiles(final List<Map<String, dynamic>> mediaFiles) =>
      _media.addAll(mediaFiles);
  void removeMediaFile(final Map<String, dynamic> file) => _media.remove(file);

  /// Moves the gallery entry at [from] to index [to].
  ///
  /// Both indexes are positions in the list before the move. The same index,
  /// or an index outside the list, leaves the order unchanged.
  void moveMediaFile(final int from, final int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= _media.length ||
        to >= _media.length) {
      return;
    }
    final Map<String, dynamic> item = _media.removeAt(from);
    _media.insert(to, item);
  }
}
