import 'package:flutter/material.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../common/app_dialog.dart';

/// Palette + HSV shade square + hex field for optional catalog tag colours.
class CatalogColorField extends StatefulWidget {
  const CatalogColorField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  State<CatalogColorField> createState() => _CatalogColorFieldState();
}

class _CatalogColorFieldState extends State<CatalogColorField> {
  static const _fallback = Color(0xFF6B4EAA);

  late HSVColor _hsv;
  bool _syncingController = false;

  @override
  void initState() {
    super.initState();
    _hsv =
        _hsvFromText(widget.controller.text) ?? HSVColor.fromColor(_fallback);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  HSVColor? _hsvFromText(String text) {
    final color = UserTagHelpers.parseColor(text);
    return color == null ? null : HSVColor.fromColor(color);
  }

  Color? get _selectedColor =>
      UserTagHelpers.parseColor(widget.controller.text);

  String? get _selectedHex =>
      UserTagHelpers.normalizeHex(widget.controller.text);

  void _onControllerChanged() {
    if (_syncingController) return;
    final hsv = _hsvFromText(widget.controller.text);
    if (hsv == null) {
      setState(() {});
      return;
    }
    if (UserTagHelpers.formatHex(hsv.toColor()) ==
        UserTagHelpers.formatHex(_hsv.toColor())) {
      return;
    }
    setState(() => _hsv = hsv);
  }

  void _writeHex(String hex) {
    _syncingController = true;
    widget.controller.text = hex;
    _syncingController = false;
  }

  void _clearColor() {
    _writeHex('');
    setState(() {});
  }

  void _applyColor(Color color, {String? hex}) {
    _hsv = HSVColor.fromColor(color);
    _writeHex(hex ?? UserTagHelpers.formatHex(color));
    setState(() {});
  }

  void _applyHsv(HSVColor hsv) {
    _applyColor(hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedColor;
    final selectedHex = _selectedHex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SwatchButton(
              tooltip: l10n.catalogColorNone,
              selected: selected == null,
              onTap: _clearColor,
              child: Icon(
                Icons.format_color_reset_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            for (final hex in UserTagHelpers.presetHexes)
              _SwatchButton(
                tooltip: hex,
                selected: selectedHex == hex,
                color: UserTagHelpers.parseColor(hex),
                onTap: () {
                  final color = UserTagHelpers.parseColor(hex);
                  if (color == null) return;
                  _applyColor(color, hex: hex);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ShadeSquare(
          hsv: _hsv,
          semanticLabel: l10n.catalogColorShade,
          onChanged: _applyHsv,
        ),
        const SizedBox(height: 8),
        _HueBar(
          hue: _hsv.hue,
          semanticLabel: l10n.catalogColorHue,
          onChanged: (hue) => _applyHsv(_hsv.withHue(hue)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          decoration: AppDialog.inputDecoration(
            label: widget.label,
            hint: widget.hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: _PreviewDot(color: selected),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.selected,
    required this.onTap,
    required this.tooltip,
    this.color,
    this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: color ?? colorScheme.surfaceContainerHighest,
          shape: CircleBorder(
            side: BorderSide(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.35),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 28,
              height: 28,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _ShadeSquare extends StatelessWidget {
  const _ShadeSquare({
    required this.hsv,
    required this.semanticLabel,
    required this.onChanged,
  });

  final HSVColor hsv;
  final String semanticLabel;
  final ValueChanged<HSVColor> onChanged;

  void _update(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (local.dx / size.width).clamp(0.0, 1.0);
    final value = 1.0 - (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return Semantics(
      label: semanticLabel,
      slider: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: SizedBox(
          height: 120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) =>
                    _update(details.localPosition, constraints.biggest),
                onPanUpdate: (details) =>
                    _update(details.localPosition, constraints.biggest),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, hueColor],
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(
                          hsv.saturation * 2 - 1,
                          (1 - hsv.value) * 2 - 1,
                        ),
                        child: const _PickerThumb(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HueBar extends StatelessWidget {
  const _HueBar({
    required this.hue,
    required this.semanticLabel,
    required this.onChanged,
  });

  final double hue;
  final String semanticLabel;
  final ValueChanged<double> onChanged;

  static const _spectrum = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  void _update(Offset local, Size size) {
    if (size.width <= 0) return;
    onChanged((local.dx / size.width).clamp(0.0, 1.0) * 359.9);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '${hue.round()}',
      slider: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) =>
                    _update(details.localPosition, constraints.biggest),
                onPanUpdate: (details) =>
                    _update(details.localPosition, constraints.biggest),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _spectrum),
                        ),
                        child: SizedBox.expand(),
                      ),
                      Align(
                        alignment: Alignment((hue / 359.9) * 2 - 1, 0),
                        child: const _PickerThumb(compact: true),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickerThumb extends StatelessWidget {
  const _PickerThumb({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 16.0 : 18.0;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
