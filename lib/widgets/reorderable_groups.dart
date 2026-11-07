import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/motion.dart';

Widget groupDragProxy(Widget child, int index, Animation<double> animation) {
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
  bool expanded = true,
  bool canCollapse = false,
}) {
  if (canCollapse) {
    return [
      SliverToBoxAdapter(
        child: Column(
          children: [
            header,
            _CollapsingGroupList(
              expanded: expanded,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
              onReorder: onReorder,
              empty: empty,
            ),
          ],
        ),
      ),
    ];
  }

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

class _CollapsingGroupList extends StatelessWidget {
  const _CollapsingGroupList({
    required this.expanded,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    required this.empty,
  });

  final bool expanded;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        key: const Key('group-list'),
        alignment: Alignment.topCenter,
        heightFactor: expanded ? 1 : 0,
        duration: Motion.short,
        curve: Motion.ease,
        child: _items(context),
      ),
    );
  }

  Widget _items(BuildContext context) {
    if (itemCount == 0) {
      return empty ?? const SizedBox(width: double.infinity);
    }
    // The page around this list scrolls. This list does not, so a drag on a
    // group is not swallowed here.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(dragDevices: const <PointerDeviceKind>{}),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        padding: EdgeInsets.zero,
        proxyDecorator: groupDragProxy,
        itemCount: itemCount,
        onReorderItem: onReorder,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
