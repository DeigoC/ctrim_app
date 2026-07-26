import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'info_parsing.dart';

class TestimonialInfo {
  late String _id, _name, _church, _summary, _updatedBy;
  late List<dynamic> _body;
  late List<String> _imageSources;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  TestimonialInfo({
    required String id,
    required String name,
    required String church,
    required List<dynamic> body,
    List<String>? imageSources,
    String summary = '',
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _name = name;
    _church = church;
    _body = List<dynamic>.from(body);
    _imageSources = List<String>.from(imageSources ?? const <String>[]);
    _summary = summary;
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory TestimonialInfo.fromMap(
      final String id, final Map<String, dynamic> data) {
    return TestimonialInfo(
      id: id,
      name: (data['name'] ?? '').toString(),
      church: (data['church'] ?? '').toString(),
      body: InfoParsing.parseBody(data['body']),
      imageSources: InfoParsing.parseImageSources(data),
      summary: (data['summary'] ?? '').toString(),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: InfoParsing.parseUpdatedAt(data['updatedAt']),
      displayOrder: InfoParsing.parseDisplayOrder(data['displayOrder']),
    );
  }

  String encode() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'name': _name,
      'church': _church,
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
      'name': _name,
      'church': _church,
      'body': _body,
      'imageSources': _imageSources,
      'summary': _summary,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  String get church => _church;
  int get displayOrder => _displayOrder;
  String get id => _id;
  List<String> get imageSources => UnmodifiableListView<String>(_imageSources);
  String get imgSrc => _imageSources.isNotEmpty ? _imageSources.first : '';
  String get name => _name;
  String get summary => _summary;
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;

  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setChurch(final String value) => _church = value;
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setImageSources(final List<String> value) =>
      _imageSources = List<String>.from(value);
  void setName(final String value) => _name = value;
  void setSummary(final String value) => _summary = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;
}
