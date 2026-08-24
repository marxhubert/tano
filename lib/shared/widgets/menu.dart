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
    'gridlist': PopupItem(
      title: AppText.tr('menu_grid'),
      icon: const Icon(Icons.view_module, size: 24.0),
      value: 'gridlist',
      trailingIcon: true,
    ),
    'list': PopupItem(
      title: AppText.tr('menu_list'),
      icon: const Icon(Icons.view_stream, size: 24.0),
      value: 'list',
      trailingIcon: true,
    ),
    'separator': PopupItem(
      title: '',
      value: 'separator',
      icon: null,
    ),
    'settings': PopupItem(
      title: AppText.tr('settings'),
      value: 'settings',
      icon: const Icon(Icons.settings_outlined, size: 24.0),
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

  final Widget label = Text(
    popupItem.title,
    style: TextStyle(
      color: selectedColor ?? primaryTextColor(context),
      fontSize: 14.0,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    ),
    overflow: TextOverflow.ellipsis,
  );

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    visualDensity: const VisualDensity(vertical: -4.0),
    dense: true,
    title: label,
    trailing: icon != null
        ? Icon(
            icon.icon,
            color: selectedColor ?? mutedTextColor(context),
            size: 20.0,
          )
        : null,
  );
}
