import 'package:flutter/material.dart';
import 'package:tano/pages/home.dart';
import 'package:tano/pages/splash.dart';

void main() {
    runApp(Tano());
}

class Tano extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tano',
            theme: ThemeData(
                primarySwatch: Colors.blueGrey,
            ),
            home: SplashScreen(),
            routes: <String, WidgetBuilder>{
                '/home': (BuildContext context) => Home(),
            },
        );
    }
}