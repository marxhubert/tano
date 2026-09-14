import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'widgets/appearance_section.dart';
import 'widgets/sorting_section.dart';
import 'widgets/language_section.dart';
import 'widgets/about_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/settings_widgets.dart';
import '../lab/card_lab_page.dart';

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
    _viewModel.init();
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
                SortingSection(viewModel: _viewModel),
                const LanguageSection(),
                AboutSection(viewModel: _viewModel),
                DataManagementSection(viewModel: _viewModel),
                // TEMPORARY: entry to the card lab, removed with the lab page.
                const _CardLabEntry(),
                const SizedBox(height: 40.0),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// TEMPORARY settings entry pointing at the card lab. Remove together with
/// [CardLabPage] once the card refactoring is validated.
class _CardLabEntry extends StatelessWidget {
  const _CardLabEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: SettingsCard(
        children: <Widget>[
          SettingsTile(
            title: 'Labo cartes',
            selected: false,
            trailing: Icon(Icons.chevron_right, color: mutedTextColor(context)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const CardLabPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
