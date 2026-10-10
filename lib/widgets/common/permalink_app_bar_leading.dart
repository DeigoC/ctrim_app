import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/app_links.dart';

/// Home (or up) control for a permalink that has nothing underneath it.
///
/// In-app opens can pop, so [homeOrNull] returns null and the app bar keeps
/// its normal back button. A shared link, bookmark, or refresh is the first
/// page: Home opens the section that owns the record.
class PermalinkAppBarLeading extends StatelessWidget {
  const PermalinkAppBarLeading({super.key, this.onLeave});

  /// Return false to stay on this page (for example after declining to
  /// discard edits).
  final Future<bool> Function()? onLeave;

  /// True when this route is the first page, so there is no back stack.
  static bool isRootPermalink(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return router != null && !router.canPop();
  }

  /// The home control, or null when the app bar should show Back.
  static Widget? homeOrNull(
    BuildContext context, {
    Future<bool> Function()? onLeave,
  }) {
    if (!isRootPermalink(context)) return null;
    return PermalinkAppBarLeading(onLeave: onLeave);
  }

  /// Pops when a previous page exists. Otherwise opens [AppLinks.upPath].
  static void leave(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    context.go(AppLinks.upPath(path));
  }

  @override
  Widget build(BuildContext context) {
    final destination = AppLinks.upPath(GoRouterState.of(context).uri.path);
    final opensShell = AppLinks.homeTabIndexForPath(destination) != null;
    final tooltip = opensShell
        ? AppLocalizations.of(context)!.permalinkGoHome
        : MaterialLocalizations.of(context).backButtonTooltip;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(opensShell ? Icons.home_outlined : Icons.arrow_back),
      onPressed: () async {
        if (onLeave != null) {
          final ok = await onLeave!();
          if (!ok || !context.mounted) return;
        }
        if (!context.mounted) return;
        context.go(destination);
      },
    );
  }
}
