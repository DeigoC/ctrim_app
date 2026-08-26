import 'package:flutter/material.dart';

class WelcomeHeroHeader extends StatelessWidget {
  const WelcomeHeroHeader({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    // Get text scale factor to adjust sizes for accessibility
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final isLargeText = textScaleFactor > 1.2;

    // Adjust sizes based on text scaling for better accessibility
    final logoSize = isLargeText ? 80.0 : 120.0;
    final logoPadding = isLargeText ? 16.0 : 32.0;
    final spacing = isLargeText ? 12.0 : 24.0;

    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Container(
              padding: EdgeInsets.all(logoPadding),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(isLargeText ? 24 : 32),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(isLargeText ? 24 : 32),
                      child: Image.asset(
                        'assets/images/ctrim_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.church_rounded,
                            size: logoSize * 0.5,
                            color: colorScheme.onPrimaryContainer,
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // Welcome Text
                  Text(
                    'Welcome to CTRIM',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: spacing / 3),

                  Text(
                    'Connect, grow, and thrive in faith',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Sticky Tab Bar Delegate for persistent header
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 72.0;

  @override
  double get maxExtent => 72.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
