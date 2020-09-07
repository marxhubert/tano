import 'package:flutter/material.dart';

Widget noRecordFound() {
    return Container(
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                    Container(
                        width: 90.0,
                        height: 90.0,
                        child: Stack(
                            children: <Widget>[
                                Container(
                                    width: 90.0,
                                    height: 90.0,
                                    child: CircleAvatar(
                                        backgroundColor: Colors.grey.shade500,
                                        child: Icon(Icons.bookmark_border, color: Colors.blueGrey.shade50, size: 45.0,),
                                    ),
                                ),
                                Row(
                                    children: <Widget>[
                                        Expanded(child: Offstage(),),
                                        Column(
                                            children: <Widget>[
                                                Expanded(child: Offstage(),),
                                                Container(
                                                    alignment: Alignment.bottomRight,
                                                    child: Icon(Icons.warning, color: Colors.black87, size: 45.0,),
                                                ),
                                            ],
                                        )
                                    ],
                                ),
                            ],
                        ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(bottom: 18.0),
                    ),
                    Text(
                        'Pas de donnée',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 15.0,
                        ),
                    ),
                ],
            ),
        ),
    );
}