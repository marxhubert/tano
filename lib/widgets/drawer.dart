import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:tano/pages/home.dart';
import 'info.dart';

class DrawerMenu extends StatefulWidget {
    @override
    _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
    @override
    Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
                DrawerHeader(
                    padding: EdgeInsets.zero,
                    child: Icon(
                        Icons.playlist_add_check,
                        size: 180.0,
                        color: Colors.white54,
                    ),
                    decoration: BoxDecoration(color: Colors.black54),
                ),
                MenuList(),
            ],
        ),
    );
    }
}

class MenuList extends StatefulWidget {
    @override
    _MenuListState createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
    PackageInfo _packageInfo = PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: 'Unknown',
        buildNumber: 'Unknown',
    );

    @override
    void initState() {
        super.initState();
        _initPackageInfo();
    }

    Future<void> _initPackageInfo() async {
        final PackageInfo info = await PackageInfo.fromPlatform();
        setState(() {
            _packageInfo = info;
        });
    }

    @override
    Widget build(BuildContext context) {
    return Column(
        children: <Widget>[
            ListTile(
                leading: Icon(Icons.home),
                title: Text('Accueil'),
                onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
                },
            ),
            Divider(color: Colors.grey,),
            ListTile(
                leading: Icon(Icons.info),
                title: Text('À propos'),
                onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (BuildContext context) => aboutInfo(context: context, packageInfo: _packageInfo));
                },
            ),
        ],
    );
    }
}

