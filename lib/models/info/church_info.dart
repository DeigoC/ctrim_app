import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'church_social.dart';
import 'info_parsing.dart';

/// Full location hub vs nested outreach under a parent church.
enum ChurchKind {
  church,
  outreach;

  static ChurchKind fromStorage(final dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    if (value == ChurchKind.outreach.name) return ChurchKind.outreach;
    return ChurchKind.church;
  }

  String get storageValue => name;
}

class ChurchInfo {
  late String _id, _title, _analyticsTitle, _summary, _updatedBy;
  late String _location, _mapLink, _address, _geoPostcode;
  double? _latitude, _longitude;
  late String _heroImageSrc, _pastorsImageSrc;
  late String _parentChurchId;
  late ChurchKind _kind;
  late List<dynamic> _body;
  late List<String> _galleryImageSources, _pastorUserIds;
  late List<ChurchSocialLink> _socials;
  late DateTime _updatedAt;
  int _displayOrder = 0;

  ChurchInfo({
    required String id,
    required String title,
    required String analyticsTitle,
    required List<dynamic> body,
    ChurchKind kind = ChurchKind.church,
    String parentChurchId = '',
    String heroImageSrc = '',
    String pastorsImageSrc = '',
    List<String>? galleryImageSources,
    List<String>? pastorUserIds,
    List<ChurchSocialLink>? socials,
    String summary = '',
    String location = '',
    String mapLink = '',
    String address = '',
    double? latitude,
    double? longitude,
    String geoPostcode = '',
    String updatedBy = '',
    DateTime? updatedAt,
    int displayOrder = 0,
  }) {
    _id = id;
    _title = title;
    _analyticsTitle = analyticsTitle;
    _body = List<dynamic>.from(body);
    _kind = kind;
    _parentChurchId = parentChurchId.trim();
    _heroImageSrc = heroImageSrc.trim();
    _pastorsImageSrc = pastorsImageSrc.trim();
    _galleryImageSources =
        _dedupeGallery(galleryImageSources ?? const <String>[], _heroImageSrc);
    _pastorUserIds = List<String>.from(pastorUserIds ?? const <String>[]);
    _socials =
        List<ChurchSocialLink>.from(socials ?? const <ChurchSocialLink>[]);
    _summary = summary;
    _location = location;
    _mapLink = mapLink;
    _address = address;
    _applyGeo(
      latitude: latitude,
      longitude: longitude,
      geoPostcode: geoPostcode,
    );
    _updatedBy = updatedBy;
    _updatedAt = updatedAt ?? DateTime.now();
    _displayOrder = displayOrder;
  }

