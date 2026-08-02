import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'info_parsing.dart';

class CtrimInfo {
  late String _id, _title, _description, _analyticsTitle, _updatedBy;
  late List<dynamic> _body;
  late List<String> _imageSources;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  CtrimInfo({
    required String id,
    required String title,
    required String description,
    required String analyticsTitle,
    required List<dynamic> body,
    List<String>? imageSources,
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _title = title;
    _description = description;
    _analyticsTitle = analyticsTitle;
    _body = List<dynamic>.from(body);
    _imageSources = List<String>.from(imageSources ?? const <String>[]);
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory CtrimInfo.fromMap(final String id, final Map<String, dynamic> data) {
    return CtrimInfo(
      id: id,
      title: (data['title'] ?? data['Title'] ?? data['analyticTitle'] ?? '')
          .toString(),
      description: (data['description'] ?? '').toString(),
      analyticsTitle:
          (data['analyticTitle'] ?? data['title'] ?? data['Title'] ?? '')
              .toString(),
      body: InfoParsing.parseBody(data['body']),
      imageSources: InfoParsing.parseImageSources(data),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: InfoParsing.parseUpdatedAt(data['updatedAt']),
      displayOrder: InfoParsing.parseDisplayOrder(data['displayOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': _title,
      'description': _description,
      'analyticTitle': _analyticsTitle,
      'body': _body,
      'imageSources': _imageSources,
      'updatedBy': _updatedBy,
      'updatedAt': Timestamp.fromDate(_updatedAt),
      'displayOrder': _displayOrder,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': _id,
      'title': _title,
      'description': _description,
      'analyticTitle': _analyticsTitle,
      'body': _body,
      'imageSources': _imageSources,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  String get analyticsTitle => _analyticsTitle;
  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  String get description => _description;
  int get displayOrder => _displayOrder;
  String get id => _id;
  List<String> get imageSources => UnmodifiableListView<String>(_imageSources);
  String get imgSrc => _imageSources.isNotEmpty ? _imageSources.first : '';
  String get title => _title;
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;

  void setAnalyticsTitle(final String value) => _analyticsTitle = value;
  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setDescription(final String value) => _description = value;
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setImageSources(final List<String> value) =>
      _imageSources = List<String>.from(value);
  void setTitle(final String value) => _title = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;
}
