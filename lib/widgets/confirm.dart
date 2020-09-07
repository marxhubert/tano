import 'package:flutter/material.dart';

Future<bool> getConfirmation({BuildContext context, String actionTitle, String action}) async {
    return await showDialog(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: Text(actionTitle),
                content: const Text(
                    'Voulez-vous vraiment continuer ?',
                ),
                actions: <Widget>[
                    FlatButton(
                        child: Text(
                            'ANNULER',
                            style: TextStyle(
                                color: Colors.blue,
                            ),
                        ),
                        onPressed: () {
                            Navigator.pop(context, false);
                        },
                    ),
                    FlatButton(
                        child: Text(
                            action.toUpperCase(),
                            style: TextStyle(
                                color: Colors.red,
                            ),
                        ),
                        onPressed: () {
                            Navigator.pop(context, true);
                        },
                    ),
                ],
            );
        },
    );
}