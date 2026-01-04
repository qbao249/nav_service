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

      group('NavAware', () {
        testWidgets('calls lifecycle callbacks', (WidgetTester tester) async {
          final navigatorKey = GlobalKey<NavigatorState>();
          final navService = NavService.instance;

          var initCalled = false;
          var afterCalled = false;
          var disposeCalled = false;

          final routes = [
            NavRoute(
              path: '/other',
              builder: (context, state) => const Scaffold(body: Text('Other')),
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
              home: PageAware(
                onInit: () => initCalled = true,
                onAfterFirstFrame: () => afterCalled = true,
                onDispose: () => disposeCalled = true,
                child: const Scaffold(body: Text('Home')),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(initCalled, isTrue);
          expect(afterCalled, isTrue);
          expect(disposeCalled, isFalse);

          // Replace the current route to trigger dispose on the Home route.
          navService.replace('/other');
          await tester.pumpAndSettle();

          expect(disposeCalled, isTrue);
        });
      });

      // Test helper class
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
      expect(extra.data, equals({'key1': 'value1', 'key2': 42}));
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

  group('Deep Linking', () {
    late TestNavLinkHandler testHandler;
    late NavService navService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      testHandler = TestNavLinkHandler();
      navService = NavService.instance;
      navigatorKey = GlobalKey<NavigatorState>();
    });

    test('should initialize with link prefixes and handlers', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      final config = NavServiceConfig(
        routes: routes,
        navigatorKey: navigatorKey,
        enableLogger: false,
        linkPrefixes: ['myapp://', 'https://myapp.com/'],
        linkHandlers: [testHandler],
      );

      expect(() => navService.init(config), returnsNormally);
    });

    test('should handle URL with scheme prefix', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          linkPrefixes: ['myapp://'],
          linkHandlers: [testHandler],
        ),
      );

      navService.openUrl('myapp://product/123?category=electronics');

      expect(testHandler.lastResult?.matchedRoutePath, equals('/product/:id'));
      expect(testHandler.lastResult?.pathParameters, equals({'id': '123'}));
      expect(
        testHandler.lastResult?.queryParameters,
        equals({'category': 'electronics'}),
      );
    });

    test('should handle URL with domain prefix', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          linkPrefixes: ['https://myapp.com'],
          linkHandlers: [testHandler],
        ),
      );

      navService.openUrl('https://myapp.com/user/profile?tab=settings');

      expect(testHandler.lastResult?.matchedRoutePath, equals('/user/profile'));
      expect(testHandler.lastResult?.pathParameters, isEmpty);
      expect(
        testHandler.lastResult?.queryParameters,
        equals({'tab': 'settings'}),
      );
    });

    test('should extract path parameters correctly', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          linkPrefixes: ['myapp://'],
          linkHandlers: [testHandler],
        ),
      );

      navService.openUrl('myapp://product/abc123/review/456');

      expect(
        testHandler.lastResult?.matchedRoutePath,
        equals('/product/:productId/review/:reviewId'),
      );
      expect(
        testHandler.lastResult?.pathParameters,
        equals({'productId': 'abc123', 'reviewId': '456'}),
      );
    });

    test('should throw error for duplicate redirect paths', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      final duplicateHandler = TestNavLinkHandler();

      expect(
        () => navService.init(
          NavServiceConfig(
            routes: routes,
            navigatorKey: navigatorKey,
            enableLogger: false,
            linkPrefixes: ['myapp://'],
            linkHandlers: [testHandler, duplicateHandler],
          ),
        ),
        throwsException,
      );
    });

    test('should not handle URL without matching prefix', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          linkPrefixes: ['myapp://'],
          linkHandlers: [testHandler],
        ),
      );

      testHandler.clearResults();
      navService.openUrl('https://other.com/product/123');

      expect(testHandler.lastResult, isNull);
    });

    test('NavLinkResult should contain correct data', () {
      final result = NavLinkResult(
        matchedRoutePath: '/product/:id',
        pathParameters: {'id': '123'},
        queryParameters: {'tab': 'details'},
      );

      expect(result.matchedRoutePath, equals('/product/:id'));
      expect(result.pathParameters, equals({'id': '123'}));
      expect(result.queryParameters, equals({'tab': 'details'}));
    });
  });
}

// Test helper class
class TestNavLinkHandler extends NavLinkHandler {
  NavLinkResult? lastResult;

  @override
  List<String> get redirectPaths => [
    '/product/:id',
    '/user/profile',
    '/product/:productId/review/:reviewId',
  ];

  @override
  void onRedirect(NavLinkResult result) {
    lastResult = result;
  }

  void clearResults() {
    lastResult = null;
  }
}
