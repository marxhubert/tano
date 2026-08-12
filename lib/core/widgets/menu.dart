import 'package:flutter/material.dart';
import 'package:tano/core/config/l10n.dart';

class PopupItem {
  final String title;
  final String value;
  final Icon? icon;
  PopupItem({required this.title, required this.value, this.icon});
}

/// Main menu items, resolved according to the current language.
Map<String, PopupItem> get menuItems {
  return <String, PopupItem>{
    'layout_title': PopupItem(
      title: AppText.tr('menu_display'),
      value: 'header',
      icon: null,
    ),
    'compact': PopupItem(
      title: AppText.tr('menu_compact'),
      icon: Icon(Icons.view_list),
      value: 'compact',
    ),
    'list': PopupItem(
      title: AppText.tr('menu_list'),
      icon: Icon(Icons.view_stream),
      value: 'list',
    ),
    'gridlist': PopupItem(
      title: AppText.tr('menu_grid'),
      icon: Icon(Icons.view_module),
      value: 'gridlist',
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
      icon: Icon(Icons.date_range),
    ),
    'alpha': PopupItem(
      title: AppText.tr('menu_title'),
      value: 'alpha',
      icon: Icon(Icons.sort_by_alpha),
    ),
    'important': PopupItem(
      title: AppText.tr('menu_favorites'),
      value: 'important',
      icon: Icon(Icons.star, color: Colors.orange),
    ),
    'category': PopupItem(
      title: AppText.tr('menu_category'),
      value: 'category',
      icon: Icon(Icons.bookmark_border),
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
    'en': PopupItem(
      title: AppText.tr('menu_english'),
      value: 'en',
      icon: Icon(Icons.language),
    ),
    'fr': PopupItem(
      title: AppText.tr('menu_french'),
      value: 'fr',
      icon: Icon(Icons.language),
    ),

    'info_separator': PopupItem(
      title: 'Separator',
      value: 'separator',
      icon: null,
    ),
    'info': PopupItem(
      title: AppText.tr('about'),
      value: 'info',
      icon: Icon(Icons.outlined_flag),
    ),
  };
}

/// Category list items, resolved according to the current language.
Map<String, PopupItem> get categoryElements {
  return <String, PopupItem>{
    'note': PopupItem(
      title: AppText.tr('category_note'),
      icon: Icon(Icons.bookmark, color: Colors.orange, size: 18.0),
      value: 'note',
    ),
    'work': PopupItem(
      title: AppText.tr('category_work'),
      icon: Icon(Icons.bookmark, color: Colors.red, size: 18.0),
      value: 'work',
    ),
    'personal': PopupItem(
      title: AppText.tr('category_personal'),
      icon: Icon(Icons.bookmark, color: Colors.blue, size: 18.0),
      value: 'personal',
    ),
    'travel': PopupItem(
      title: AppText.tr('category_travel'),
      icon: Icon(Icons.bookmark, color: Colors.green, size: 18.0),
      value: 'travel',
    ),
    'life': PopupItem(
      title: AppText.tr('category_life'),
      icon: Icon(Icons.bookmark, color: Colors.purple, size: 18.0),
      value: 'life',
    ),
    'project': PopupItem(
      title: AppText.tr('category_project'),
      icon: Icon(Icons.bookmark, color: Colors.yellow, size: 18.0),
      value: 'project',
    ),
    'none': PopupItem(
      title: AppText.tr('category_none'),
      icon: Icon(Icons.bookmark_border, color: null, size: 18.0),
      value: 'none',
    ),
  };
}

Widget popupButton({
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

  return editMode
      ? Row(
          children: <Widget>[
            popupItem.icon!,
            SizedBox(width: 4.5),
            Text(popupItem.title),
          ],
        )
      : Row(
          children: <Widget>[
            popupItem.icon!,
            SizedBox(width: 4.5),
            Text(popupItem.title),
            Expanded(child: Offstage()),
            (popupItem.value == layout ||
                    popupItem.value == sort ||
                    popupItem.value == lang)
                ? Icon(Icons.arrow_back_ios, size: 14.4)
                : Offstage(),
          ],
        );
}

Color themeCategory(String value, bool withShade) {
  switch (value) {
    case 'note':
      return withShade ? Colors.orange.shade50 : Colors.orange;
    case 'work':
      return withShade ? Colors.red.shade50 : Colors.red;
    case 'personal':
      return withShade ? Colors.blue.shade50 : Colors.blue;
    case 'travel':
      return withShade ? Colors.green.shade50 : Colors.green;
    case 'life':
      return withShade ? Colors.purple.shade50 : Colors.purple;
    case 'project':
      return withShade ? Colors.yellow.shade50 : Colors.yellow;
    default:
      return withShade ? Colors.white : Colors.grey.shade600;
  }
}
