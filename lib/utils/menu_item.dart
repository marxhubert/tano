import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/pages/home.dart';

class MenuItem {
    final String title;
    final Icon icon;
    MenuItem({required this.title, required this.icon});
}

// Create a List of Menu Item for PopupMenuButton
List<MenuItem> menuItemList = [
    MenuItem(title: 'View', icon: Icon(Icons.view_list)),
    MenuItem(title: 'About', icon: Icon(Icons.info_outline)),
];

Future<void> addViewPrefToSP(BuildContext context, String viewPref) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('viewPref', viewPref);
    if (!context.mounted) {
        return;
    }
    Navigator.pop(
        context,
        MaterialPageRoute(
            builder: (context) => Home(),
            fullscreenDialog: true
        ),
    );
}

AlertDialog viewDialog(BuildContext context) {
    return AlertDialog(
        contentPadding: EdgeInsets.all(0.0),
        content: SizedBox(
            width: 360.0,
            height: 207.0,
            child: Column(
                children: <Widget>[
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 36.0),
                        height: 72.0,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                                Text(
                                    'View',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 21.0,
                                        color: Colors.blueGrey.shade600,
                                    ),
                                )
                            ],
                        ),
                    ),
                    Container(
                        height: 2.1,
                        color: Colors.blueGrey.shade600,
                    ),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 0.0),
                        child: Column(
                            children: <Widget>[
                                ListTile(
                                    leading: Icon(Icons.view_stream, color: Colors.black,),
                                    title: Text('List'),
                                    contentPadding: EdgeInsets.only(left: 36.0),
                                    onTap: () {
                                        addViewPrefToSP(context, 'list');
                                    },
                                ),
                                Divider(thickness: 1.2,),
                                ListTile(
                                    leading: Icon(Icons.view_module, color: Colors.black,),
                                    title: Text('Grid'),
                                    contentPadding: EdgeInsets.only(left: 36.0),
                                    onTap: () {
                                        addViewPrefToSP(context, 'grid');
                                    },
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    );
}

AlertDialog aboutDialog(BuildContext context) {
    return AlertDialog(
        contentPadding: EdgeInsets.all(36.0),
        title: Row(
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
                        'v 0.1.0',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 18.0,
                        ),
                    )
                ],
            ),
        content: const Text(
            'The main goal of Tano is to provide a simple tool that lets you write notes to keep your ideas, create to-do lists and organize your projects at the same place. Tano prioritizes ease of use over bells and whistles.\n\n\nMarx Hubert 2020\nshikamarx@gmail.com',
        ),
        actions: <Widget>[
            TextButton(
                child: const Text('CLOSE'),
                onPressed: () {
                    Navigator.of(context).pop();
                },
            ),
        ],
    );
}
