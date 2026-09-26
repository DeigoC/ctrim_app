import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/map_area.dart';
import '../common/app_dialog.dart';
import 'area_map.dart';

/// Pannable map. A tap moves the church pin. Pops a [LatLng] on save.
class AdjustPinDialog extends StatefulWidget {
  const AdjustPinDialog({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<AdjustPinDialog> createState() => _AdjustPinDialogState();
}

class _AdjustPinDialogState extends State<AdjustPinDialog> {
  late double _latitude = widget.latitude;
  late double _longitude = widget.longitude;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppDialog(
      scrollable: false,
      icon: Icons.edit_location_alt_outlined,
      title: l10n.churchEditorAdjustPinTitle,
      message: l10n.churchEditorAdjustPinHelp,
      child: AreaMap(
        height: 320,
        interactive: true,
        pinZoom: MapArea.churchPinZoom,
        maxZoom: 18,
        pins: [
          MapAreaPin(latitude: _latitude, longitude: _longitude),
        ],
        onTap: (point) => setState(() {
          _latitude = point.latitude;
          _longitude = point.longitude;
        }),
      ),
      actions: AppDialogActions(
        cancelLabel: l10n.cancel,
        confirmLabel: l10n.save,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () => Navigator.of(context).pop(
          LatLng(_latitude, _longitude),
        ),
      ),
    );
  }
}
