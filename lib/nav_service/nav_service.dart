import 'dart:async';

import 'package:flutter/material.dart';
import 'nav_link_handler.dart';
import 'nav_link_result.dart';
import 'nav_extra.dart';
import 'nav_route.dart';
import 'nav_route_info.dart';
import 'nav_state.dart';
import 'nav_step.dart';

part 'navigator_inheritance_service_ext.dart';
part 'linking_service_ext.dart';
part 'page_aware.dart';
part 'persistence_service_ext.dart';

class NavServiceConfig {
  const NavServiceConfig({
    required this.routes,
    required this.navigatorKey,
    this.enableLogger = true,
    this.linkPrefixes,
    this.linkHandlers,
    this.persistence,
  });

  /// List of navigation routes
  final List<NavRoute> routes;

  /// Navigator key to access navigator state
  final GlobalKey<NavigatorState> navigatorKey;

  /// Enable logging for navigation actions
  final bool enableLogger;

  /// List of link prefixes to match incoming URLs against.
  final List<String>? linkPrefixes;

  /// List of link handlers to process specific link patterns.
  final List<NavLinkHandler>? linkHandlers;

  final NavPagePersistence? persistence;
}

class NavPagePersistence {
  const NavPagePersistence({
    required this.onPersist,
    required this.onRestore,
    this.enableSchedule = false,
    this.schedule,
  });

  /// Whether to enable scheduled persistence.
  final bool enableSchedule;

  /// Callback to persist the current navigation state.
  final Future<void> Function(List<Map<String, dynamic>> data) onPersist;

  /// Callback to restore the navigation state.
  final Future<List<Map<String, dynamic>>> Function() onRestore;

  /// Schedule configuration for persistence.
  final NavPagePersistenceSchedule? schedule;
}

class NavPagePersistenceSchedule {
  const NavPagePersistenceSchedule({this.interval, this.immediate});

  /// Interval duration for scheduled persistence.
  final Duration? interval;

  /// Whether to perform immediate persistence on route changes.
  final bool? immediate;
}

class NavService {
  // Factory returns the single instance
  factory NavService() => instance;

  // Private constructor
  NavService._internal();
  // Singleton instance
  static final NavService instance = NavService._internal();

  // Commonly used navigator key (you can remove or extend as needed)
  GlobalKey<NavigatorState>? _navigatorKey;

  final List<NavStep> _steps = [];

  final Map<String, NavRoute> _routes = {};

  final List<String> _linkPrefixes = [];

  final List<NavLinkHandler> _linkHandlers = [];

  NavPagePersistence? _persistence;
  bool _launchedSchedule = false;

  BuildContext? get _currentContext => _navigatorKey?.currentContext;

  /// Route observer to monitor navigation events
  /// Use a single instance so `RouteAware` subscriptions register
  /// against the same observer that is attached to the Navigator.
  final RouteObserver<PageRoute> _routeObserver = _RouteObserver();

  RouteObserver<PageRoute> get routeObserver => _routeObserver;

  bool _enableLogger = true;

  /// Initialize the NavService with configuration
  ///
  /// Clean up previous configuration if exists
  void init(NavServiceConfig config) {
    _routes
      ..clear()
      ..addAll({for (final route in config.routes) route.path: route});

    _navigatorKey = config.navigatorKey;

    _enableLogger = config.enableLogger;

    if (config.linkPrefixes != null) {
      _linkPrefixes.clear();
      _linkPrefixes.addAll(config.linkPrefixes!);
    }

    if (config.linkHandlers != null) {
      _initLinkHandlers(config.linkHandlers!);
    }

    _persistence = config.persistence;
  }

  /// context.go():
  ///  - route is the last route in full path
  ///  - previousRoute is the route before go(), not is the previous route in
  ///  full path
  ///
  /// context.push():
  /// - route is the new route being pushed
  /// - previousRoute is the current route before push()
  void _didPush(Route route, Route? previousRoute) {
    // // You can add custom logic here if needed

    final routeName = route.settings.name ?? '';
    if (routeName.isEmpty) return;

    final context = route.navigator?.context;
    if (context == null) return;

    final state = NavState.fromRoute(route);

    final prevState = _steps.isNotEmpty ? _steps.last.currentState : null;

    if (state != null) {
      if (_enableLogger) {
        debugPrint(
          'NavService._didPush - $routeName is a valid NavService route.',
        );
      }
      _steps.add(
        NavStep(
          path: routeName,
          prevState: prevState,
          currentState: state,
          currentRoute: route,
          prevRoute: previousRoute,
        ),
      );
    } else {
      // If extra is not NavExtra, clear the navigation history
      // as we cannot track it properly
      // Ex: GoRouter's context.go(), Navigator push, replace actions
      if (_enableLogger) {
        debugPrint(
          'NavService._didPush - ${route.settings.name} extra is an'
          ' invalid NavService route. So clearing navigation history.',
        );
      }

      _steps.clear();
    }

    _persistImmediate();

    if (_enableLogger) {
      debugPrint('NavService._didPush location: $joinedLocation');
    }
  }

