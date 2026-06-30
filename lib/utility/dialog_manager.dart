import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';

/// Modern dialog manager with Material 3 design patterns
/// Used to show consistent dialogs throughout the app
class DialogManager {
  /// Shows a modern user profile dialog with Material 3 design
  static void showUserProfile({
    required User selectedUser,
    required BuildContext context,
    bool currentUserAdmin = false,
  }) {
    Widget buildVerticalUserViewer(User selectedUser) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // Hero animation for avatar
            Hero(
              tag: 'user_avatar_${selectedUser.id}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MyUserAvatar(
                  selectedUser,
                  radius: MediaQuery.of(context).size.width * 0.18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // User name with better typography
            Text(
              currentUserAdmin ? '${selectedUser.fullname} (${selectedUser.id})' : selectedUser.fullname,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Location with admin badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  selectedUser.location,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (selectedUser.isAreaAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Admin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    Widget buildHorizontalUserViewer(User selectedUser) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 24),
            // Avatar with hero animation
            Hero(
              tag: 'user_avatar_${selectedUser.id}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MyUserAvatar(
                  selectedUser,
                  radius: MediaQuery.of(context).size.height * 0.15,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // User info column
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUserAdmin ? '${selectedUser.fullname} (${selectedUser.id})' : selectedUser.fullname,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedUser.location,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (selectedUser.isAreaAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => OrientationBuilder(
        builder: (context, orientation) {
          return Dialog(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: orientation == Orientation.portrait
                  ? buildVerticalUserViewer(selectedUser)
                  : buildHorizontalUserViewer(selectedUser),
            ),
          );
        },
      ),
    );
  }

  /// Shows a modern confirmation dialog for discarding changes
  static Future<bool> discardChanges({required BuildContext context}) async {
    HapticFeedback.lightImpact(); // Haptic feedback for better UX

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog.adaptive(
          icon: Icon(
            Icons.warning_rounded,
            color: colorScheme.error,
            size: 32,
          ),
          title: Text(
            'Discard Changes?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'All unsaved changes will be lost. This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Editing',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Shows a modern confirmation dialog with customizable content and actions
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool barrierDismissible = true,
    IconData? icon,
    bool isDestructive = false,
  }) async {
    HapticFeedback.lightImpact();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog.adaptive(
          icon: icon != null
              ? Icon(
                  icon,
                  color: isDestructive ? colorScheme.error : colorScheme.primary,
                  size: 32,
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            isDestructive
                ? FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    child: Text(confirmText),
                  )
                : FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmText),
                  ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Shows a modern alert dialog with better typography and styling
  static Future<void> showAlertDialog({
    required BuildContext context,
    required String title,
    required String content,
    String closeText = 'Got it',
    bool barrierDismissible = true,
    IconData? icon,
    bool isError = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog.adaptive(
          icon: icon != null
              ? Icon(
                  icon,
                  color: isError ? colorScheme.error : colorScheme.primary,
                  size: 32,
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isError ? colorScheme.error : null,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(closeText),
            ),
          ],
        );
      },
    );
  }

  /// Shows a modern progress dialog with Material 3 design
  static void showProgressDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a modern snackbar with better styling (bonus utility)
  static void showSnackBar({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? colorScheme.onError : colorScheme.onInverseSurface,
          ),
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: isError ? colorScheme.onError : colorScheme.inversePrimary,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}
