import 'package:flutter/material.dart';

/// Status + determinate progress used while loading posts / templates / setup.
class LoadProgressBody extends StatelessWidget {
  const LoadProgressBody({
    super.key,
    required this.message,
    required this.completedSteps,
    required this.totalSteps,
    this.error,
    this.onRetry,
    this.errorTitle = 'Something went wrong',
    this.padding = const EdgeInsets.all(24),
  });

  final String message;
  final int completedSteps;
  final int totalSteps;
  final Object? error;
  final VoidCallback? onRetry;
  final String errorTitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: padding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  errorTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final double? progress =
        totalSteps > 0 ? (completedSteps / totalSteps).clamp(0.0, 1.0) : null;

    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (totalSteps > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '$completedSteps of $totalSteps',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
