import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'widgets/appearance_section.dart';
import 'widgets/feedback_section.dart';
import 'widgets/sorting_section.dart';
import 'widgets/language_section.dart';
import 'widgets/about_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/settings_widgets.dart';

import 'package:tano/shared/config/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsViewModel _viewModel = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    // The settings list reads badly in landscape: hold the screen portrait while
    // it is on screen, and hand the device back on the way out.
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _viewModel.init();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole page when the language changes. A pushed route does not
    // rebuild on its own, so without this the new strings would only appear
    // after navigating away and back.
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => PageScaffold(
        title: AppText.tr('settings'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: appPaddingMedium),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const AppearanceSection(),
                const FeedbackSection(),
                SortingSection(viewModel: _viewModel),
                const LanguageSection(),
                AboutSection(viewModel: _viewModel),
                DataManagementSection(viewModel: _viewModel),
                const SizedBox(height: SettingsGroup.defaultTopSpacing),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
