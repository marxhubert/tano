import 'package:flutter/material.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/features/settings/widgets/settings_widgets.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/page_layout.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24.0),
                  // --- SECTION 1: DATA ---
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        title: AppText.tr('option_delete_data'),
                        value: _deleteData,
                        onChanged: (val) => setState(() => _deleteData = val),
                      ),
                    ],
                  ),
                  SettingsFooter(
                    children: [
                      SettingsFooterText(text: AppText.tr('desc_delete_data')),
                    ],
                  ),

                  const SizedBox(height: 12.0),

                  // --- SECTION 2: PREFERENCES ---
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        title: AppText.tr('option_delete_prefs'),
                        value: _deletePrefs,
                        onChanged: (val) => setState(() => _deletePrefs = val),
                      ),
                    ],
                  ),
                  SettingsFooter(
                    children: [
                      SettingsFooterText(text: AppText.tr('desc_delete_prefs')),
                    ],
                  ),

                  const SizedBox(height: 12.0),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54.0,
                      child: ElevatedButton(
                        onPressed: (_deleteData || _deletePrefs) && !_viewModel.isResetting
                            ? _handleReset
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(55.0),
                          ),
                          elevation: 0,
                        ),
                        child: _viewModel.isResetting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppText.tr('reset').toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
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
        // Redirect to home and clear navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }
}
