import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/manageable_cover.dart';

Widget _host(Future<void> Function() onRemove) {
  return MaterialApp(
    home: Scaffold(
      body: ManageableCover(
        name: 'missing.png',
        height: 160.0,
        onRemove: onRemove,
      ),
    ),
  );
}

void main() {
  setUp(() {
    if (!getIt.isRegistered<AttachmentsStore>()) {
      getIt.registerLazySingleton<AttachmentsStore>(() => AttachmentsStore());
    }
  });

  testWidgets('long press reveals the remove button, confirming removes',
      (tester) async {
    bool removed = false;
    await tester.pumpWidget(_host(() async => removed = true));
    await tester.pumpAndSettle();

    // Hidden until the user long-presses the cover.
    expect(find.byIcon(Symbols.cancel), findsNothing);

    await tester.longPress(find.byType(CoverImage));
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.cancel), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(removed, isFalse);

    await tester.tap(find.text(AppText.tr('delete').toUpperCase()));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });

  testWidgets('an inset cover clips its corners to the given radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManageableCover(
            name: 'missing.png',
            height: 160.0,
            borderRadius: BorderRadius.circular(12.0),
            onRemove: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ClipRRect clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(ManageableCover),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, BorderRadius.circular(12.0));
  });
}
