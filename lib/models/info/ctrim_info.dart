import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
      title: (data['title'] ?? data['Title'] ?? data['analyticTitle'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      analyticsTitle: (data['analyticTitle'] ?? data['title'] ?? data['Title'] ?? '').toString(),
      body: _parseBody(data['body']),
      imageSources: _parseImageSources(data),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: _parseUpdatedAt(data['updatedAt']),
      displayOrder: (data['displayOrder'] ?? 0) as int,
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
  void setImageSources(final List<String> value) => _imageSources = List<String>.from(value);
  void setTitle(final String value) => _title = value;
  void setUpdatedAt(final DateTime value) => _updatedAt = value;
  void setUpdatedBy(final String value) => _updatedBy = value;

  static List<String> _parseImageSources(final Map<String, dynamic> data) {
    final dynamic imageSources = data['imageSources'];
    if (imageSources is List) {
      return imageSources.map((e) => e.toString()).where((e) => e.isNotEmpty && e.toUpperCase() != 'TODO').toList();
    }

    final String fallback = (data['imgSrc'] ?? '').toString();
    if (fallback.isEmpty || fallback.toUpperCase() == 'TODO') {
      return <String>[];
    }
    return <String>[fallback];
  }

  static List<dynamic> _parseBody(final dynamic rawBody) {
    if (rawBody == null) {
      return _defaultBody();
    }
    if (rawBody is List) {
      debugPrint('Parsing body list: $rawBody');
      return _normalizeBody(List<dynamic>.from(rawBody));
    }
    if (rawBody is Map) {
      final ops = rawBody['ops'];
      if (ops is List) {
        return _normalizeBody(List<dynamic>.from(ops));
      }
    }
    if (rawBody is String) {
      debugPrint('Parsing body string: $rawBody');
      final parsed = _parseBodyString(rawBody);
      if (parsed != null) {
        return parsed;
      }

      final text = rawBody.trim();
      if (text.isNotEmpty) {
        return <dynamic>[
          <String, dynamic>{'insert': '$text\n'}
        ];
      }
    }
    return _defaultBody();
  }

  static List<dynamic>? _parseBodyString(final String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // Handles legacy payloads like "[{\"insert\":\"...\"}]".
    if (trimmed.startsWith('"[') && trimmed.endsWith(']"')) {
      final candidate = trimmed.substring(1, trimmed.length - 1).replaceAll('\\"', '"');
      final decodedLegacy = _tryJsonDecode(candidate);
      if (decodedLegacy is List) {
        return _normalizeBody(List<dynamic>.from(decodedLegacy));
      }
      if (decodedLegacy is Map) {
        final legacyOps = decodedLegacy['ops'];
        if (legacyOps is List) {
          return _normalizeBody(List<dynamic>.from(legacyOps));
        }
      }
    }

    dynamic decoded = trimmed;
    for (int i = 0; i < 3; i++) {
      if (decoded is! String) {
        break;
      }

      final parsed = _tryJsonDecode(decoded.trim());
      if (parsed != null) {
        decoded = parsed;
        continue;
      }

      final unwrapped = _unwrapQuoted(decoded.trim());
      if (unwrapped != decoded.trim()) {
        decoded = unwrapped;
        continue;
      }

      final unescaped = _unescapeLegacyString(decoded.trim());
      if (unescaped != decoded.trim()) {
        decoded = unescaped;
        continue;
      }
      break;
    }

    if (decoded is List) {
      return _normalizeBody(List<dynamic>.from(decoded));
    }
    if (decoded is Map) {
      final ops = decoded['ops'];
      if (ops is List) {
        return _normalizeBody(List<dynamic>.from(ops));
      }
    }

    return null;
  }

  static dynamic _tryJsonDecode(final String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  static String _unwrapQuoted(final String value) {
    if (value.length < 2) {
      return value;
    }

    final startsWithDoubleQuote = value.startsWith('"') && value.endsWith('"');
    final startsWithSingleQuote = value.startsWith('\'') && value.endsWith('\'');
    if (startsWithDoubleQuote || startsWithSingleQuote) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static String _unescapeLegacyString(final String value) {
    return value.replaceAll('\\\\', '\\').replaceAll('\\"', '"').replaceAll("\\'", "'");
  }

  static List<dynamic> _normalizeBody(final List<dynamic> body) {
    if (body.isEmpty) {
      return _defaultBody();
    }

    final normalized = <dynamic>[];
    for (final op in body) {
      if (op is Map && op['insert'] is String && (op['insert'] as String).isEmpty) {
        continue;
      }
      normalized.add(op);
    }

    if (normalized.isEmpty) {
      return _defaultBody();
    }

    final lastOp = normalized.last;
    if (lastOp is Map && lastOp['insert'] is String && !(lastOp['insert'] as String).endsWith('\n')) {
      normalized.add(const <String, dynamic>{'insert': '\n'});
    }

    return normalized;
  }

  static List<dynamic> _defaultBody() {
    return <dynamic>[
      <String, dynamic>{'insert': '\n'}
    ];
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
