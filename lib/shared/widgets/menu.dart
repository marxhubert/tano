import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

class PopupItem {
  final String title;
  final String value;
  final Icon? icon;

  /// When true, the icon (if any) is rendered at the end of the row,
  /// right-aligned (used for the "Display" group).
  final bool trailingIcon;

  PopupItem({
    required this.title,
    required this.value,
    this.icon,
    this.trailingIcon = false,
  });
}

/// Main menu items, resolved according to the current language.
Map<String, PopupItem> get menuItems {
  return <String, PopupItem>{
    'layout_title': PopupItem(
      title: AppText.tr('menu_display'),
      value: 'header',
      icon: null,
    ),
    'list': PopupItem(
      title: AppText.tr('menu_list'),
      icon: Icon(Icons.view_stream),
      value: 'list',
      trailingIcon: true,
    ),
    'gridlist': PopupItem(
      title: AppText.tr('menu_grid'),
      icon: Icon(Icons.view_module),
      value: 'gridlist',
      trailingIcon: true,
    ),

    'settings_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'settings': PopupItem(
      title: AppText.tr('settings'),
      value: 'settings',
      icon: Icon(Icons.settings_outlined),
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
}) {
  if ('separator' == popupItem.value) {
    return Container(
      color: Colors.grey,
      height: 0.36,
      margin: EdgeInsets.all(0.0),
      child: null,
    );
  }
  if ('header' == popupItem.value) {
    return Text(
      popupItem.title,
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  final Icon? icon = popupItem.icon;
  final bool isSelected =
      !editMode &&
      (popupItem.value == layout ||
          popupItem.value == sort ||
          popupItem.value == lang);
  final Color? selectedColor = isSelected
      ? Theme.of(context).colorScheme.primary
      : null;

  final Widget? leadingIcon = icon != null && !popupItem.trailingIcon
      ? (isSelected
            ? Icon(icon.icon, color: selectedColor, size: icon.size)
            : icon)
      : null;
  final Widget? trailingIcon = icon != null && popupItem.trailingIcon
      ? (isSelected
            ? Icon(icon.icon, color: selectedColor, size: icon.size)
            : icon)
      : null;

  // Only wrap the label in Expanded when a trailing icon must be pushed to
  // the right edge. popupButton is also embedded in unbounded-width rows
  // (e.g. the edit page title bar), where a flex child would throw.
  final Widget label = popupItem.trailingIcon
      ? Expanded(
          child: Text(
            popupItem.title,
            style: selectedColor != null
                ? TextStyle(color: selectedColor)
                : null,
            overflow: TextOverflow.ellipsis,
          ),
        )
      : Text(
          popupItem.title,
          style: selectedColor != null ? TextStyle(color: selectedColor) : null,
          overflow: TextOverflow.ellipsis,
        );

  return Row(
    children: <Widget>[
      if (leadingIcon != null) ...<Widget>[leadingIcon, SizedBox(width: 4.5)],
      label,
      if (trailingIcon != null) ...<Widget>[SizedBox(width: 4.5), trailingIcon],
    ],
  );
}
