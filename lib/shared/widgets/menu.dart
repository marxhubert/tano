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

    'sorting_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'sorting_title': PopupItem(
      title: AppText.tr('menu_sorting'),
      value: 'header',
      icon: null,
    ),
    'date': PopupItem(
      title: AppText.tr('menu_date'),
      value: 'date',
      icon: null,
    ),
    'alpha': PopupItem(
      title: AppText.tr('menu_title'),
      value: 'alpha',
      icon: null,
    ),
    'important': PopupItem(
      title: AppText.tr('menu_favorites'),
      value: 'important',
      icon: null,
    ),
    'category': PopupItem(
      title: AppText.tr('menu_category'),
      value: 'category',
      icon: null,
    ),

    'theme_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'theme_title': PopupItem(
      title: AppText.tr('menu_theme'),
      value: 'header',
      icon: null,
    ),
    'theme_light': PopupItem(
      title: AppText.tr('theme_light'),
      value: 'theme_light',
      icon: null,
    ),
    'theme_dark': PopupItem(
      title: AppText.tr('theme_dark'),
      value: 'theme_dark',
      icon: null,
    ),
    'theme_system': PopupItem(
      title: AppText.tr('theme_system'),
      value: 'theme_system',
      icon: null,
    ),

    'language_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'language_title': PopupItem(
      title: AppText.tr('menu_language'),
      value: 'header',
      icon: null,
    ),
    'en': PopupItem(title: AppText.tr('menu_english'), value: 'en', icon: null),
    'fr': PopupItem(title: AppText.tr('menu_french'), value: 'fr', icon: null),

    'info_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'info': PopupItem(title: AppText.tr('about'), value: 'info', icon: null),
  };
}

/// Category list items, resolved according to the current language.
Map<String, PopupItem> get categoryElements {
  return <String, PopupItem>{
    'neutral': PopupItem(
      title: AppText.tr('category_none'),
      icon: const Icon(Icons.bookmark_border, size: 18.0),
      value: 'neutral',
    ),
    'action': PopupItem(
      title: AppText.tr('category_work'),
      icon: const Icon(Icons.bookmark, color: tanoTeal, size: 18.0),
      value: 'action',
    ),
    'success': PopupItem(
      title: AppText.tr('category_note'),
      icon: const Icon(Icons.bookmark, color: Colors.green, size: 18.0),
      value: 'success',
    ),
    'warning': PopupItem(
      title: AppText.tr('category_personal'),
      icon: const Icon(Icons.bookmark, color: Colors.orange, size: 18.0),
      value: 'warning',
    ),
    'error': PopupItem(
      title: AppText.tr('category_travel'),
      icon: const Icon(Icons.bookmark, color: Colors.red, size: 18.0),
      value: 'error',
    ),
    'purple': PopupItem(
      title: AppText.tr('category_life'),
      icon: const Icon(Icons.bookmark, color: Colors.purple, size: 18.0),
      value: 'purple',
    ),
    'yellow': PopupItem(
      title: AppText.tr('category_project'),
      icon: const Icon(Icons.bookmark, color: Colors.yellow, size: 18.0),
      value: 'yellow',
    ),
    'reference': PopupItem(
      title: 'Reference',
      icon: const Icon(Icons.bookmark, color: Colors.blue, size: 18.0),
      value: 'reference',
    ),
    'subtle': PopupItem(
      title: 'Subtle',
      icon: const Icon(Icons.bookmark, color: Colors.blueGrey, size: 18.0),
      value: 'subtle',
    ),
    'archive': PopupItem(
      title: 'Archive',
      icon: const Icon(Icons.bookmark, color: Colors.grey, size: 18.0),
      value: 'archive',
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
