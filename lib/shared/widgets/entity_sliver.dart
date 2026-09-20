import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Grid or list of cards, shared by every card screen.
///
/// Both layouts adapt to the viewport with [entityColumnCount]. Grid cards
/// keep their 0.9 aspect ratio; list cards retain their natural row height.
/// It belongs in a [CustomScrollView]; callers add outer [SliverPadding].
class EntitySliver<T> extends StatelessWidget {
  const EntitySliver({
    super.key,
    required this.items,
    required this.isList,
    required this.cardBuilder,
  });

  final List<T> items;
  final bool isList;

  /// Builds the cards in the visible and cached rows, rather than the full list.
  final Widget Function(BuildContext context, T item) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final int columns = entityColumnCount(
      MediaQuery.sizeOf(context),
      isList: isList,
    );
    if (isList) {
      return SliverList.separated(
        itemCount: (items.length / columns).ceil(),
        itemBuilder: (BuildContext context, int row) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int column = 0; column < columns; column++) ...<Widget>[
              if (column > 0) const SizedBox(width: appPaddingTight),
              Expanded(
                child: row * columns + column < items.length
                    ? cardBuilder(context, items[row * columns + column])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: appPaddingTight),
      );
    }
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: appPaddingTight,
        mainAxisSpacing: appPaddingTight,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) =>
          cardBuilder(context, items[index]),
    );
  }
}
