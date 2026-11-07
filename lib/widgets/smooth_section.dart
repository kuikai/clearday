import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Eases the height of a block when its contents appear or leave.
class SmoothSection extends StatelessWidget {
  const SmoothSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Motion.short,
      curve: Motion.ease,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
