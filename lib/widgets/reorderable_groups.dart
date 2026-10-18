import 'package:flutter/material.dart';

Widget groupDragProxy(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, proxyChild) {
      final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
      return Material(
        elevation: elevation,
        color: Colors.transparent,
        shadowColor: Theme.of(context).colorScheme.shadow,
        borderRadius: BorderRadius.circular(16),
        child: proxyChild,
      );
    },
    child: child,
  );
}

List<Widget> reorderableGroupSlivers({
  required Widget header,
  required int itemCount,
  required IndexedWidgetBuilder itemBuilder,
  required ReorderCallback onReorder,
  Widget? empty,
}) {
  return [
    SliverToBoxAdapter(child: header),
    if (itemCount == 0)
      SliverToBoxAdapter(child: empty ?? const SizedBox.shrink())
    else
      SliverReorderableList(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        onReorderItem: onReorder,
        proxyDecorator: groupDragProxy,
      ),
  ];
}
