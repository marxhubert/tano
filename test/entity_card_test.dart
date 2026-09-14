import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/widgets/entity_card.dart';

Widget _host(
  Widget card, {
  double width = 200.0,
  double height = 200.0,
  Brightness? brightness,
}) {
  return MaterialApp(
    theme: brightness == null
        ? null
        : ThemeData(brightness: brightness, useMaterial3: true),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: card),
      ),
    ),
  );
}

EntityCard _card({bool locked = false}) {
  return EntityCard(
    kind: EntityKind.note,
    category: 'menthe',
    title: 'Titre',
    subtitle: '1 Jan 2026',
    isLocked: locked,
    builder: (BuildContext context, Color textColor, bool hasCover) =>
        const SizedBox.expand(),
  );
}

void main() {
  test('the three allowed card heights are fixed', () {
    expect(EntityCardHeight.compact.value, 80.0);
    expect(EntityCardHeight.normal.value, 92.0);
    expect(EntityCardHeight.square.value, 128.0);
  });

  test('the inner radius follows outer minus margin', () {
    expect(EntityCard.contentInset, 6.0);
    expect(EntityCard.outerRadius, 12.0);
    expect(EntityCard.innerRadius, 6.0);
    expect(
      EntityCard.innerRadius,
      EntityCard.outerRadius - EntityCard.contentInset,
    );
  });

  testWidgets('the border is thicker in the dark theme', (tester) async {
    Future<double> borderWidth(Brightness brightness) async {
      await tester.pumpWidget(
        _host(_card(), brightness: brightness),
      );
      await tester.pumpAndSettle();
      final BoxDecoration decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(EntityCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((DecoratedBox box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((BoxDecoration d) => d.border != null);
      return (decoration.border! as Border).top.width;
    }

    expect(await borderWidth(Brightness.light), 0.5);
    expect(await borderWidth(Brightness.dark), 1.0);
  });

  testWidgets('a locked card draws the dashed outline and the lock',
      (tester) async {
    await tester.pumpWidget(_host(_card(locked: true)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('entity-card-outline')),
      findsOneWidget,
    );
    expect(find.byIcon(Symbols.lock), findsOneWidget);
  });

  testWidgets('an unlocked card has neither dashes nor lock', (tester) async {
    await tester.pumpWidget(_host(_card()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('entity-card-outline')),
      findsNothing,
    );
    expect(find.byIcon(Symbols.lock), findsNothing);
  });

  testWidgets('a locked card shows the subtitle icon and text', (tester) async {
    await tester.pumpWidget(
      _host(
        EntityCard(
          kind: EntityKind.folder,
          category: 'azur',
          title: 'Dossier',
          subtitle: 'x3',
          subtitleIcon: Icons.description_outlined,
          isLocked: true,
          builder: (BuildContext context, Color textColor, bool hasCover) =>
              const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.text('x3'), findsOneWidget);
  });

  testWidgets('only an unlocked folder card shows the watermark',
      (tester) async {
    Future<void> pump(EntityKind kind, {bool locked = false}) async {
      await tester.pumpWidget(
        _host(
          EntityCard(
            kind: kind,
            category: 'azur',
            title: 'Titre',
            isLocked: locked,
            builder: (BuildContext context, Color textColor, bool hasCover) =>
                const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(EntityKind.folder);
    expect(
      find.byKey(const ValueKey<String>('entity-card-watermark')),
      findsOneWidget,
    );

    await pump(EntityKind.note);
    expect(
      find.byKey(const ValueKey<String>('entity-card-watermark')),
      findsNothing,
    );

    await pump(EntityKind.folder, locked: true);
    expect(
      find.byKey(const ValueKey<String>('entity-card-watermark')),
      findsNothing,
    );
  });

  testWidgets('the card is flat (no shadow) and bordered', (tester) async {
    await tester.pumpWidget(_host(_card()));
    await tester.pumpAndSettle();

    final Container container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(EntityCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final BoxDecoration decoration = container.decoration! as BoxDecoration;

    expect(decoration.boxShadow, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(12.0));

    // The border is painted above the content, on its own DecoratedBox.
    final bool hasBorder = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(EntityCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .any((DecoratedBox box) {
      final Decoration d = box.decoration;
      return d is BoxDecoration && d.border != null;
    });
    expect(hasBorder, isTrue);
  });

  testWidgets('a locked card fits the real grid cell without overflowing',
      (tester) async {
    await tester.pumpWidget(
      _host(_card(locked: true), width: 112.67, height: 125.0),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
