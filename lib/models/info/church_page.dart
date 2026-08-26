import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'info_parsing.dart';

/// Nested info page under a church hub (`…/items/{churchId}/pages/{pageId}`).
class ChurchPage {
  late String _id, _churchId, _title, _summary, _updatedBy;
  late List<dynamic> _body;
  late List<String> _imageSources;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  ChurchPage({
    required String id,
    required String churchId,
    required String title,
    required List<dynamic> body,
    List<String>? imageSources,
    String summary = '',
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _churchId = churchId;
    _title = title;
    _body = List<dynamic>.from(body);
    _imageSources = List<String>.from(imageSources ?? const <String>[]);
    _summary = summary;
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory ChurchPage.fromMap(
    final String id,
    final String churchId,
    final Map<String, dynamic> data,
  ) {
    return ChurchPage(
      id: id,
      churchId: (data['churchId'] ?? churchId).toString(),
      title: (data['title'] ?? data['Title'] ?? '').toString(),
      body: InfoParsing.parseBody(data['body']),
      imageSources: InfoParsing.parseImageSources(data),
      summary: (data['summary'] ?? '').toString(),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: InfoParsing.parseUpdatedAt(data['updatedAt']),
      displayOrder: InfoParsing.parseDisplayOrder(data['displayOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': _title,
      'body': _body,
      'imageSources': _imageSources,
      'summary': _summary,
      'updatedBy': _updatedBy,
      'updatedAt': Timestamp.fromDate(_updatedAt),
      'displayOrder': _displayOrder,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': _id,
      'churchId': _churchId,
      'title': _title,
      'body': _body,
      'imageSources': _imageSources,
      'summary': _summary,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  String get id => _id;
  String get churchId => _churchId;
  String get title => _title;
  String get summary => _summary;
  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  List<String> get imageSources => UnmodifiableListView<String>(_imageSources);
  String get imgSrc => _imageSources.isNotEmpty ? _imageSources.first : '';
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;
  int get displayOrder => _displayOrder;

  void setTitle(final String value) => _title = value;
  void setSummary(final String value) => _summary = value;
  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setImageSources(final List<String> value) =>
      _imageSources = List<String>.from(value);
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;
}
