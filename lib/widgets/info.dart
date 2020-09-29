import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

AlertDialog aboutInfo({BuildContext context, PackageInfo packageInfo}) {
    return AlertDialog(
        title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
                Container(
                    width: 36.0,
                    height: 36.0,
                    child: CircleAvatar(
                        backgroundColor: Colors.black87,
                        child: Icon(Icons.bookmark_border, size: 21.0, color: Colors.white,),
                    ),
                ),
                Padding(
                    padding: EdgeInsets.only(right: 9.0),
                ),
                Expanded(
                    child: RichText(
                        text: TextSpan(
                            text: 'Tano',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                fontSize: 18.0,
                            ),
                            children: <TextSpan>[
                                TextSpan(
                                    text: 'Note',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                        fontSize: 18.0,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                Text(
                    '${packageInfo.version}',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontSize: 14.4,
                    ),
                ),
            ],
        ),
        content: RichText(
            text: TextSpan(
                text: 'TanoNote est un simple outil de prise de note qui pourra, je l\'espère vivement, vous être utile pour sauvegarder vos idées.\nJe vous invite à me faire part de vos remarques et conseils pour me donner le plaisir de continuer à l\'améliorer. Merci.',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    fontSize: 14.4,
                    height: 1.5,
                ),
                children: <TextSpan>[
                    TextSpan(
                        text: '\n\nMarx Hubert\nshikamarx@gmail.com',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 14.4,
                            height: 1.5,
                        ),
                    ),
                ],
            ),
        ),
        actions: [
            FlatButton(
                child: Text(
                    'FERMER',
                    style: TextStyle(
                        color: Colors.blue,
                    ),
                ),
                onPressed: () {
                    Navigator.of(context).pop();
                },
            ),
        ],
    );
}