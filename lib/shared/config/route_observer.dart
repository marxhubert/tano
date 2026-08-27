import 'package:flutter/widgets.dart';

/// Global [RouteObserver] shared by the app so that pages can react to
/// navigation changes (for example, dismissing a snack bar when the user
/// leaves the page that showed it).
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
