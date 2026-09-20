/// Product boundaries; billing and store identity are deliberately separate.
enum AppFeature {
  notes,
  folders,
  tasks,
  exportImport,
  projects,
  sharing,
  collaboration,
}

enum AccessTier { free, premium }

/// Read-only entitlement snapshot. Production currently has no billing adapter
/// and therefore uses [free]. A future adapter must verify store evidence before
/// creating a premium snapshot; a persisted boolean is not proof of purchase.
class PremiumAccess {
  const PremiumAccess({this.tier = AccessTier.free});
  static const free = PremiumAccess();
  final AccessTier tier;

  static const premiumFeatures = {
    AppFeature.projects,
    AppFeature.sharing,
    AppFeature.collaboration,
  };

  bool allows(AppFeature feature) =>
      tier == AccessTier.premium || !premiumFeatures.contains(feature);

  void require(AppFeature feature) {
    if (!allows(feature)) throw PremiumRequired(feature);
  }
}

class PremiumRequired implements Exception {
  const PremiumRequired(this.feature);
  final AppFeature feature;
}
