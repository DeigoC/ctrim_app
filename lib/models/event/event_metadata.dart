import 'dart:collection';

class EventMetadata {
  late final String _authorUID;
  late final List<String> _contributorUIDs;
  late String _lastUID;
  late String? _parentID;
  late final List<String> _childrenIDs, _topics, _tagIDs;
  String? _leadSpeakerUID;
  bool _isPeriodParent = false;

  EventMetadata({required String authorUID, final String? parentID, bool isPeriodParent = false}) {
    _authorUID = authorUID;
    _lastUID = authorUID;
    _parentID = parentID;
    _isPeriodParent = isPeriodParent;
    _contributorUIDs = List<String>.empty(growable: true);
    _childrenIDs = List<String>.empty(growable: true);
    _topics = List.empty(growable: true);
    _tagIDs = List.empty(growable: true);
  }

  EventMetadata.fromMap(final Map<String, dynamic> data)
      : _authorUID = data['AuthorUID'],
        _lastUID = data['LastUID'],
        _parentID = data['ParentID'],
        _contributorUIDs = List<String>.from(data['ContributorUIDs']),
        _childrenIDs = List<String>.from(data['ChildrenIDs']),
        _topics = List<String>.from(data['Topics'] ?? []),
        _tagIDs = List<String>.from(data['TagIDs'] ?? []),
        _leadSpeakerUID = data['LeadSpeakerUID'] as String?,
        _isPeriodParent = data['IsPeriodParent'] == true;

  Map<String, Object?> toJson() {
    return {
      'AuthorUID': _authorUID,
      'LastUID': _lastUID,
      'ContributorUIDs': _contributorUIDs,
      'ParentID': _parentID,
      'ChildrenIDs': _childrenIDs,
      'Topics': _topics,
      'TagIDs': _tagIDs,
      'LeadSpeakerUID': _leadSpeakerUID,
      'IsPeriodParent': _isPeriodParent,
    };
  }

  String get lastUID => _lastUID;
  String get authorUID => _authorUID;
  String? get parentID => _parentID;
  String? get leadSpeakerUID => _leadSpeakerUID;
  bool get isPeriodParent => _isPeriodParent;
  bool get hasLeadSpeaker => _leadSpeakerUID != null && _leadSpeakerUID!.isNotEmpty;
  bool get hasChildren => _childrenIDs.isNotEmpty;
  bool get hasParent => _parentID != null && _parentID!.isNotEmpty;

  // ! change in the future to be unmodifiable and update accordingly
  List<String> get contributorUIDs => _contributorUIDs;
  List<String> get childrenPostIDs => _childrenIDs;
  List<String> get topics => UnmodifiableListView(_topics);
  List<String> get tagIDs => UnmodifiableListView(_tagIDs);

  void clearTopics() => _topics.clear();
  void addAllTopics(final List<String> newTopics) => _topics.addAll(newTopics);

  /// Adds [topic] if not already present.
  void addTopic(final String topic) {
    if (!_topics.contains(topic)) _topics.add(topic);
  }

  /// Removes [topic] if present.
  void removeTopic(final String topic) => _topics.remove(topic);

  void setTagIDs(final List<String> tagIDs) {
    _tagIDs
      ..clear()
      ..addAll(tagIDs);
  }

  void clearTagIDs() => _tagIDs.clear();

  void setLastUID(final String newLastUID) => _lastUID = newLastUID;
  void setLeadSpeakerUID(final String? uid) => _leadSpeakerUID = uid;
  void clearLeadSpeakerUID() => _leadSpeakerUID = null;

  void setParentID(final String? parentID) =>
      _parentID = (parentID == null || parentID.isEmpty) ? null : parentID;

  void clearParentID() => _parentID = null;

  void setIsPeriodParent(final bool value) => _isPeriodParent = value;

  void addChildID(final String childId) {
    if (childId.isEmpty || _childrenIDs.contains(childId)) return;
    _childrenIDs.add(childId);
  }

  void removeChildID(final String childId) => _childrenIDs.remove(childId);
}
