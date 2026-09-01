import 'package:flutter/material.dart';

import 'pro_badge.dart';

/// Visual lock used on Pro-only controls.
class ProLock extends StatelessWidget {
  const ProLock({
    super.key,
    required this.child,
    required this.locked,
    required this.onLockedTap,
  });

  final Widget child;
  final bool locked;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    if (!locked) {
      return child;
    }

    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(opacity: 0.58, child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onLockedTap,
              borderRadius: BorderRadius.circular(16),
              child: const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: ProBadge(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
