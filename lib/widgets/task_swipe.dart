import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';

/// Short horizontal swipe that springs back.
///
/// Completing a task keeps it on screen, so a full dismiss would stick until
/// the save finished and then snap the whole width back.
class TaskSwipe extends StatefulWidget {
  const TaskSwipe({
    super.key,
    required this.allowTomorrow,
    required this.markingDone,
    required this.onTomorrow,
    required this.onDone,
    required this.child,
  });

  final bool allowTomorrow;
  final bool markingDone;
  final VoidCallback onTomorrow;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<TaskSwipe> createState() => _TaskSwipeState();
}

class _TaskSwipeState extends State<TaskSwipe>
    with SingleTickerProviderStateMixin {
  static const double _trigger = 64;
  static const double _maxDrag = 96;

  late final AnimationController _controller;
  Animation<double>? _spring;
  double _drag = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.short)
      ..addListener(_onSpringTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  double _towardEnd(double dx) => _isRtl ? -dx : dx;

  void _onDragStart(DragStartDetails details) {
    _spring = null;
    _fired = false;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _drag = _limited(_drag + _towardEnd(details.delta.dx)));
    _fireIfPastTrigger();
  }

  void _onDragEnd(DragEndDetails details) {
    _fireFling(_towardEnd(details.primaryVelocity ?? 0));
    _springBack();
  }

  double _limited(double next) {
    if (!widget.allowTomorrow && next > 0) {
      return 0;
    }
    final distance = next.abs();
    if (distance <= _maxDrag) {
      return next;
    }
    return next.sign * (_maxDrag + (distance - _maxDrag) * 0.18);
  }

  void _fireIfPastTrigger() {
    if (_fired || _drag.abs() < _trigger) {
      return;
    }
    _fire(tomorrow: _drag > 0);
  }

  void _fireFling(double towardEndVelocity) {
    // A zero velocity means the gesture was a drag, not a flick.
    if (_fired || towardEndVelocity == 0) {
      return;
    }
    if (towardEndVelocity > 0 && !widget.allowTomorrow) {
      return;
    }
    _fire(tomorrow: towardEndVelocity > 0);
  }

  void _fire({required bool tomorrow}) {
    _fired = true;
    HapticFeedback.lightImpact();
    if (tomorrow) {
      widget.onTomorrow();
      return;
    }
    widget.onDone();
  }

  void _springBack() {
    _spring = Tween<double>(
      begin: _drag,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.ease));
    _controller.forward(from: 0);
  }

  void _onSpringTick() {
    final spring = _spring;
    if (!mounted || spring == null) {
      return;
    }
    setState(() => _drag = spring.value);
  }

  @override
  Widget build(BuildContext context) {
    final visual = _isRtl ? -_drag : _drag;
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _springBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: _background()),
            RepaintBoundary(
              child: Transform.translate(
                offset: Offset(visual, 0),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    final tomorrow = _drag > 0;
    final progress = (_drag.abs() / _trigger).clamp(0.0, 1.0);
    final colors = _SwipeColors.resolve(
      Theme.of(context).colorScheme,
      tomorrow: tomorrow,
      markingDone: widget.markingDone,
    );
    return ColoredBox(
      color: colors.background,
      child: Align(
        alignment: tomorrow
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Opacity(
            opacity: progress,
            child: Icon(colors.icon, color: colors.foreground),
          ),
        ),
      ),
    );
  }
}

class _SwipeColors {
  const _SwipeColors(this.background, this.foreground, this.icon);

  final Color background;
  final Color foreground;
  final IconData icon;

  factory _SwipeColors.resolve(
    ColorScheme scheme, {
    required bool tomorrow,
    required bool markingDone,
  }) {
    if (tomorrow) {
      return _SwipeColors(
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.event_rounded,
      );
    }
    if (markingDone) {
      return _SwipeColors(
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_rounded,
      );
    }
    return _SwipeColors(
      scheme.surfaceContainerHighest,
      scheme.onSurface,
      Icons.undo_rounded,
    );
  }
}
