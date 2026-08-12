import 'package:flutter/material.dart';

Future<bool?> getConfirmation({required BuildContext context, required String actionTitle, required String action}) async {
    return await showDialog<bool>(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: Text(actionTitle),
                content: const Text(
                    'Voulez-vous vraiment continuer ?',
                ),
                actions: <Widget>[
                    TextButton(
                        child: Text(
                            action.toLowerCase() == 'enregistrer' ? 'QUITTER' : 'ANNULER',
                            style: TextStyle(
                                color: action.toLowerCase() == 'enregistrer' ? Colors.red : Colors.blue,
                            ),
                        ),
                        onPressed: () {
                            Navigator.pop(context, false);
                        },
                    ),
                    TextButton(
                        child: Text(
                            action.toUpperCase(),
                            style: TextStyle(
                                color: action.toLowerCase() == 'enregistrer' ? Colors.blue : Colors.red,
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
