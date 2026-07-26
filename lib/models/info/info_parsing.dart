import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore / cache parsing for churches, testimonials, and CTRIM info.
abstract final class InfoParsing {
  static List<String> parseImageSources(final Map<String, dynamic> data) {
    final dynamic imageSources = data['imageSources'];
    if (imageSources is List) {
      return imageSources
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty && e.toUpperCase() != 'TODO')
          .toList();
    }

    final String fallback = (data['imgSrc'] ?? '').toString();
    if (fallback.isEmpty || fallback.toUpperCase() == 'TODO') {
      return <String>[];
    }
    return <String>[fallback];
  }

  static List<dynamic> parseBody(final dynamic rawBody) {
    if (rawBody == null) {
      return defaultBody();
    }
    if (rawBody is List) {
      return normalizeBody(List<dynamic>.from(rawBody));
    }
    if (rawBody is Map) {
      final ops = rawBody['ops'];
      if (ops is List) {
        return normalizeBody(List<dynamic>.from(ops));
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
    return defaultBody();
  }

  static DateTime parseUpdatedAt(final dynamic rawValue) {
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }
    if (rawValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawValue);
    }
    if (rawValue is num) {
      return DateTime.fromMillisecondsSinceEpoch(rawValue.toInt());
    }
    return DateTime.now();
  }

  static int parseDisplayOrder(final dynamic rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? 0;
    }
    return 0;
  }

  static List<dynamic> normalizeBody(final List<dynamic> body) {
    if (body.isEmpty) {
      return defaultBody();
    }

    final normalized = <dynamic>[];
    for (final op in body) {
      if (op is Map &&
          op['insert'] is String &&
          (op['insert'] as String).isEmpty) {
        continue;
      }
      normalized.add(op);
    }

    if (normalized.isEmpty) {
      return defaultBody();
    }

    final lastOp = normalized.last;
    if (lastOp is Map &&
        lastOp['insert'] is String &&
        !(lastOp['insert'] as String).endsWith('\n')) {
      normalized.add(const <String, dynamic>{'insert': '\n'});
    }

    return normalized;
  }

  static List<dynamic> defaultBody() {
    return <dynamic>[
      <String, dynamic>{'insert': '\n'}
    ];
  }

  static List<dynamic>? _parseBodyString(final String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // Handles legacy payloads like "[{\"insert\":\"...\"}]".
    if (trimmed.startsWith('"[') && trimmed.endsWith(']"')) {
      final candidate =
          trimmed.substring(1, trimmed.length - 1).replaceAll('\\"', '"');
      final decodedLegacy = _tryJsonDecode(candidate);
      if (decodedLegacy is List) {
        return normalizeBody(List<dynamic>.from(decodedLegacy));
      }
      if (decodedLegacy is Map) {
        final legacyOps = decodedLegacy['ops'];
        if (legacyOps is List) {
          return normalizeBody(List<dynamic>.from(legacyOps));
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
      return normalizeBody(List<dynamic>.from(decoded));
    }
    if (decoded is Map) {
      final ops = decoded['ops'];
      if (ops is List) {
        return normalizeBody(List<dynamic>.from(ops));
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
    final startsWithSingleQuote =
        value.startsWith('\'') && value.endsWith('\'');
    if (startsWithDoubleQuote || startsWithSingleQuote) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static String _unescapeLegacyString(final String value) {
    return value
        .replaceAll('\\\\', '\\')
        .replaceAll('\\"', '"')
        .replaceAll("\\'", "'");
  }
}
