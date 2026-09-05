import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/widgets/confirm.dart';
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
                  title: AppText.tr('option_recycle_bin'),
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pushNamed('/trash');
                  },
                ),
                SettingsTile(
                  title: 'Developer reset',
                  selected: false,
                  trailing: viewModel.isResetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : null,
                  onTap: viewModel.isResetting
                      ? () {}
                      : () async {
                          final confirm = await getConfirmation(
                            context: context,
                            actionTitle: 'Developer reset',
                            action: AppText.tr('reset'),
                          );
                          if (confirm == true) {
                            await viewModel.developerReset();
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home', (route) => false);
                            }
                          }
                        },
                ),
                SettingsTile(
                  title: AppText.tr('option_reset_data'),
                  selected: false,
                  textColor: const Color(0xFFFF8A80),
                  fontWeight: FontWeight.bold,
                  onTap: viewModel.isResetting
                      ? () {}
                      : () async {
                          final confirm = await getConfirmation(
                            context: context,
                            actionTitle: AppText.tr('option_reset_data'),
                            action: AppText.tr('delete'),
                          );
                          if (confirm == true) {
                            await viewModel.resetData();
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home', (route) => false);
                            }
                          }
                        },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.tr('desc_recycle_bin'),
                    style: TextStyle(fontSize: 12.0, color: mutedTextColor(context), height: 1.4),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    AppText.tr('desc_reset_data'),
                    style: TextStyle(fontSize: 12.0, color: mutedTextColor(context), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
