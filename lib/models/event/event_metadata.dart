import 'dart:collection';

class EventMetadata {
  late final String _authorUID;
  late final List<String> _contributorUIDs;
  late String _lastUID;

  EventMetadata({required String authorUID}) {
    _authorUID = authorUID;
    _lastUID = authorUID;
    _contributorUIDs = List<String>.empty(growable: true);
  }

  EventMetadata.fromMap(Map<String, dynamic> data)
      : _authorUID = data['AuthorUID'],
        _lastUID = data['LastUID'],
        _contributorUIDs = List.from(data['ContributorUIDs']);

  toJson() {
    return {'AuthorUID': _authorUID, 'LastUID': _lastUID, 'ContributorUIDs': _contributorUIDs};
  }

  String get lastUID => _lastUID;
  String get authorUID => _authorUID;
  List<String> get contributorUIDs => UnmodifiableListView(_contributorUIDs);

  void setLastUID(String newLastUID) => _lastUID = newLastUID;
  void addContributorUID(String newUID) => _contributorUIDs.add(newUID);
  void removeContributorUID(String toBeRemovedUID) => _contributorUIDs.remove(toBeRemovedUID);
}
