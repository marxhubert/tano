import 'package:flutter/material.dart';
import 'package:tano/pages/home.dart';
import 'package:tano/pages/search.dart';
import 'package:tano/pages/splash.dart';

void main() {
    runApp(Tano());
}

class Tano extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TanoNote',
            theme: ThemeData(
                primaryColor: Colors.blueGrey.shade50,
                canvasColor: Colors.blueGrey.shade50,
            ),
            home: SplashScreen(),
            routes: <String, WidgetBuilder>{
                '/home': (BuildContext context) => Home(),
                '/search': (BuildContext context) => SearchPage(),
            },
        );
    }
}