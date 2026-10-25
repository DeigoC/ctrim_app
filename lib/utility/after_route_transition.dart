import 'package:flutter/widgets.dart';

/// Runs work after the current route's entrance animation finishes.
///
/// Opening a heavy page during the slide-in spends the animation's frames on
/// that work. Call [schedule] from a post-frame callback and [dispose] with
/// the [State].
class AfterRouteTransition {
  Animation<double>? _animation;
  AnimationStatusListener? _listener;

  void schedule(State<dynamic> state, VoidCallback action) {
    final animation = ModalRoute.of(state.context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      action();
      return;
    }
    if (animation.status == AnimationStatus.dismissed) return;

    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (identical(_listener, listener)) {
        _listener = null;
        _animation = null;
      }
      if (state.mounted) action();
    }

    _animation = animation;
    _listener = listener;
    animation.addStatusListener(listener);
  }

  void dispose() {
    final listener = _listener;
    if (listener != null) {
      _animation?.removeStatusListener(listener);
    }
    _listener = null;
    _animation = null;
  }
}
