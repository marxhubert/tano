import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/services/premium_access.dart';

void main() {
  test('only the agreed features require Premium', () {
    for (final feature in [
      AppFeature.projects,
      AppFeature.sharing,
      AppFeature.collaboration,
    ]) {
      expect(
        () => PremiumAccess.free.require(feature),
        throwsA(isA<PremiumRequired>()),
      );
    }
    for (final feature in [
      AppFeature.notes,
      AppFeature.folders,
      AppFeature.tasks,
      AppFeature.exportImport,
    ]) {
      expect(PremiumAccess.free.allows(feature), isTrue);
    }
  });
  test('a premium entitlement permits all features', () {
    const access = PremiumAccess(tier: AccessTier.premium);
    expect(AppFeature.values.every(access.allows), isTrue);
  });
}
