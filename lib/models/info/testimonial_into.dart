import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory TestimonialInfo.fromMap(final String id, final Map<String, dynamic> data) {
    return TestimonialInfo(
      id: id,
      name: (data['name'] ?? '').toString(),
      church: (data['church'] ?? '').toString(),
      body: _parseBody(data['body']),
      imageSources: _parseImageSources(data),
      summary: (data['summary'] ?? '').toString(),
      updatedBy: (data['updatedBy'] ?? '').toString(),
      updatedAt: _parseUpdatedAt(data['updatedAt']),
      displayOrder: (data['displayOrder'] ?? 0) as int,
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
  void setImageSources(final List<String> value) => _imageSources = List<String>.from(value);
  void setName(final String value) => _name = value;
  void setSummary(final String value) => _summary = value;
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

  static List<dynamic> _parseBody(final dynamic rawBody) {
    if (rawBody == null) {
      return _defaultBody();
    }
    if (rawBody is List) {
      return _normalizeBody(List<dynamic>.from(rawBody));
    }
    if (rawBody is Map) {
      final ops = rawBody['ops'];
      if (ops is List) {
        return _normalizeBody(List<dynamic>.from(ops));
      }
    }
    if (rawBody is String) {
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
