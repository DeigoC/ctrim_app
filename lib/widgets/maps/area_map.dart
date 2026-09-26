import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/map_area.dart';
import 'open_free_map_style.dart';

/// Non-interactive by default so a surrounding scroll view keeps working.
class AreaMap extends StatefulWidget {
  const AreaMap({
    super.key,
    this.circles = const [],
    this.pins = const [],
    this.interactive = false,
    this.maxZoom,
    this.pinZoom = MapArea.churchPinZoom,
    this.onTap,
    this.height = 180,
  });

  final List<MapAreaCircle> circles;
  final List<MapAreaPin> pins;
  final bool interactive;
  final double? maxZoom;
  final double pinZoom;
  final ValueChanged<LatLng>? onTap;
  final double height;

  @override
  State<AreaMap> createState() => _AreaMapState();
}

class _AreaMapState extends State<AreaMap> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: FutureBuilder<vt.Style>(
                key: ValueKey(_attempt),
                future: OpenFreeMapStyle.load(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _MapStatus(
                      icon: Icons.wifi_off_outlined,
                      message: l10n.mapLoadFailed,
                      onRetry: () => setState(() => _attempt++),
                    );
                  }
                  final style = snapshot.data;
                  if (style == null) {
                    return const _MapStatus(
                      icon: Icons.map_outlined,
                      message: '',
                    );
                  }
                  return _MapCanvas(
                    style: style,
                    circles: widget.circles,
                    pins: widget.pins,
                    interactive: widget.interactive,
                    maxZoom: widget.maxZoom,
                    pinZoom: widget.pinZoom,
                    onTap: widget.onTap,
                    colorScheme: colorScheme,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => launchUrlString(
              OpenFreeMapStyle.copyrightUrl,
              mode: LaunchMode.externalApplication,
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.mapAttribution),
          ),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.style,
    required this.circles,
    required this.pins,
    required this.interactive,
    required this.maxZoom,
    required this.pinZoom,
    required this.onTap,
    required this.colorScheme,
  });

  final vt.Style style;
  final List<MapAreaCircle> circles;
  final List<MapAreaPin> pins;
  final bool interactive;
  final double? maxZoom;
  final double pinZoom;
  final ValueChanged<LatLng>? onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final box = MapArea.bounds(circles: circles, pins: pins);
    final fit = box != null && !box.isDegenerate
        ? CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(box.south, box.west),
              LatLng(box.north, box.east),
            ),
            padding: const EdgeInsets.all(28),
            maxZoom: maxZoom ?? pinZoom,
          )
        : null;
    final center = _center();
    final flags = interactive
        ? InteractiveFlag.all & ~InteractiveFlag.rotate
        : InteractiveFlag.none;

    final map = FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: pinZoom,
        initialCameraFit: fit,
        minZoom: 4,
        maxZoom: interactive ? (maxZoom ?? 18) : (maxZoom ?? pinZoom),
        backgroundColor: colorScheme.surfaceContainerHighest,
        interactionOptions: InteractionOptions(flags: flags),
        onTap: onTap == null ? null : (tapPosition, point) => onTap!(point),
      ),
      children: [
        vt.VectorTileLayer(
          theme: style.theme,
          tileProviders: style.providers,
          rasterSources: style.rasterSources,
          sprites: style.sprites,
        ),
        if (circles.isNotEmpty)
          CircleLayer(
            circles: [
              for (final circle in circles)
                CircleMarker(
                  point: LatLng(circle.latitude, circle.longitude),
                  radius: circle.radiusMeters,
                  useRadiusInMeter: true,
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  borderStrokeWidth: 2,
                  borderColor: colorScheme.primary,
                ),
            ],
          ),
        if (pins.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final pin in pins)
                Marker(
                  point: LatLng(pin.latitude, pin.longitude),
                  width: 36,
                  height: 36,
                  alignment:
                      pin.origin ? Alignment.center : Alignment.topCenter,
                  child: Icon(
                    pin.origin ? Icons.my_location : Icons.location_on,
                    color:
                        pin.origin ? colorScheme.tertiary : colorScheme.primary,
                    size: 32,
                  ),
                ),
            ],
          ),
      ],
    );

    if (interactive) return map;
    return IgnorePointer(child: map);
  }

  LatLng _center() {
    if (pins.isNotEmpty) {
      return LatLng(pins.first.latitude, pins.first.longitude);
    }
    if (circles.isNotEmpty) {
      return LatLng(circles.first.latitude, circles.first.longitude);
    }
    return const LatLng(54.6, -5.93);
  }
}

class _MapStatus extends StatelessWidget {
  const _MapStatus({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text(l10n.mapRetry)),
          ],
        ],
      ),
    );
  }
}
