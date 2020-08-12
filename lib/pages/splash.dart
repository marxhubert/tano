import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
    @override
    SplashScreenState createState() => new SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
    startTime() async {
        var _duration = new Duration(seconds: 3);
        return new Timer(_duration, navigationPage);
    }

    void navigationPage() {
        Navigator.of(context).pushReplacementNamed('/home');
    }

    @override
    void initState() {
        super.initState();
        startTime();
    }

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            backgroundColor: Colors.blueGrey,
            body: new Stack(
                fit: StackFit.expand,
                children: <Widget>[
                    Center(
                        child: Column(
                            children: <Widget>[
                                Expanded(
                                    flex: 1,
                                    child: Center(
                                        child: CircleAvatar(
                                            radius: 54.0,
                                            child: Icon(
                                                Icons.playlist_add_check,
                                                size: 72.0,
                                            ),
                                        ),
                                    ),
                                ),
                                Container(
                                    height: 180.0,
                                    child: Center(
                                        child: const Text(
                                            'Tano',
                                            style: TextStyle(
                                                fontSize: 27.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                            ),
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    )
                ],
            ),
        );
    }
}