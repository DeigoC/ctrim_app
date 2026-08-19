import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Overlapping avatars for a list of [users], mixing profile photos and
/// initials the same way as [MyUserAvatar].
///
/// Uses [WidgetStack] from `avatar_stack` so each slot can be any widget,
/// not only [ImageProvider]s.
class MyAvatarStack extends StatelessWidget {
  const MyAvatarStack({
    super.key,
    required this.users,
    this.appDir,
    this.height = kToolbarHeight,
    this.width,
    this.settings,
    this.borderWidth = 2.0,
    this.borderColor,
  });

  final List<User> users;

  /// Kept for call-site compatibility; [MyUserAvatar] resolves cache paths
  /// via [AppContext].
  final String? appDir;

  final double? height;
  final double? width;
  final Positions? settings;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final border = BorderSide(
      color: borderColor ?? theme.colorScheme.onPrimary,
      width: borderWidth,
    );
    final positions =
        settings ?? RestrictedPositions(maxCoverage: 0.3, minCoverage: 0.1);

    Widget infoWidget(int surplus, BuildContext _) => BorderedCircleAvatar(
          border: border,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '+$surplus',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        );

    return SizedBox(
      height: height,
      width: width ?? (kIsWeb ? null : 90),
      child: WidgetStack(
        positions: positions,
        buildInfoWidget: infoWidget,
        stackedWidgets: [
          for (final user in users)
            _StackedUserAvatar(user: user, border: border),
        ],
      ),
    );
  }
}

class _StackedUserAvatar extends StatelessWidget {
  const _StackedUserAvatar({required this.user, required this.border});

  final User user;
  final BorderSide border;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final avatarRadius =
            (size / 2 - border.width).clamp(1.0, double.infinity);
        return BorderedCircleAvatar(
          border: border,
          child: MyUserAvatar(user, radius: avatarRadius),
        );
      },
    );
  }
}
