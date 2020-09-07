import 'package:flutter/material.dart';
import 'package:tano/utils/dialog.dart';

Future<String> dialogContent({BuildContext context, DialogAlert dialogAlert}) async {
    return await showDialog(
        context: context,
        builder: (context) {
            return Dialog(
                child: _dialog(context: context, dialogAlert: dialogAlert),
            );
        },
    );
}

_dialog({BuildContext context, DialogAlert dialogAlert}) {
    String title = dialogAlert.title;
    String subtitle = '';
    Widget content = dialogAlert.content;
    List<Widget> actions = [];

    if (dialogAlert.subtitle != null) {
        subtitle = dialogAlert.subtitle;
    }
    if (dialogAlert.actions.length > 0) {
        dialogAlert.actions.forEach((FlatButton flatButton) {
            actions.add(Expanded(child: flatButton));
        });
    }

    return Container(
        color: Colors.white,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
                Container(
                    color: Colors.blue,
                    height: 63.0,
                    child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 21.0),
                        margin: EdgeInsets.only(bottom: 1.8),
                        child: Row(
                            children: <Widget>[
                                Expanded(
                                    child: Text(
                                        '$title',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 14.4,
                                        ),
                                    ),
                                ),
                                Text(
                                    '$subtitle',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: Colors.blue,
                                        fontSize: 12.0,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                Container(
                    child: Column(
                        children: <Widget>[
                            content,
                        ],
                    ),
                ),
                actions.length == 0
                ? Offstage()
                : Container(
                    color: Colors.blue,
                    height: 63.0,
                    child: Container(
                        color: Colors.white,
                        margin: EdgeInsets.only(top: 1.8),
                        child: Row(
                            children: actions,
                        ),
                    ),
                ),
            ],
        ),
    );
}