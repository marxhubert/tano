import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'settings_widgets.dart';

class SortingSection extends StatefulWidget {
  const SortingSection({super.key, required this.viewModel});
  final SettingsViewModel viewModel;

  @override
  State<SortingSection> createState() => _SortingSectionState();
}

class _SortingSectionState extends State<SortingSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(title: AppText.tr('menu_sorting')),
        FutureBuilder<Map<String, dynamic>>(
          future: Future.wait([
            widget.viewModel.getSorting(),
            widget.viewModel.getSortAscending(),
          ]).then((res) => {'sortBy': res[0], 'ascending': res[1]}),
          builder: (context, snapshot) {
            final currentSort = snapshot.data?['sortBy'] ?? 'date';
            final currentAsc = snapshot.data?['ascending'] ?? true;

            return SettingsCard(
              children: [
                SettingsTile(
                  title: AppText.tr('menu_title'),
                  selected: currentSort == 'alpha',
                  onTap: () async {
                    await widget.viewModel.setSorting('alpha');
                    setState(() {});
                  },
                ),
                SettingsTile(
                  title: AppText.tr('menu_date'),
                  selected: currentSort == 'date',
                  onTap: () async {
                    await widget.viewModel.setSorting('date');
                    setState(() {});
                  },
                ),
                SettingsTile(
                  title: AppText.tr('menu_favorites'),
                  selected: currentSort == 'important',
                  onTap: () async {
                    await widget.viewModel.setSorting('important');
                    setState(() {});
                  },
                ),
                SettingsTile(
                  title: AppText.tr('menu_theme_sort'),
                  selected: currentSort == 'theme' || currentSort == 'category',
                  onTap: () async {
                    await widget.viewModel.setSorting('theme');
                    setState(() {});
                  },
                ),
                SettingsSwitchTile(
                  title: AppText.tr('menu_descending'),
                  value: !currentAsc,
                  onChanged: (val) async {
                    await widget.viewModel.setSortAscending(!val);
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
