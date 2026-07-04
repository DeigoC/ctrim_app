import 'dart:collection';

class EventMetadata {
  late final String _authorUID;
  late final List<String> _contributorUIDs;
  late String _lastUID;
  late final String? _parentID;
  late final List<String> _childrenIDs, _topics;

  EventMetadata({required String authorUID, final String? parentID}) {
    _authorUID = authorUID;
    _lastUID = authorUID;
    _parentID = parentID;
    _contributorUIDs = List<String>.empty(growable: true);
    _childrenIDs = List<String>.empty(growable: true);
    _topics = List.empty(growable: true);
  }

  EventMetadata.fromMap(final Map<String, dynamic> data)
      : _authorUID = data['AuthorUID'],
        _lastUID = data['LastUID'],
        _parentID = data['ParentID'],
        _contributorUIDs = List<String>.from(data['ContributorUIDs']),
        _childrenIDs = List<String>.from(data['ChildrenIDs']),
        _topics = List<String>.from(data['Topics'] ?? []);

  Map<String, Object?> toJson() {
    return {
      'AuthorUID': _authorUID,
      'LastUID': _lastUID,
      'ContributorUIDs': _contributorUIDs,
      'ParentID': _parentID,
      'ChildrenIDs': _childrenIDs,
      'Topics': _topics
    };
  }

  String get lastUID => _lastUID;
  String get authorUID => _authorUID;
  String? get parentID => _parentID;
  bool get hasChildren => _childrenIDs.isNotEmpty;
  bool get hasParent => _parentID != null;

  // ! change in the future to be unmodifiable and update accordingly
  List<String> get contributorUIDs => _contributorUIDs;
  List<String> get childrenPostIDs => _childrenIDs;
  List<String> get topics => UnmodifiableListView(_topics);

  void clearTopics() => _topics.clear();
  void addAllTopics(final List<String> newTopics) => _topics.addAll(newTopics);
  void setLastUID(final String newLastUID) => _lastUID = newLastUID;
}
