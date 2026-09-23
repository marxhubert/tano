import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';

/// Folds a page's FAB once another route has fully covered it.
///
/// Pushing a route covers the page at once, but the collapse should look like
/// it already happened when the user comes back: wait out the push animation,
/// then collapse only if the page is still not the current route. Returning
/// quickly cancels the pending fold, so it cannot close a FAB the user has
/// already reopened. Pages using this mixin must also mix in [RouteAware].
mixin FabRouteCollapse<T extends StatefulWidget> on State<T>, RouteAware {
  /// Key of the FAB to fold. The page owns the widget it points at.
  GlobalKey<AppFabState> get fabKey;

  Timer? _routeCollapseTimer;
  int _routeCollapseGeneration = 0;

  /// Cancels any pending fold. Call it from [State.dispose].
  void disposeFabRouteCollapse() {
    _routeCollapseGeneration++;
    _routeCollapseTimer?.cancel();
  }

  @override
  void didPushNext() {
    _routeCollapseTimer?.cancel();
    final int generation = ++_routeCollapseGeneration;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    _routeCollapseTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted &&
          generation == _routeCollapseGeneration &&
          route?.isCurrent == false) {
        fabKey.currentState?.collapse();
      }
    });
  }

  @override
  void didPopNext() {
    // A quick return invalidates the delayed fold from the outgoing route.
    _routeCollapseGeneration++;
    _routeCollapseTimer?.cancel();
  }
}
