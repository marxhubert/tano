import 'package:flutter/material.dart';

class PopupItem {
    final String title;
    final String value;
    final Icon icon;
    PopupItem({this.title, this.value, this.icon});
}

Map<String, PopupItem> menuItems = {
    'layout_title'  : PopupItem(title: 'Affichage', value: 'header', icon: null),
    'compact' : PopupItem(title: 'Compact', icon: Icon(Icons.view_list), value: 'compact'),
    'list' : PopupItem(title: 'Liste', icon: Icon(Icons.view_stream), value: 'list'),
    'gridlist' : PopupItem(title: 'Grille', icon: Icon(Icons.view_module), value: 'gridlist'),

    'sorting_separator'  : PopupItem(title: 'Separator', value: 'separator', icon: null),
    'sorting_title'  : PopupItem(title: 'Triage', value: 'header', icon: null),
    'date'     : PopupItem(title: 'Date', value: 'date', icon: Icon(Icons.date_range)),
    'alpha'    : PopupItem(title: 'Titre', value: 'alpha', icon: Icon(Icons.sort_by_alpha)),
    'important' : PopupItem(title: 'Favoris', value: 'important', icon: Icon(Icons.star, color: Colors.orange)),
    'category' : PopupItem(title: 'Catégorie', value: 'category', icon: Icon(Icons.bookmark_border)),

    'info_separator'  : PopupItem(title: 'Separator', value: 'separator', icon: null),
    'info' : PopupItem(title: 'À propos', value: 'info', icon: Icon(Icons.outlined_flag)),
};

Map<String, PopupItem> categoryElements = {
    'note'     : PopupItem(title: 'Note', icon: Icon(Icons.bookmark, color: Colors.orange, size: 18.0,), value: 'note'),
    'work'     : PopupItem(title: 'Travail', icon: Icon(Icons.bookmark, color: Colors.red, size: 18.0,), value: 'work'),
    'personal' : PopupItem(title: 'Personnel', icon: Icon(Icons.bookmark, color: Colors.blue, size: 18.0,), value: 'personal'),
    'travel'   : PopupItem(title: 'Voyage', icon: Icon(Icons.bookmark, color: Colors.green, size: 18.0,), value: 'travel'),
    'life'     : PopupItem(title: 'Vie', icon: Icon(Icons.bookmark, color: Colors.purple, size: 18.0,), value: 'life'),
    'project'  : PopupItem(title: 'Projet', icon: Icon(Icons.bookmark, color: Colors.yellow, size: 18.0,), value: 'project'),
    'none'     : PopupItem(title: 'Libre', icon: Icon(Icons.bookmark_border, color: null, size: 18.0,), value: 'none'),
};

Widget popupButton({PopupItem popupItem, String layout, String sort, bool editMode = false}) {
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
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
            ),
        );
    }

    return editMode
        ? Row(
            children: <Widget>[
                popupItem.icon,
                SizedBox(width: 4.5),
                Text(popupItem.title),
            ],
        )
        : Row(
            children: <Widget>[
                popupItem.icon,
                SizedBox(width: 4.5),
                Text(popupItem.title),
                Expanded(child: Offstage(),),
                (popupItem.value == layout || popupItem.value == sort)
                    ? Icon(Icons.arrow_back_ios, size: 14.4,) : Offstage(),
            ],
        )
    ;
}

Color themeCategory(String value, bool withShade) {
    switch (value) {
        case 'note':
            return withShade ? Colors.orange.shade50 : Colors.orange;
            break;
        case 'work':
            return withShade ? Colors.red.shade50 : Colors.red;
            break;
        case 'personal':
            return withShade ? Colors.blue.shade50 : Colors.blue;
            break;
        case 'travel':
            return withShade ? Colors.green.shade50 : Colors.green;
            break;
        case 'life':
            return withShade ? Colors.purple.shade50 : Colors.purple;
            break;
        case 'project':
            return withShade ? Colors.yellow.shade50 : Colors.yellow;
            break;
        default:
            return withShade ? Colors.white : Colors.grey.shade600;
            break;
    }
}


