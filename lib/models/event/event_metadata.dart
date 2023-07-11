import 'dart:collection';

class EventMetadata {
  late final String _authorUID;
  late final List<String> _contributorUIDs;
  late String _lastUID;
  late final String? _parentID;
  late final List<String> _childrenIDs;

  EventMetadata({required String authorUID, String? parentID}) {
    _authorUID = authorUID;
    _lastUID = authorUID;
    _parentID = parentID;
    _contributorUIDs = List<String>.empty(growable: true);
    _childrenIDs = List<String>.empty(growable: true);
  }

  EventMetadata.fromMap(Map<String, dynamic> data)
      : _authorUID = data['AuthorUID'],
        _lastUID = data['LastUID'],
        _parentID = data['ParentID'],
        _contributorUIDs = List<String>.from(data['ContributorUIDs']),
        _childrenIDs = List<String>.from(data['ChildrenIDs']);

  toJson() {
    return {
      'AuthorUID': _authorUID,
      'LastUID': _lastUID,
      'ContributorUIDs': _contributorUIDs,
      'ParentID': _parentID,
      'ChildrenIDs': _childrenIDs
    };
  }

  String get lastUID => _lastUID;
  String get authorUID => _authorUID;
  String? get parentID => _parentID!;
  List<String> get contributorUIDs => UnmodifiableListView(_contributorUIDs);
  List<String> get children => UnmodifiableListView(_childrenIDs);
  bool get hasChildren => _childrenIDs.isNotEmpty;
  bool get hasParent => _parentID != null;

  void setLastUID(String newLastUID) => _lastUID = newLastUID;
  void addContributorUID(String newUID) => _contributorUIDs.add(newUID);
  void removeContributorUID(String toBeRemovedUID) => _contributorUIDs.remove(toBeRemovedUID);
  void addChildID(String childID) => _childrenIDs.add(childID);
}
