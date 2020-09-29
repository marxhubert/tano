import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
    @override
    SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
    startTime() async {
        var _duration = Duration(seconds: 3);
        return Timer(_duration, navigationPage);
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
        return Scaffold(
            backgroundColor: Colors.blueGrey.shade50,
            body: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                    Center(
                        child: Column(
                            children: <Widget>[
                                Expanded(
                                    flex: 1,
                                    child: Center(
                                        child: Container(
                                            width: 90.0,
                                            height: 90.0,
                                            child: CircleAvatar(
                                                radius: 54.0,
                                                backgroundColor: Colors.black87,
                                                child: Icon(Icons.turned_in_not, color: Colors.white, size: 45.0,),
                                            ),
                                        ),
                                    ),
                                ),
                                Container(
                                    height: 90.0,
                                    child: Center(
                                        child: RichText(
                                            text: TextSpan(
                                                text: 'Tano',
                                                style: TextStyle(
                                                    fontSize: 21.0,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.black87,
                                                ),
                                                children: <TextSpan>[
                                                    TextSpan(
                                                        text: 'Note',
                                                        style: TextStyle(
                                                            fontSize: 21.0,
                                                            fontWeight: FontWeight.w400,
                                                            color: Colors.black87,
                                                        ),
                                                    ),
                                                ]
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