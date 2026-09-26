import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';

/// Process-wide OpenFreeMap Liberty style. No API key.
class OpenFreeMapStyle {
  OpenFreeMapStyle._();

  static const String libertyUri =
      'https://tiles.openfreemap.org/styles/liberty';

  static const String copyrightUrl = 'https://www.openstreetmap.org/copyright';

  static Future<Style>? _loading;

  static Future<Style> load() {
    final existing = _loading;
    if (existing != null) return existing;
    final future = const StyleReader(
      uri: libertyUri,
      logger: Logger.noop(),
    ).read();
    _loading = future;
    future.then((_) {}, onError: (_) {
      if (identical(_loading, future)) _loading = null;
    });
    return future;
  }
}
