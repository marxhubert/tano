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
  String _sortBy = 'date';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String sortBy = await widget.viewModel.getSorting();
    final bool ascending = await widget.viewModel.getSortAscending();
    if (!mounted) return;
    setState(() {
      _sortBy = sortBy;
      _ascending = ascending;
    });
  }

  Future<void> _setSorting(String sortBy) async {
    await widget.viewModel.setSorting(sortBy);
    if (mounted) setState(() => _sortBy = sortBy);
  }

  Future<void> _setAscending(bool ascending) async {
    await widget.viewModel.setSortAscending(ascending);
    if (mounted) setState(() => _ascending = ascending);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: AppText.tr('menu_sorting'),
      tiles: <Widget>[
        SettingsTile(
          title: AppText.tr('menu_title'),
          selected: _sortBy == 'alpha',
          onTap: () => _setSorting('alpha'),
        ),
        SettingsTile(
          title: AppText.tr('menu_date'),
          selected: _sortBy == 'date',
          onTap: () => _setSorting('date'),
        ),
        SettingsTile(
          title: AppText.tr('menu_modified'),
          selected: _sortBy == 'updated',
          onTap: () => _setSorting('updated'),
        ),
        SettingsTile(
          title: AppText.tr('menu_favorites'),
          selected: _sortBy == 'important',
          onTap: () => _setSorting('important'),
        ),
        SettingsTile(
          title: AppText.tr('menu_theme_sort'),
          selected: _sortBy == 'theme' || _sortBy == 'category',
          onTap: () => _setSorting('theme'),
        ),
        SettingsSwitchTile(
          title: AppText.tr('menu_descending'),
          value: !_ascending,
          onChanged: (val) => _setAscending(!val),
        ),
      ],
    );
  }
}