  factory ChurchInfo.fromMap(final String id, final Map<String, dynamic> data) {
    final media = _parseMediaFromMap(data);
    final kind = ChurchKind.fromStorage(data['kind']);
    final parentChurchId = (data['parentChurchId'] ?? '').toString().trim();
    return ChurchInfo(
      id: id,
      title: (data['title'] ?? data['Title'] ?? data['analyticTitle'] ?? '')
          .toString(),
      analyticsTitle:
          (data['analyticTitle'] ?? data['title'] ?? data['Title'] ?? '')
              .toString(),
      body: InfoParsing.parseBody(data['body']),
      kind: kind,
      parentChurchId: kind == ChurchKind.outreach ? parentChurchId : '',
      heroImageSrc: media.heroImageSrc,
      pastorsImageSrc: media.pastorsImageSrc,
      galleryImageSources: media.galleryImageSources,
      pastorUserIds: _parseStringList(data['pastorUserIds']),
      socials: ChurchSocialLink.parseList(data['socials']),
      summary: (data['summary'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      mapLink: (data['mapLink'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      geoPostcode: (data['geoPostcode'] ?? '').toString(),
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
      'kind': _kind.storageValue,
      'parentChurchId': _kind == ChurchKind.outreach ? _parentChurchId : '',
      'heroImageSrc': _heroImageSrc,
      'pastorsImageSrc': _pastorsImageSrc,
      'galleryImageSources': _galleryImageSources,
      'pastorUserIds': _pastorUserIds,
      'socials': _socials.map((s) => s.toJson()).toList(),
      'summary': _summary,
      'location': _location,
      'mapLink': _mapLink,
      'address': _address,
      'latitude': _latitude,
      'longitude': _longitude,
      'geoPostcode': _geoPostcode.isEmpty ? null : _geoPostcode,
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
      'kind': _kind.storageValue,
      'parentChurchId': _kind == ChurchKind.outreach ? _parentChurchId : '',
      'heroImageSrc': _heroImageSrc,
      'pastorsImageSrc': _pastorsImageSrc,
      'galleryImageSources': _galleryImageSources,
      'pastorUserIds': _pastorUserIds,
      'socials': _socials.map((s) => s.toJson()).toList(),
      'summary': _summary,
      'location': _location,
      'mapLink': _mapLink,
      'address': _address,
      'latitude': _latitude,
      'longitude': _longitude,
      'geoPostcode': _geoPostcode.isEmpty ? null : _geoPostcode,
      'updatedBy': _updatedBy,
      'updatedAt': _updatedAt.millisecondsSinceEpoch,
      'displayOrder': _displayOrder,
    };
  }

  List<dynamic> get body => UnmodifiableListView<dynamic>(_body);
  String get analyticsTitle => _analyticsTitle;
  int get displayOrder => _displayOrder;
  String get id => _id;
  ChurchKind get kind => _kind;
  String get parentChurchId => _parentChurchId;
  String get heroImageSrc => _heroImageSrc;
  String get pastorsImageSrc => _pastorsImageSrc;
  List<String> get galleryImageSources =>
      UnmodifiableListView<String>(_galleryImageSources);
  List<String> get pastorUserIds =>
      UnmodifiableListView<String>(_pastorUserIds);
  List<ChurchSocialLink> get socials =>
      UnmodifiableListView<ChurchSocialLink>(_socials);
  String get imgSrc => _heroImageSrc;
  String get summary => _summary;
  String get title => _title;
  String get location => _location;
  String get mapLink => _mapLink;
  String get address => _address;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get geoPostcode => _geoPostcode;
  DateTime get updatedAt => _updatedAt;
  String get updatedBy => _updatedBy;

  bool get isFullChurch => _kind == ChurchKind.church;
  bool get isOutreach => _kind == ChurchKind.outreach;
  bool get hasParentChurch => isOutreach && _parentChurchId.trim().isNotEmpty;
  bool get hasLocation => _location.trim().isNotEmpty;
  bool get hasMapLink => _mapLink.trim().isNotEmpty;
  bool get hasAddress => _address.trim().isNotEmpty;
  bool get hasCoordinates => _latitude != null && _longitude != null;
  bool get hasHeroImage => _heroImageSrc.isNotEmpty;
  bool get hasPastorsImage => _pastorsImageSrc.isNotEmpty;
  bool get hasGalleryImages => _galleryImageSources.isNotEmpty;
  bool get hasPastors => _pastorUserIds.isNotEmpty;
  bool get hasPastorsBody => !InfoParsing.isEmptyBody(_body);
  bool get hasPastorsSection => hasPastorsImage || hasPastors || hasPastorsBody;
  bool get hasSocials => _socials.isNotEmpty;

  void setAnalyticsTitle(final String value) => _analyticsTitle = value;
  void setBody(final List<dynamic> value) => _body = List<dynamic>.from(value);
  void setDisplayOrder(final int value) => _displayOrder = value;
  void setKind(final ChurchKind value) {
    _kind = value;
    if (value != ChurchKind.outreach) {
      _parentChurchId = '';
    }
  }

  void setParentChurchId(final String value) {
    _parentChurchId = value.trim();
  }

  void setHeroImageSrc(final String value) => _heroImageSrc = value.trim();
  void setPastorsImageSrc(final String value) =>
      _pastorsImageSrc = value.trim();
  void setGalleryImageSources(final List<String> value) =>
      _galleryImageSources = _dedupeGallery(value, _heroImageSrc);
  void setPastorUserIds(final List<String> value) =>
      _pastorUserIds = List<String>.from(value);
  void setSocials(final List<ChurchSocialLink> value) =>
      _socials = List<ChurchSocialLink>.from(value);
  void setSummary(final String value) => _summary = value;
  void setTitle(final String value) => _title = value;
  void setLocation(final String value) => _location = value;
  void setMapLink(final String value) => _mapLink = value;
  void setAddress(final String value) => _address = value;

  void setGeo({
    required final double? latitude,
    required final double? longitude,
    final String geoPostcode = '',
  }) {
    _applyGeo(
      latitude: latitude,
      longitude: longitude,
      geoPostcode: geoPostcode,
    );
  }

  void _applyGeo({
    required final double? latitude,
    required final double? longitude,
    required final String geoPostcode,
  }) {
    if (latitude == null || longitude == null) {
      _latitude = null;
      _longitude = null;
      _geoPostcode = '';
      return;
    }
    _latitude = latitude;
    _longitude = longitude;
    _geoPostcode = geoPostcode.trim();
  }

  static double? _parseDouble(final dynamic raw) {
    if (raw is num) return raw.toDouble();
    return null;
  }

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
