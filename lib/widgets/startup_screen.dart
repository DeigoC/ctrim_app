import 'package:flutter/material.dart';

import '../utility/startup_load.dart';
import 'common/load_progress_body.dart';

/// Covers the shell until [loadStartup] finishes, then reveals [child].
///
/// The child stays mounted so the router keeps the incoming URL. Pointers and
/// semantics are blocked until the bar completes.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.title,
    required this.messageFor,
    required this.loadStartup,
    required this.child,
  });

  final String title;
  final String Function(StartupLoadStep step) messageFor;
  final Future<void> Function(StartupProgressReporter onProgress) loadStartup;
  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _ready = false;
  bool _started = false;
  StartupLoadStep _step = StartupLoadStep.opening;
  int _completed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      await widget.loadStartup(({
        required int completed,
        required int total,
        required StartupLoadStep step,
      }) {
        if (!mounted || _ready) return;
        setState(() {
          _completed = completed;
          _total = total;
          _step = step;
        });
      });
    } catch (e) {
      debugPrint('Startup load failed: $e');
    } finally {
      if (mounted) {
        setState(() => _ready = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !_ready,
          child: ExcludeSemantics(
            excluding: !_ready,
            child: widget.child,
          ),
        ),
        if (!_ready)
          Positioned.fill(
            child: StartupScreen(
              title: widget.title,
              message: widget.messageFor(_step),
              completedSteps: _completed,
              totalSteps: _total,
            ),
          ),
      ],
    );
  }
}

/// Logo, title, and determinate bar shown while the app opens.
class StartupScreen extends StatelessWidget {
  const StartupScreen({
    super.key,
    required this.title,
    required this.message,
    required this.completedSteps,
    required this.totalSteps,
  });

  final String title;
  final String message;
  final int completedSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.secondary.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StartupLogo(colorScheme: colorScheme),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                LoadProgressBody(
                  message: message,
                  completedSteps: completedSteps,
                  totalSteps: totalSteps,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupLogo extends StatelessWidget {
  const _StartupLogo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/ctrim_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.church_rounded,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            );
          },
        ),
      ),
    );
  }
}
