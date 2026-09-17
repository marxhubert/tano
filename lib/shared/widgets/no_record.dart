import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

Widget noRecordFound(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 90.0,
          height: 90.0,
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: 90.0,
                height: 90.0,
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade500,
                  child: Icon(
                    Symbols.bookmark,
                    color: Colors.blueGrey.shade50,
                    size: 45.0,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(child: Offstage()),
                  Column(
                    children: <Widget>[
                      Expanded(child: Offstage()),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Symbols.warning,
                          color: primaryTextColor(context),
                          size: 45.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.only(bottom: appPaddingLarge)),
        Text(
          AppText.tr('no_data'),
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: TanoText.label),
        ),
      ],
    ),
  );
}
