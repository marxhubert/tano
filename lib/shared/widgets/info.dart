import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

AlertDialog aboutInfo({
  required BuildContext context,
  PackageInfo? packageInfo,
}) {
  return AlertDialog(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(
          width: 36.0,
          height: 36.0,
          child: CircleAvatar(
            backgroundColor: Colors.black87,
            child: Icon(Icons.bookmark_border, size: 21.0, color: Colors.white),
          ),
        ),
        Padding(padding: EdgeInsets.only(right: 9.0)),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: AppConfig.appName,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor(context),
                fontSize: 18.0,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: AppConfig.appNameSuffix,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: primaryTextColor(context),
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          packageInfo?.version ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: primaryTextColor(context),
            fontSize: 14.4,
          ),
        ),
      ],
    ),
    content: RichText(
      text: TextSpan(
        text: AppText.tr('about_description'),
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: primaryTextColor(context),
          fontSize: 14.4,
          height: 1.5,
        ),
        children: <TextSpan>[
          TextSpan(
            text: '\n\n${AppConfig.authorName}\n${AppConfig.authorEmail}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryTextColor(context),
              fontSize: 14.4,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        child: Text(
          AppText.tr('close_button'),
          style: TextStyle(color: Colors.blue),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
}
