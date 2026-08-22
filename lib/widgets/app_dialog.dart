import 'package:flutter/material.dart';

import '../utility/responsive_layout.dart';

/// Shared Material 3 dialog chrome: capped width, 28px corners, icon + title + actions.
///
/// Use this (or [DialogManager] helpers built on it) instead of a raw [Dialog]
/// or [AlertDialog] so desktop widths stay consistent.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.messageAlign,
    this.banner,
    this.child,
    this.actions,
    this.maxWidth = ResponsiveLayout.dialogMaxWidth,
    this.isError = false,
    this.scrollable = true,
  });

  final IconData? icon;
  final String? title;
  final String? message;
  final TextAlign? messageAlign;
  final Widget? banner;
  final Widget? child;
  final Widget? actions;
  final double maxWidth;
  final bool isError;
  final bool scrollable;

  static const double cornerRadius = 28;
  static const EdgeInsets insetPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 24);

  static ShapeBorder get shape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      );

  static BoxConstraints boxConstraints(
    BuildContext context, {
    double maxWidth = ResponsiveLayout.dialogMaxWidth,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    );
  }

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      alignLabelWithHint: maxLines != null && maxLines > 1,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final align = messageAlign ??
        (child == null && banner == null ? TextAlign.center : TextAlign.start);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isError
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isError
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (title != null)
          Text(
            title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isError ? colorScheme.error : null,
            ),
            textAlign: TextAlign.center,
          ),
        if (message != null) ...[
          SizedBox(height: title != null || icon != null ? 12 : 0),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: align,
          ),
        ],
        if (banner != null) ...[
          const SizedBox(height: 16),
          banner!,
        ],
        if (child != null) ...[
          if (icon != null ||
              title != null ||
              message != null ||
              banner != null)
            const SizedBox(height: 20),
          child!,
        ],
        if (actions != null) ...[
          const SizedBox(height: 20),
          actions!,
        ],
      ],
    );

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: insetPadding,
      shape: shape,
      child: ConstrainedBox(
        constraints: boxConstraints(context, maxWidth: maxWidth),
        child: scrollable
            ? SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(24, 24, 24, 16 + viewInsets.bottom),
                child: body,
              )
            : Padding(
                padding:
                    EdgeInsets.fromLTRB(24, 24, 24, 16 + viewInsets.bottom),
                child: body,
              ),
      ),
    );
  }
}

/// Info callout used inside [AppDialog] (bookmark notify, tips, etc.).
class AppDialogBanner extends StatelessWidget {
  const AppDialogBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard Cancel / Confirm row for [AppDialog].
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.confirmLabel = 'OK',
    this.confirmIcon,
    this.confirmEnabled = true,
    this.isDestructive = false,
  });

  final VoidCallback? onCancel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final String confirmLabel;
  final IconData? confirmIcon;
  final bool confirmEnabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canConfirm = confirmEnabled && onConfirm != null;

    Widget confirmButton() {
      final child = Text(confirmLabel);
      final style = isDestructive
          ? FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            )
          : null;
      if (confirmIcon != null) {
        return FilledButton.icon(
          onPressed: canConfirm ? onConfirm : null,
          style: style,
          icon: Icon(confirmIcon, size: 18),
          label: child,
        );
      }
      return FilledButton(
        onPressed: canConfirm ? onConfirm : null,
        style: style,
        child: child,
      );
    }

    if (onCancel == null) {
      return SizedBox(width: double.infinity, child: confirmButton());
    }

    if (onConfirm == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: confirmButton()),
      ],
    );
  }
}
