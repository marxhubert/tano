import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/card_typography.dart';
import 'package:tano/shared/widgets/theme.dart';

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
  test('small metadata retains contrast on every paper tint', () {
    for (final category in TanoPastels.all) {
      for (final background in [category.light, category.dark]) {
        final foreground = Color.alphaBlend(
          cardMutedColor(getTextColor(background)),
          background,
        );
        final backgroundLuminance = background.computeLuminance();
        final foregroundLuminance = foreground.computeLuminance();
        final ratio = foregroundLuminance > backgroundLuminance
            ? (foregroundLuminance + 0.05) / (backgroundLuminance + 0.05)
            : (backgroundLuminance + 0.05) / (foregroundLuminance + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: category.name);
      }
    }
  });

  test('the three allowed card heights are fixed', () {
    expect(EntityCardHeight.compact.value, 100.0);
    expect(EntityCardHeight.normal.value, 112.0);
    expect(EntityCardHeight.square.value, 176.0);
  });

  test('the inner radius follows outer minus margin', () {
    expect(EntityCard.contentInset, 6.0);
    expect(EntityCard.outerRadius, 8.0);
    expect(EntityCard.innerRadius, 2.0);
    expect(
      EntityCard.innerRadius,
      EntityCard.outerRadius - EntityCard.contentInset,
    );
  });

  testWidgets('the paper rule is a fine border in both themes', (tester) async {
    Future<double> borderWidth(Brightness brightness) async {
      await tester.pumpWidget(_host(_card(), brightness: brightness));
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

    expect(await borderWidth(Brightness.light), 1.0);
    expect(await borderWidth(Brightness.dark), 1.0);
  });

  testWidgets('a locked card draws the dashed outline and the lock', (
    tester,
  ) async {
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
          subtitleIcon: Symbols.description,
          isLocked: true,
          builder: (BuildContext context, Color textColor, bool hasCover) =>
              const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.description), findsOneWidget);
    expect(find.text('x3'), findsOneWidget);
  });


  testWidgets('the paper card has a subtle shadow and rounded border', (
    tester,
  ) async {
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

    expect(decoration.boxShadow, hasLength(1));
    expect(decoration.boxShadow!.single.spreadRadius, lessThan(0));
    expect(decoration.borderRadius, BorderRadius.circular(8.0));

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

  testWidgets('a locked card fits the real grid cell without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_card(locked: true), width: 160.0, height: 176.0),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
