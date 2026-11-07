import 'package:flutter/animation.dart';

/// Shared timing so taps, swipes, and section changes feel like one motion.
abstract final class Motion {
  static const Duration short = Duration(milliseconds: 220);
  static const Curve ease = Curves.easeOutCubic;
}
