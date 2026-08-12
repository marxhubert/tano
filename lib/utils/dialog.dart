import 'package:flutter/material.dart';

class DialogAlert {
    final String? title;
    final String? subtitle;
    final Widget? content;
    final List<Widget>? actions;
    DialogAlert({this.title, this.subtitle, this.content, this.actions});
}
