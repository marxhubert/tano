import 'package:flutter/material.dart';

class MenuItem {
    final String title;
    final Icon icon;
    MenuItem({this.title, this.icon});
}

// Create a List of Menu Item for PopupMenuButton
List<MenuItem> menuItemList = [
    MenuItem(title: 'About', icon: Icon(Icons.info_outline)),
];

AlertDialog aboutDialog(BuildContext context) {
    return AlertDialog(
        contentPadding: EdgeInsets.all(36.0),
        title: Container(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                    const Text(
                        'Tano',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                        ),
                    ),
                    SizedBox(width: 9.0,),
                    const Text(
                        'v 1.0.0',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 18.0,
                        ),
                    )
                ],
            ),
        ),
        content: const Text(
            'The main goal of Tano is to provide a simple tool that lets you write notes to keep your ideas, create to-do lists and organize your projects at the same place. Tano prioritizes ease of use over bells and whistles.\n\n\nMarx Hubert 2020\nshikamarx@gmail.com',
        ),
        actions: <Widget>[
            FlatButton(
                child: const Text('CLOSE'),
                onPressed: () {
                    Navigator.of(context).pop();
                },
            ),
        ],
    );
}