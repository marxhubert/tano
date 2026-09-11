import 'package:flutter/material.dart';
import 'package:tano/features/settings/data_transfer.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'widgets/settings_widgets.dart';

/// Backup page: export the data to a `.tano` file or import one.
class DataTransferPage extends StatelessWidget {
  const DataTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.tr('data_transfer_title'),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const SizedBox(height: 24.0),
              // --- SECTION 1: EXPORT ---
              SettingsCard(
                children: <Widget>[
                  SettingsTile(
                    title: AppText.tr('export_data'),
                    selected: false,
                    onTap: () => exportData(context),
                  ),
                ],
              ),
              SettingsFooter(
                children: <Widget>[
                  SettingsFooterText(text: AppText.tr('desc_export_data')),
                ],
              ),

              const SizedBox(height: 12.0),

              // --- SECTION 2: IMPORT ---
              SettingsCard(
                children: <Widget>[
                  SettingsTile(
                    title: AppText.tr('import_data'),
                    selected: false,
                    onTap: () => importData(context),
                  ),
                ],
              ),
              SettingsFooter(
                children: <Widget>[
                  SettingsFooterText(text: AppText.tr('desc_import_data')),
                ],
              ),

              const SizedBox(height: 12.0),
            ]),
          ),
        ),
      ],
    );
  }
}
