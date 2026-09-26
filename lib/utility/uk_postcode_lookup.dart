import 'dart:convert';

import 'package:http/http.dart' as http;

/// Whether [UkPostcodeLookup.classify] sees a full postcode or an outward code.
enum UkPostcodeKind { none, full, outcode }

/// Why a postcodes.io lookup failed.
enum UkPostcodeLookupFailure { invalid, failed }

class UkPostcodeLookupException implements Exception {
  const UkPostcodeLookupException(this.failure);

  final UkPostcodeLookupFailure failure;

  bool get isInvalid => failure == UkPostcodeLookupFailure.invalid;

  @override
  String toString() => 'UkPostcodeLookupException($failure)';
}

/// A UK postcode found in free text, or a signal that one is unfinished.
class UkPostcodeInAddress {
  const UkPostcodeInAddress({this.postcode, this.pending = false});

  /// Normalised postcode or outcode. Null when [pending] or nothing matched.
  final String? postcode;

  /// True while an inward code is only partly typed (`BT9 6`).
  final bool pending;
}

/// Centroid returned by postcodes.io for a full postcode or outcode.
class UkPostcodeGeo {
  const UkPostcodeGeo({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  /// Normalised postcode (`BT9 6AB`) or outcode (`BT9`).
  final String label;
  final double latitude;
  final double longitude;
}

/// Client for https://api.postcodes.io (CORS-enabled; safe on Flutter web).
class UkPostcodeLookup {
  UkPostcodeLookup({http.Client? client}) : _client = client;

  static const String _baseUrl = 'https://api.postcodes.io';

  /// Inward code: digit + two letters (`6AB`, `1AA`).
  static final RegExp _inward = RegExp(r'^\d[A-Z]{2}$');

  /// Outward code only, e.g. `BT9`, `BT12`, `G1`.
  static final RegExp _outcode = RegExp(r'^[A-Z]{1,2}\d[A-Z\d]?$');

  final http.Client? _client;

  static String compact(final String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static UkPostcodeKind classify(final String raw) {
    final compactForm = compact(raw);
    if (compactForm.isEmpty) return UkPostcodeKind.none;
    if (compactForm.length >= 5) {
      final inward = compactForm.substring(compactForm.length - 3);
      final outward = compactForm.substring(0, compactForm.length - 3);
      if (_inward.hasMatch(inward) && _outcode.hasMatch(outward)) {
        return UkPostcodeKind.full;
      }
    }
    if (_outcode.hasMatch(compactForm)) return UkPostcodeKind.outcode;
    return UkPostcodeKind.none;
  }

  /// `BT9 6AB`, or null if [raw] is not a full postcode.
  static String? normalizeFull(final String raw) {
    if (classify(raw) != UkPostcodeKind.full) return null;
    final compactForm = compact(raw);
    return '${compactForm.substring(0, compactForm.length - 3)} '
        '${compactForm.substring(compactForm.length - 3)}';
  }

  /// `BT9`, or null if [raw] is not an outward code.
  static String? normalizeOutcode(final String raw) {
    if (classify(raw) != UkPostcodeKind.outcode) return null;
    return compact(raw);
  }

  /// `BT9 6AB` or `BT37`, or null if [raw] is neither.
  static String? normalize(final String raw) {
    return normalizeFull(raw) ?? normalizeOutcode(raw);
  }

  /// Full postcode inside free text, e.g. `BT9 6AB` or `BT96AB`.
  static final RegExp _fullInText = RegExp(
    r'\b([A-Z]{1,2}\d[A-Z\d]?)\s*(\d[A-Z]{2})\b',
  );

  /// Outward code inside free text, e.g. `BT37`.
  static final RegExp _outcodeInText = RegExp(
    r'\b([A-Z]{1,2}\d[A-Z\d]?)\b',
  );

  /// Outcode followed by an unfinished inward code (`BT9 6`, `BT9 6A`).
  static final RegExp _partialInward = RegExp(
    r'\b[A-Z]{1,2}\d[A-Z\d]?\s+(\d[A-Z]{0,2})\b',
  );

  /// Last full postcode in [address], otherwise the last outcode.
  ///
  /// [UkPostcodeInAddress.pending] is true while someone is still typing
  /// the inward code, so callers can wait instead of geocoding `BT9`.
  static UkPostcodeInAddress extractFromAddress(final String address) {
    final upper = address.toUpperCase();
    final full = _fullInText.allMatches(upper).toList();
    if (full.isNotEmpty) {
      final match = full.last;
      final normalised = normalizeFull('${match.group(1)}${match.group(2)}');
      if (normalised != null) {
        return UkPostcodeInAddress(postcode: normalised);
      }
    }
    for (final match in _partialInward.allMatches(upper)) {
      final inward = match.group(1) ?? '';
      if (!_inward.hasMatch(inward)) {
        return const UkPostcodeInAddress(pending: true);
      }
    }
    String? lastOutcode;
    for (final match in _outcodeInText.allMatches(upper)) {
      final token = match.group(1);
      if (token == null) continue;
      final normalised = normalizeOutcode(token);
      if (normalised != null) lastOutcode = normalised;
    }
    if (lastOutcode == null) return const UkPostcodeInAddress();
    return UkPostcodeInAddress(postcode: lastOutcode);
  }

  /// Looks up a full postcode, or an outcode when [allowOutcode] is true.
  Future<UkPostcodeGeo> lookup(
    final String raw, {
    bool allowOutcode = true,
  }) async {
    final kind = classify(raw);
    if (kind == UkPostcodeKind.none ||
        (kind == UkPostcodeKind.outcode && !allowOutcode)) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.invalid);
    }

    final path = kind == UkPostcodeKind.full
        ? '/postcodes/${Uri.encodeComponent(normalizeFull(raw)!)}'
        : '/outcodes/${Uri.encodeComponent(normalizeOutcode(raw)!)}';

    final http.Response response;
    try {
      response = await _get(Uri.parse('$_baseUrl$path'));
    } catch (error) {
      if (error is UkPostcodeLookupException) rethrow;
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.failed);
    }

    if (response.statusCode == 404) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.invalid);
    }
    if (response.statusCode != 200) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.failed);
    }

    return _parseBody(response.body);
  }

  Future<http.Response> _get(final Uri uri) {
    final client = _client;
    if (client != null) return client.get(uri);
    return http.get(uri);
  }

  static UkPostcodeGeo _parseBody(final String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.failed);
    }
    final result = decoded['result'];
    if (result is! Map) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.failed);
    }
    final map = Map<String, dynamic>.from(result);
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    final label =
        ((map['postcode'] as String?) ?? (map['outcode'] as String?))?.trim();
    if (lat == null || lng == null || label == null || label.isEmpty) {
      throw const UkPostcodeLookupException(UkPostcodeLookupFailure.failed);
    }
    return UkPostcodeGeo(label: label, latitude: lat, longitude: lng);
  }
}
