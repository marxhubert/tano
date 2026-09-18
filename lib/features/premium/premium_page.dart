import 'package:flutter/material.dart';
import 'package:tano/core/services/premium_access.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Product information until billing and the corresponding features ship.
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Premium',
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(appPaddingLarge),
        sliver: SliverList.list(
          children: [
            Text(AppText.tr('premium_intro')),
            const SizedBox(height: appPaddingLarge),
            for (final feature in PremiumAccess.premiumFeatures)
              ListTile(
                title: Text(AppText.tr('premium_${feature.name}')),
                leading: const Icon(Icons.star_outline),
              ),
            const SizedBox(height: appPaddingLarge),
            Text(AppText.tr('premium_unavailable')),
          ],
        ),
      ),
    ],
  );
}
