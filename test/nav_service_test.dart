import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_nav_service/nav_service.dart';

void main() {
  group('NavService', () {
    late NavService navService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navService = NavService.instance;
      navigatorKey = GlobalKey<NavigatorState>();
    });

    test('should be a singleton', () {
      final instance1 = NavService();
      final instance2 = NavService.instance;
      expect(instance1, same(instance2));
    });

    test('should initialize with configuration', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
        NavRoute(path: '/settings', builder: (context, state) => Container()),
      ];

      final config = NavServiceConfig(
        routes: routes,
        navigatorKey: navigatorKey,
        enableLogger: false,
      );

      navService.init(config);

      expect(navService.routeObserver, isA<NavigatorObserver>());
      expect(navService.navigationHistory, isEmpty);
    });

    testWidgets('should navigate between routes', (WidgetTester tester) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        NavRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => navService.push('/home'),
                        child: const Text('Go Home'),
                      ),
                      ElevatedButton(
                        onPressed: () => navService.push('/settings'),
                        child: const Text('Go Settings'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      // Test navigation to home
      await tester.tap(find.text('Go Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Test navigation to settings
      await tester.tap(find.text('Go Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // Verify navigation history
      expect(navService.navigationHistory.length, equals(2));
      expect(
        navService.navigationHistory.last.currentState.path,
        equals('/settings'),
      );
    });

    testWidgets('should handle extra data', (WidgetTester tester) async {
      String? receivedData;

      final routes = [
        NavRoute(
          path: '/test',
          builder: (context, state) {
            receivedData = state.extra?.data['message'];
            return Scaffold(body: Text('Test: $receivedData'));
          },
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed:
                        () => navService.push(
                          '/test',
                          extra: {'message': 'Hello World'},
                        ),
                    child: const Text('Navigate'),
                  ),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(receivedData, equals('Hello World'));
      expect(find.text('Test: Hello World'), findsOneWidget);
    });

    testWidgets('should handle pop operations', (WidgetTester tester) async {
      final routes = [
        NavRoute(
          path: '/first',
          builder: (context, state) => const Scaffold(body: Text('First')),
        ),
        NavRoute(
          path: '/second',
          builder: (context, state) => const Scaffold(body: Text('Second')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => navService.push('/first'),
                        child: const Text('Push First'),
                      ),
                      ElevatedButton(
                        onPressed: () => navService.push('/second'),
                        child: const Text('Push Second'),
                      ),
                      ElevatedButton(
                        onPressed: () => navService.pop(),
                        child: const Text('Pop'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      // Push first route
      await tester.tap(find.text('Push First'));
      await tester.pumpAndSettle();
      expect(navService.navigationHistory.length, equals(1));

      // Push second route
      await tester.tap(find.text('Push Second'));
      await tester.pumpAndSettle();
      expect(navService.navigationHistory.length, equals(2));

      // Pop
      expect(navService.canPop(), isTrue);
      await tester.tap(find.text('Pop'));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(navService.navigationHistory.length, equals(1));
    });

    testWidgets('should handle replace operations', (
      WidgetTester tester,
    ) async {
      final routes = [
        NavRoute(
          path: '/original',
          builder: (context, state) => const Scaffold(body: Text('Original')),
        ),
        NavRoute(
          path: '/replacement',
          builder:
              (context, state) => const Scaffold(body: Text('Replacement')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => navService.push('/original'),
                        child: const Text('Push Original'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => navService.pushReplacement('/replacement'),
                        child: const Text('Replace'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      // Push original route
      await tester.tap(find.text('Push Original'));
      await tester.pumpAndSettle();
      expect(find.text('Original'), findsOneWidget);

      // Replace with new route
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('NavExtra', () {
    test('should store and retrieve data', () {
      final extra = NavExtra({'key1': 'value1', 'key2': 42});

      expect(extra.data['key1'], equals('value1'));
      expect(extra.data['key2'], equals(42));
      expect(extra.toJson(), equals({'key1': 'value1', 'key2': 42}));
    });
  });

  group('NavState', () {
    test('should create NavState from route with NavExtra', () {
      final extra = NavExtra({'test': 'data'});
      final route = MaterialPageRoute(
        settings: RouteSettings(name: '/test', arguments: extra),
        builder: (context) => Container(),
      );

      final state = NavState.fromRoute(route);

      expect(state, isNotNull);
      expect(state!.path, equals('/test'));
      expect(state.extra, equals(extra));
    });

    test('should return null for route without NavExtra', () {
      final route = MaterialPageRoute(
        settings: const RouteSettings(
          name: '/test',
          arguments: 'regular string',
        ),
        builder: (context) => Container(),
      );

      final state = NavState.fromRoute(route);
      expect(state, isNull);
    });
  });

  group('NavRouteInfo', () {
    test('should create route info with path and extra data', () {
      final routeInfo = NavRouteInfo(path: '/test', extra: {'data': 'value'});

      expect(routeInfo.path, equals('/test'));
      expect(routeInfo.extra, equals({'data': 'value'}));
    });

    test('should create route info with path only', () {
      final routeInfo = NavRouteInfo(path: '/test');

      expect(routeInfo.path, equals('/test'));
      expect(routeInfo.extra, isNull);
    });
  });
}
