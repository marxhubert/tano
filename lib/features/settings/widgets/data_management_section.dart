import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/features/settings/data_transfer_page.dart';
import 'package:tano/features/settings/reset_page.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'settings_widgets.dart';

class DataManagementSection extends StatelessWidget {
  const DataManagementSection({super.key, required this.viewModel});
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),
            SettingsCard(
              children: [
                SettingsTile(
                  title: AppText.tr('data_transfer_title'),
                  selected: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataTransferPage(),
                    ),
                  ),
                ),
                SettingsTile(
                  title: AppText.tr('option_recycle_bin'),
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pushNamed('/trash');
                  },
                ),
                SettingsTile(
                  title: AppText.tr('option_reset_data'),
                  selected: false,
                  textColor: const Color(0xFFFF8A80),
                  fontWeight: FontWeight.bold,
                  onTap: viewModel.isResetting
                      ? () {}
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPage(),
                            ),
                          );
                        },
                ),
              ],
            ),
            SettingsFooter(
              children: [
                SettingsFooterText(text: AppText.tr('desc_recycle_bin')),
                SettingsFooterText(text: AppText.tr('desc_reset_data')),
              ],
            ),
          ],
        );
      },
    );
  }
}