  void _didPop(Route route, Route? previousRoute) {
    final routeName = route.settings.name ?? '';
    if (routeName.isEmpty) return;

    if (_steps.isNotEmpty) {
      _steps.removeLast();
    }

    _persistImmediate();

    if (_enableLogger) {
      debugPrint('NavService._didPop location: $joinedLocation');
    }
  }

  void _didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute != null && newRoute != null) {
      // Find and update the step with the old route
      for (int i = 0; i < _steps.length; i++) {
        if (_steps[i].currentRoute == oldRoute) {
          final oldStep = _steps[i];
          final newState = NavState.fromRoute(newRoute);

          if (newState != null) {
            _steps[i] = NavStep(
              path: newState.path,
              prevState: oldStep.prevState,
              currentState: newState,
              currentRoute: newRoute,
              prevRoute: oldStep.prevRoute,
            );
          } else {
            // If new route doesn't have NavExtra, remove the step
            _steps.removeAt(i);
          }
          break;
        }
      }
    }

    _persistImmediate();

    if (_enableLogger) {
      debugPrint('NavService._didReplace location: $joinedLocation');
    }
  }

  void _didRemove({Route? oldRoute, Route? previousRoute}) {
    if (oldRoute != null) {
      // Remove the step that matches the removed route
      _steps.removeWhere((step) => step.currentRoute == oldRoute);
    }

    _persistImmediate();

    if (_enableLogger) {
      debugPrint('NavService._didRemove location: $joinedLocation');
    }
  }

  String get joinedLocation {
    final context = _currentContext;
    if (context == null) return '';
    return _steps.map((e) => e.currentState.path).join();
  }

  MaterialPageRoute<T> _buildPageRoute<T>({
    required String path,
    required NavExtra extra,
    required NavRoute route,
  }) {
    return MaterialPageRoute<T>(
      settings: RouteSettings(name: path, arguments: extra),
      builder: (ctx) => route.builder(ctx, NavState(path: path, extra: extra)),
    );
  }

  MaterialPageRoute<T> _buildPageRouteNoPushAnimation<T>({
    required String path,
    required NavExtra extra,
    required NavRoute route,
  }) {
    // ignore: inference_failure_on_instance_creation
    return _NoTransitionMaterialPageRoute(
      settings: RouteSettings(name: path, arguments: extra),
      builder:
          (context) =>
              route.builder(context, NavState(path: path, extra: extra)),
    );
  }

  void _persistImmediate() {
    final persistence = _persistence;
    if (persistence == null || !persistence.enableSchedule) return;

    if (!_launchedSchedule) return;

    final immediate = persistence.schedule?.immediate ?? false;

    if (immediate) persist();
  }

  void _persistInterval() {
    final persistence = _persistence;
    if (persistence == null || !persistence.enableSchedule) return;

    final interval = persistence.schedule?.interval;
    if (interval == null) return;

    Timer.periodic(interval, (timer) {
      if (!_launchedSchedule) return;
      persist();
    });
  }

  Future<List<NavRouteInfo>> _getRestoredRoutes() async {
    final persistence = _persistence;
    if (persistence == null || !persistence.enableSchedule) return [];

    final data = await persistence.onRestore();

    return _validateAndParseRoutes(data);
  }

  //
  // Main navigation methods
  //

  /// Call this method when app is launched to restore
  /// or set initial routes
  Future<void> launched(List<NavRouteInfo> routes) async {
    final restoredRoutes = await _getRestoredRoutes();
    _launchedSchedule = true;
    replaceAll(restoredRoutes.isNotEmpty ? restoredRoutes : routes);
    _persistImmediate();
    _persistInterval();
  }

  /// If the path exists in the navigation history, navigate back to it.
  /// If not, push a new route.
  ///
  /// [forcePush] forces pushing a new route even if it exists in history.
  void navigate(
    String path, {
    Map<String, dynamic>? extra,
    bool forcePush = false,
  }) {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.navigate: No valid context found.');
        }
        return;
      }

      final navExtra = NavExtra(extra ?? {});
      final route = _routes[path];

      if (route == null) {
        if (_enableLogger) {
          debugPrint('NavService.navigate: Route not found for path: $path');
        }
        return;
      }

      final navigator = Navigator.of(context);
      final newRoute = _buildPageRoute<dynamic>(
        path: path,
        extra: navExtra,
        route: route,
      );

      // Find if path exists in navigation history
      int existingIndex = -1;
      if (!forcePush) {
        for (int i = _steps.length - 1; i >= 0; i--) {
          if (_steps[i].currentState.path == path) {
            existingIndex = i;
            break;
          }
        }
      }

      if (existingIndex != -1) {
        // Calculate how many routes to remove (all routes after and including
        // the target)
        final routesToRemoveCount = _steps.length - existingIndex;
        int removeCounter = 0;

        navigator.pushAndRemoveUntil(newRoute, (route) {
          // Remove routes from top until we reach the desired point
          removeCounter++;
          return removeCounter > routesToRemoveCount;
        });
      } else {
        // Path doesn't exist or forcePush is true, push new
        navigator.push(newRoute);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.navigate.exception: $e\n$st');
      }
    }
  }

  /// Pop all routes with animation
  void popAll() {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.popAll: No valid context found.');
        }
        return;
      }

      if (_steps.isEmpty) {
        if (_enableLogger) {
          debugPrint('NavService.popAll: No steps to pop.');
        }
        return;
      }

      final navigator = Navigator.of(context);
      final routesToPop = _steps.length;

      if (routesToPop == 1) {
        // Only one route, pop with animation
        navigator.pop();
      } else {
        // Get all routes in the navigator
        final List<Route> allRoutes = [];
        navigator.popUntil((route) {
          allRoutes.add(route);
          return allRoutes.length > routesToPop;
        });
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.popAll.exception: $e\n$st');
      }
    }
  }

  /// Pops routes until the given [path] is reached
  void popUntilPath(String path) {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.popUntilPath: No valid context found.');
        }
        return;
      }

      Navigator.of(context).popUntil((route) => route.settings.name == path);
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.popUntilPath.exception: $e\n$st');
      }
    }
  }

  /// Required call before call GoRouter's context.go()
  ///
  /// Remove all routes without animation
  ///
  /// Caution: If use NavService standalone without GoRouter, DON'T call this method
  /// because it can lead to error _history.isEmpty.
  ///
  /// Insteads use removeUntil
  void removeAll() {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.removeAll: No valid context found.');
        }
        return;
      }

      if (_steps.isEmpty) {
        if (_enableLogger) {
          debugPrint('NavService.removeAll: No steps to remove.');
        }
        return;
      }

      final navigator = Navigator.of(context);

      // Create a copy of steps to avoid ConcurrentModificationError
      final stepsToRemove = List<NavStep>.from(_steps.reversed);

      // Remove routes without animation in reverse order using routes
      // from steps
      for (final step in stepsToRemove) {
        if (step.currentRoute.isActive) {
          navigator.removeRoute(step.currentRoute);
        }
      }

      // Clear internal navigation history will be handled in _didRemove
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.removeAll.exception: $e\n$st');
      }
    }
  }

  /// Adds the corresponding pages to given [routeInfos] list to the _steps
  /// stack at once
  /// Similar to AutoRoute's pushAll method
  void pushAll(List<NavRouteInfo> routeInfos) {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.pushAll: No valid context found.');
        }
        return;
      }

      if (routeInfos.isEmpty) {
        if (_enableLogger) {
          debugPrint('NavService.pushAll: No routeInfos provided.');
        }
        return;
      }

      final navigator = Navigator.of(context);

      // Push all routes sequentially
      for (int i = 0; i < routeInfos.length; i++) {
        final routeInfo = routeInfos[i];
        final route = _routes[routeInfo.path];

        if (route != null) {
          final navExtra = NavExtra(routeInfo.extra ?? {});

          if (i == routeInfos.length - 1) {
            // Last route with animation
            navigator.push(
              _buildPageRoute<dynamic>(
                path: routeInfo.path,
                extra: navExtra,
                route: route,
              ),
            );
          } else {
            // Other routes without push animation but with pop animation
            navigator.push(
              _buildPageRouteNoPushAnimation(
                path: routeInfo.path,
                extra: navExtra,
                route: route,
              ),
            );
          }
        } else {
          if (_enableLogger) {
            debugPrint(
              'NavService.pushAll: Route not found for path: ${routeInfo.path}',
            );
          }
        }
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.pushAll.exception: $e\n$st');
      }
    }
  }

  /// Replace last route with new routes with push animation
  void pushReplacementAll(List<NavRouteInfo> routeInfos) {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.pushReplacementAll: No valid context found.');
        }
        return;
      }

      final navigator = Navigator.of(context);

      final currentIndex = _steps.length - 1;

      if (currentIndex > 0) {
        // Remove last existing route
        if (_steps.isNotEmpty) {
          final lastStep = _steps.last;
          if (lastStep.currentRoute.isActive) {
            navigator.removeRoute(lastStep.currentRoute);
          }
        }
        // Push new routes
        pushAll(routeInfos);
      } else {
        // Ensure remove all navigation history

        // Push first route with or without animation

        final firstRouteInfo = routeInfos.first;
        final firstRoute = _routes[firstRouteInfo.path];
        if (firstRoute == null) {
          if (_enableLogger) {
            debugPrint(
              'NavService.pushReplacementAll: Route not found for path: '
              '${firstRouteInfo.path}',
            );
          }
        } else {
          navigator.pushAndRemoveUntil(
            _buildPageRouteNoPushAnimation(
              path: firstRouteInfo.path,
              extra: NavExtra(firstRouteInfo.extra ?? {}),
              route: firstRoute,
            ),
            (route) => false,
          );
        }

        // Push remaining routes in order with animation at last
        final remainingRouteInfos = routeInfos.sublist(1);
        pushAll(remainingRouteInfos);
      }

      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.pushReplacementAll.exception: $e\n$st');
      }
    }
  }

  /// Replace all existing routes with new routes with push animation
  ///
  /// Note: If integrate with `GoRouter`, please call `removeAll()` and then
  /// use `go()` to set new routes instead of using this method.
  void replaceAll(List<NavRouteInfo> routeInfos) {
    try {
      final context = _currentContext;
      if (context == null) {
        if (_enableLogger) {
          debugPrint('NavService.replaceAll: No valid context found.');
        }
        return;
      }

      if (routeInfos.isEmpty) {
        if (_enableLogger) {
          debugPrint('NavService.replaceAll: No routeInfos provided.');
        }
        return;
      }

      final navigator = Navigator.of(context);

      final currentIndex = _steps.length - 1;

      if (currentIndex > 0) {
        // Remove all existing routes
        for (final step in List<NavStep>.from(_steps.reversed)) {
          if (step.currentRoute.isActive) {
            navigator.removeRoute(step.currentRoute);
          }
        }
        // Push new routes
        pushAll(routeInfos);
      } else {
        // handle when there is no existing _steps
        // and contains initial route

        // Push first route with or without animation
        final firstRouteInfo = routeInfos.first;
        final firstRoute = _routes[firstRouteInfo.path];
        if (firstRoute == null) {
          if (_enableLogger) {
            debugPrint(
              'NavService.replaceAll: Route not found for path: '
              '${firstRouteInfo.path}',
            );
          }
        } else {
          navigator.pushAndRemoveUntil(
            _buildPageRouteNoPushAnimation(
              path: firstRouteInfo.path,
              extra: NavExtra(firstRouteInfo.extra ?? {}),
              route: firstRoute,
            ),
            (route) => false,
          );
        }

        // Push remaining routes in order with animation at last
        final remainingRouteInfos = routeInfos.sublist(1);
        pushAll(remainingRouteInfos);
      }

      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      if (_enableLogger) {
        debugPrint('NavService.replaceAll.exception: $e\n$st');
      }
    }
  }

  // Get navigation history
  List<NavStep> get navigationHistory => List.unmodifiable(_steps);
}

class _RouteObserver extends RouteObserver<PageRoute> {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    NavService.instance._didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    NavService.instance._didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    NavService.instance._didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    NavService.instance._didRemove(
      oldRoute: route,
      previousRoute: previousRoute,
    );
  }
}

// Follow MaterialPageRoute
const Duration _kDefaultTransitionDuration = Duration(milliseconds: 300);

/// Custom MaterialPageRoute that has no push animation but keeps pop animation
class _NoTransitionMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _NoTransitionMaterialPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => _kDefaultTransitionDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // No animation when pushing (entering)
    if (animation.status == AnimationStatus.forward) {
      return child;
    }

    // Use default material transition when popping (exiting)
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
