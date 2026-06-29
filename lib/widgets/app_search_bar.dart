import 'package:flutter/material.dart';

/// Theme-aware search field for app bars, page bodies, and dialogs.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hintText = 'Search...',
    this.inAppBar = false,
    this.autofocus = false,
    this.margin,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String hintText;
  final bool inAppBar;
  final bool autofocus;
  final EdgeInsetsGeometry? margin;

  /// Shared [InputDecoration] for search [TextField]s in dialogs and forms.
  static InputDecoration inputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);
    final outlineColor = colorScheme.outline.withValues(alpha: 0.3);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  /// Text style that stays readable regardless of [AppBar] ancestor styling.
  static TextStyle textStyle(BuildContext context) {
    return TextStyle(color: Theme.of(context).colorScheme.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(inAppBar ? 20 : 12);

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: textStyle(context),
      cursorColor: colorScheme.primary,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: inAppBar,
        contentPadding: inAppBar
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: inAppBar ? 1 : 2),
        ),
      ),
    );

    Widget child = field;
    if (inAppBar) {
      child = DefaultTextStyle(
        style: textStyle(context),
        child: IconTheme(
          data: IconThemeData(color: colorScheme.onSurfaceVariant, size: 20),
          child: field,
        ),
      );
    }

    if (inAppBar) {
      return Container(
        height: 40,
        margin: margin ?? const EdgeInsets.only(right: 8),
        child: child,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: child,
    );
  }
}
