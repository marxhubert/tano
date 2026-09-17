import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Grid or list of cards, shared by every card screen.
///
/// The grid uses the standard card configuration (three columns, 8px gaps,
/// 0.9 ratio); the list stacks full-width rows separated by 8px. It is a
/// sliver, so it belongs in a [CustomScrollView]; callers add whatever
/// padding they need with a [SliverPadding].
class EntitySliver<T> extends StatelessWidget {
  const EntitySliver({
    super.key,
    required this.items,
    required this.isList,
    required this.cardBuilder,
  });

  final List<T> items;
  final bool isList;

  /// Builds the card for one item. It is called for the visible items only.
  final Widget Function(BuildContext context, T item) cardBuilder;

  @override
  Widget build(BuildContext context) {
    if (isList) {
      return SliverList.separated(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) =>
            cardBuilder(context, items[index]),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: appPaddingTight),
      );
    }
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount(context),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) =>
          cardBuilder(context, items[index]),
    );
  }
}
