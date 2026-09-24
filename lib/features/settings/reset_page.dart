import 'package:flutter/material.dart';
import 'package:tano/features/settings/data_transfer.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/features/settings/widgets/settings_widgets.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final SettingsViewModel _viewModel = SettingsViewModel();
  bool _deleteData = false;
  bool _deletePrefs = false;

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PageScaffold(
          title: AppText.tr('option_reset_data'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: appPaddingMedium),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SettingsGroup(
                    tiles: [
                      SettingsSwitchTile(
                        title: AppText.tr('option_delete_data'),
                        value: _deleteData,
                        onChanged: (val) => setState(() => _deleteData = val),
                      ),
                    ],
                    footer: [
                      SettingsFooterText(text: AppText.tr('desc_delete_data')),
                    ],
                  ),

                  SettingsGroup(
                    tiles: [
                      SettingsSwitchTile(
                        title: AppText.tr('option_delete_prefs'),
                        value: _deletePrefs,
                        onChanged: (val) => setState(() => _deletePrefs = val),
                      ),
                    ],
                    footer: [
                      SettingsFooterText(text: AppText.tr('desc_delete_prefs')),
                    ],
                  ),

                  // --- SECTION 3: EXPORT (only when data will be deleted) ---
                  if (_deleteData) ...<Widget>[
                    SettingsGroup(
                      color: tanoAmber.withValues(alpha: 0.7),
                      tiles: [
                        SettingsTile(
                          title: AppText.tr('option_export_before_reset'),
                          selected: false,
                          // The label must stay readable on the solid amber.
                          textColor: Colors.black,
                          onTap: () => exportData(context),
                        ),
                      ],
                      footer: [
                        SettingsFooterText(
                          text: AppText.tr('desc_export_before_reset'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: SettingsGroup.defaultTopSpacing),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  sectionGap,
                  48.0,
                  sectionGap,
                  sectionGap,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54.0,
                      child: ElevatedButton(
                        onPressed:
                            (_deleteData || _deletePrefs) &&
                                !_viewModel.isResetting
                            ? _handleReset
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(pillRadius),
                          ),
                          elevation: 0,
                        ),
                        child: _viewModel.isResetting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                AppText.tr('reset').toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: TanoText.body,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleReset() async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('option_reset_data'),
      action: AppText.tr('reset'),
    );

    if (confirm == true) {
      await _viewModel.performHardReset(
        deleteData: _deleteData,
        deletePrefs: _deletePrefs,
      );
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }
}
