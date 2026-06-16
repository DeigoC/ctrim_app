import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChurchInfo {
  late String _id, _title, _analyticsTitle, _summary, _updatedBy;
  late List<dynamic> _body;
  late List<String> _imageSources;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  ChurchInfo({
    required String id,
    required String title,
    required String analyticsTitle,
    required List<dynamic> body,
    List<String>? imageSources,
    String summary = '',
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _title = title;
    _analyticsTitle = analyticsTitle;
    _body = List<dynamic>.from(body);
    _imageSources = List<String>.from(imageSources ?? const <String>[]);
    _summary = summary;
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory ChurchInfo.fromMap(final String id, final Map<String, dynamic> data) {
    return ChurchInfo(
      id: id,
      title: (data['title'] ?? data['Title'] ?? data['analyticTitle'] ?? '').toString(),
      analyticsTitle: (data['analyticTitle'] ?? data['title'] ?? data['Title'] ?? '').toString(),
      body: List<dynamic>.from(data['body'] ?? const <dynamic>[]),
      imageSources: _parseImageSources(data),
      summary: (data['summary'] ?? '').toString(),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: _parseUpdatedAt(data['updatedAt']),
      displayOrder: (data['displayOrder'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': _title,
      'analyticTitle': _analyticsTitle,
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
      'title': _title,
      'analyticTitle': _analyticsTitle,
      'body': _body,
      'imageSources': _imageSources,
      'summary': _summary,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  String get analyticsTitle => _analyticsTitle;
  int get displayOrder => _displayOrder;
  String get id => _id;
  List<String> get imageSources => UnmodifiableListView<String>(_imageSources);
  String get imgSrc => _imageSources.isNotEmpty ? _imageSources.first : '';
  String get summary => _summary;
  String get title => _title;
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;

  void setAnalyticsTitle(final String value) => _analyticsTitle = value;
  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setImageSources(final List<String> value) => _imageSources = List<String>.from(value);
  void setSummary(final String value) => _summary = value;
  void setTitle(final String value) => _title = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;

  static List<String> _parseImageSources(final Map<String, dynamic> data) {
    final dynamic imageSources = data['imageSources'];
    if (imageSources is List) {
      return imageSources.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final String fallback = (data['imgSrc'] ?? '').toString();
    return fallback.isEmpty ? <String>[] : <String>[fallback];
  }

  static DateTime _parseUpdatedAt(final dynamic rawValue) {
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }
    if (rawValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawValue);
    }
    return DateTime.now();
  }
}
