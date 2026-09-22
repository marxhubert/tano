import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

class PopupItem {
  final String title;
  final String value;
  final Icon? icon;

  /// When true, the icon (if any) is rendered at the end of the row,
  /// right-aligned (used for the "Display" group).
  final bool trailingIcon;

  /// When true the row carries a switch, not an icon: it is a setting.
  final bool toggle;

  PopupItem({
    required this.title,
    required this.value,
    this.icon,
    this.trailingIcon = false,
    this.toggle = false,
  });
}

/// Main menu items, resolved according to the current language.
Map<String, PopupItem> get menuItems {
  return <String, PopupItem>{
    'gridlist': PopupItem(
      title: AppText.tr('menu_grid'),
      icon: const Icon(Symbols.grid_view, size: 24.0),
      value: 'gridlist',
      trailingIcon: true,
    ),
    'list': PopupItem(
      title: AppText.tr('menu_list'),
      icon: const Icon(Symbols.view_agenda, size: 24.0),
      value: 'list',
      trailingIcon: true,
    ),
    'leftside': PopupItem(
      title: AppText.tr('menu_left_side'),
      value: 'leftside',
      toggle: true,
    ),
    'separator': PopupItem(title: '', value: 'separator', icon: null),
    'settings': PopupItem(
      title: AppText.tr('settings'),
      value: 'settings',
      icon: const Icon(Symbols.settings_applications, size: 24.0),
      trailingIcon: true,
    ),
  };
}

Widget popupButton({
  required BuildContext context,
  required PopupItem popupItem,
  String? layout,
  String? sort,
  String? lang,
  bool editMode = false,
  bool? selected,
  Widget? trailing,
}) {
  if ('separator' == popupItem.value) {
    return const SizedBox.shrink();
  }
  if ('header' == popupItem.value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        appPaddingWide,
        appPaddingWide,
        appPaddingWide,
        0.0,
      ),
      child: Text(
        popupItem.title,
        style: TextStyle(
          color: mutedTextColor(context),
          fontWeight: FontWeight.bold,
          fontSize: TanoText.listTitle,
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  final Icon? icon = popupItem.icon;
  final bool isSelected =
      selected ??
      (!editMode &&
          (popupItem.value == layout ||
              popupItem.value == sort ||
              popupItem.value == lang));

  // The accent, so the active item follows the theme in dark mode too.
  final Color activeColor = isSelected
      ? Theme.of(context).colorScheme.primary
      : primaryTextColor(context);

  final Widget label = Text(
    popupItem.title,
    style: TextStyle(
      color: activeColor,
      fontSize: TanoText.listTitle,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    ),
    overflow: TextOverflow.ellipsis,
  );

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: appPaddingWide),
    visualDensity: const VisualDensity(vertical: -2.0),
    dense: true,
    title: label,
    trailing:
        trailing ??
        (icon != null
            ? Icon(
                icon.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : mutedTextColor(context),
                size: 20.0,
                // The active item's glyph is solid, not outlined.
                fill: isSelected ? 1.0 : 0.0,
              )
            : null),
  );
}

/// The one app-bar menu, on every platform: a Material popup with the view
/// actions. iOS used to open a Cupertino action sheet instead; it no longer
/// does, so Home and a folder offer exactly the same menu.
class AppBarMenuButton extends StatelessWidget {
  const AppBarMenuButton({
    super.key,
    required this.layout,
    required this.onLayout,
    this.onSettings,
    this.onLeft = false,
    this.onLeftChanged,
  });

  /// The current layout, so the matching item reads as selected.
  final String layout;

  /// Called with 'list' or 'gridlist'.
  final ValueChanged<String> onLayout;

  /// Opens the settings screen and reloads afterwards.
  final Future<void> Function()? onSettings;

  /// Whether the FAB sits on the left, driving the switch row.
  final bool onLeft;
  final ValueChanged<bool>? onLeftChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PopupItem>(
      icon: const Icon(Symbols.pending),
      tooltip: AppText.tr('more'),
      offset: const Offset(0, 56),
      elevation: 4.0,
      // Tighter than the default 8: the menu hugs its rows.
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      // Wide enough for a label and its switch side by side.
      constraints: const BoxConstraints(minWidth: 220.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(appBorderRadius),
      ),
      onSelected: (PopupItem item) async {
        switch (item.value) {
          case 'list':
          case 'gridlist':
            onLayout(item.value);
            break;
          case 'leftside':
            onLeftChanged?.call(!onLeft);
            break;
          case 'settings':
            await onSettings?.call();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        // Held locally to the open menu: the route is not rebuilt by the page's
        // setState, so the switch would otherwise look stale until reopened.
        bool localLeft = onLeft;
        return <PopupMenuEntry<PopupItem>>[
          for (final PopupItem item in menuItems.values)
            if (item.value == 'separator')
              PopupMenuDivider(
                // The 1px line plus ~6 of air above and below it.
                height: 13.0,
                color: Theme.of(context).colorScheme.primary,
              )
            else
              PopupMenuItem<PopupItem>(
                value: item,
                height: item.value == 'header' ? 32.0 : 40.0,
                enabled: item.value != 'header',
                padding: EdgeInsets.zero,
                child: item.toggle
                    ? StatefulBuilder(
                        builder: (BuildContext context, StateSetter setLocal) =>
                            popupButton(
                              context: context,
                              popupItem: item,
                              layout: layout,
                              // Not `selected`: a switch does not make the
                              // label read as the active view.
                              trailing: Transform.translate(
                                offset: const Offset(2.0, 0.0),
                                child: Transform.scale(
                                  scale: 0.6,
                                  // Right-anchored, like the settings
                                  // switches.
                                  alignment: Alignment.centerRight,
                                  child: Switch.adaptive(
                                    value: localLeft,
                                    onChanged: (bool value) {
                                      setLocal(() => localLeft = value);
                                      onLeftChanged?.call(value);
                                      // Dismiss the menu: a covered page keeps
                                      // its animations muted, so the move would
                                      // only show once it is uncovered again.
                                      Navigator.of(context).pop();
                                    },
                                    activeThumbColor: accentColor(context),
                                  ),
                                ),
                              ),
                            ),
                      )
                    : popupButton(
                        context: context,
                        popupItem: item,
                        layout: layout,
                      ),
              ),
        ];
      },
    );
  }
}
