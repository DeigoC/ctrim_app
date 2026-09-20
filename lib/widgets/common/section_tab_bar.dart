import 'package:flutter/material.dart';

/// Section TabBar for CTRIM and Cell Groups homes.
///
/// Uses a slim underline under the active label instead of filled pill chips.
class SectionTabBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<Widget> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: theme.textTheme.titleSmall,
      indicatorColor: colorScheme.primary,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
