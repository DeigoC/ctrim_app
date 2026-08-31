import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'info_parsing.dart';

class ChurchInfo {
  late String _id, _title, _analyticsTitle, _summary, _updatedBy;
  late String _location, _mapLink, _address;
  late String _heroImageSrc, _pastorsImageSrc;
  late List<dynamic> _body;
  late List<String> _galleryImageSources, _pastorUserIds;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  ChurchInfo({
    required String id,
    required String title,
    required String analyticsTitle,
    required List<dynamic> body,
    String heroImageSrc = '',
    String pastorsImageSrc = '',
    List<String>? galleryImageSources,
    List<String>? pastorUserIds,
    String summary = '',
    String location = '',
    String mapLink = '',
    String address = '',
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _title = title;
    _analyticsTitle = analyticsTitle;
    _body = List<dynamic>.from(body);
    _heroImageSrc = heroImageSrc.trim();
    _pastorsImageSrc = pastorsImageSrc.trim();
    _galleryImageSources =
        _dedupeGallery(galleryImageSources ?? const <String>[], _heroImageSrc);
    _pastorUserIds = List<String>.from(pastorUserIds ?? const <String>[]);
    _summary = summary;
    _location = location;
    _mapLink = mapLink;
    _address = address;
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory ChurchInfo.fromMap(final String id, final Map<String, dynamic> data) {
    final media = _parseMediaFromMap(data);
    return ChurchInfo(
      id: id,
      title: (data['title'] ?? data['Title'] ?? data['analyticTitle'] ?? '')
          .toString(),
      analyticsTitle:
          (data['analyticTitle'] ?? data['title'] ?? data['Title'] ?? '')
              .toString(),
      body: InfoParsing.parseBody(data['body']),
      heroImageSrc: media.heroImageSrc,
      pastorsImageSrc: media.pastorsImageSrc,
      galleryImageSources: media.galleryImageSources,
      pastorUserIds: _parseStringList(data['pastorUserIds']),
      summary: (data['summary'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      mapLink: (data['mapLink'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: InfoParsing.parseUpdatedAt(data['updatedAt']),
      displayOrder: InfoParsing.parseDisplayOrder(data['displayOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': _title,
      'analyticTitle': _analyticsTitle,
      'body': _body,
      'heroImageSrc': _heroImageSrc,
      'pastorsImageSrc': _pastorsImageSrc,
      'galleryImageSources': _galleryImageSources,
      'pastorUserIds': _pastorUserIds,
      'summary': _summary,
      'location': _location,
      'mapLink': _mapLink,
      'address': _address,
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
      'heroImageSrc': _heroImageSrc,
      'pastorsImageSrc': _pastorsImageSrc,
      'galleryImageSources': _galleryImageSources,
      'pastorUserIds': _pastorUserIds,
      'summary': _summary,
      'location': _location,
      'mapLink': _mapLink,
      'address': _address,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  String get analyticsTitle => _analyticsTitle;
  int get displayOrder => _displayOrder;
  String get id => _id;
  String get heroImageSrc => _heroImageSrc;
  String get pastorsImageSrc => _pastorsImageSrc;
  List<String> get galleryImageSources =>
      UnmodifiableListView<String>(_galleryImageSources);
  List<String> get pastorUserIds =>
      UnmodifiableListView<String>(_pastorUserIds);
  String get imgSrc => _heroImageSrc;
  String get summary => _summary;
  String get title => _title;
  String get location => _location;
  String get mapLink => _mapLink;
  String get address => _address;
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;

  bool get hasLocation => _location.trim().isNotEmpty;
  bool get hasMapLink => _mapLink.trim().isNotEmpty;
  bool get hasAddress => _address.trim().isNotEmpty;
  bool get hasHeroImage => _heroImageSrc.isNotEmpty;
  bool get hasPastorsImage => _pastorsImageSrc.isNotEmpty;
  bool get hasGalleryImages => _galleryImageSources.isNotEmpty;
  bool get hasPastors => _pastorUserIds.isNotEmpty;
  bool get hasPastorsBody => !InfoParsing.isEmptyBody(_body);
  bool get hasPastorsSection => hasPastorsImage || hasPastors || hasPastorsBody;

  void setAnalyticsTitle(final String value) => _analyticsTitle = value;
  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setHeroImageSrc(final String value) => _heroImageSrc = value.trim();
  void setPastorsImageSrc(final String value) =>
      _pastorsImageSrc = value.trim();
  void setGalleryImageSources(final List<String> value) =>
      _galleryImageSources = _dedupeGallery(value, _heroImageSrc);
  void setPastorUserIds(final List<String> value) =>
      _pastorUserIds = List<String>.from(value);
  void setSummary(final String value) => _summary = value;
  void setTitle(final String value) => _title = value;
  void setLocation(final String value) => _location = value;
  void setMapLink(final String value) => _mapLink = value;
  void setAddress(final String value) => _address = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;

  static List<String> _parseStringList(final dynamic raw) {
    if (raw is! List) return <String>[];
    return raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  static List<String> _dedupeGallery(
    final List<String> gallery,
    final String heroImageSrc,
  ) {
    final seen = <String>{};
    final results = <String>[];
    for (final raw in gallery) {
      final url = raw.trim();
      if (url.isEmpty || url == heroImageSrc || seen.contains(url)) {
        continue;
      }
      seen.add(url);
      results.add(url);
    }
    return results;
  }

  static _ChurchMediaFields _parseMediaFromMap(
    final Map<String, dynamic> data,
  ) {
    var heroImageSrc = (data['heroImageSrc'] ?? '').toString().trim();
    final pastorsImageSrc = (data['pastorsImageSrc'] ?? '').toString().trim();
    var galleryImageSources = _parseStringList(data['galleryImageSources']);

    final legacySources = InfoParsing.parseImageSources(data);
    if (heroImageSrc.isEmpty && legacySources.isNotEmpty) {
      heroImageSrc = legacySources.first;
      galleryImageSources = [
        ...galleryImageSources,
        ...legacySources.skip(1),
      ];
    }

    galleryImageSources = _dedupeGallery(galleryImageSources, heroImageSrc);

    return _ChurchMediaFields(
      heroImageSrc: heroImageSrc,
      pastorsImageSrc: pastorsImageSrc,
      galleryImageSources: galleryImageSources,
    );
  }
}

class _ChurchMediaFields {
  const _ChurchMediaFields({
    required this.heroImageSrc,
    required this.pastorsImageSrc,
    required this.galleryImageSources,
  });

  final String heroImageSrc;
  final String pastorsImageSrc;
  final List<String> galleryImageSources;
}
