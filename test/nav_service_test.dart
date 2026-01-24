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

      // Test helper class
      expect(navService.navigationHistory, isEmpty);
    });
  });

  group('PageAware', () {
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

  group('NavService Navigation', () {
    late NavService navService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navService = NavService.instance;
      navigatorKey = GlobalKey<NavigatorState>();
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
          home: const Scaffold(body: Text('Initial')),
        ),
      );

      // Test navigation to home
      navService.push('/home');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Test navigation to settings
      navService.push('/settings');
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
          home: const Scaffold(body: Text('Initial')),
        ),
      );

      // Push first route
      navService.push('/first');
      await tester.pumpAndSettle();
      expect(navService.navigationHistory.length, equals(1));

      // Push second route
      navService.push('/second');
      await tester.pumpAndSettle();
      expect(navService.navigationHistory.length, equals(2));

      // Pop
      expect(navService.canPop(), isTrue);
      navService.pop();
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
          home: const Scaffold(body: Text('Initial')),
        ),
      );

      // Push original route
      navService.push('/original');
      await tester.pumpAndSettle();
      expect(find.text('Original'), findsOneWidget);

      // Replace with new route
      navService.pushReplacement('/replacement');
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

    testWidgets('should handle URL with scheme prefix', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Home')),
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

    testWidgets('should handle URL with domain prefix', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Home')),
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

    testWidgets('should extract path parameters correctly', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Home')),
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

  group('Navigation Persistence', () {
    late NavService navService;
    late GlobalKey<NavigatorState> navigatorKey;
    List<Map<String, dynamic>>? persistedData;

    setUp(() {
      navService = NavService.instance;
      navigatorKey = GlobalKey<NavigatorState>();
      persistedData = null;
    });

    testWidgets('should persist navigation state', (WidgetTester tester) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        NavRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => [],
            enableSchedule: true,
            schedule: const NavPagePersistenceSchedule(immediate: true),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Launch with initial route
      navService.launched([NavRouteInfo(path: '/home')]);
      await tester.pumpAndSettle();

      // Verify persistence was called
      expect(persistedData, isNotNull);
      expect(persistedData!.length, equals(1));
      expect(persistedData![0]['path'], equals('/home'));
    });

    testWidgets('should restore navigation state', (WidgetTester tester) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        NavRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        NavRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ];

      // Mock persisted data
      final mockPersistedData = [
        {'path': '/home'},
        {
          'path': '/profile',
          'extra': {'userId': 123},
        },
        {'path': '/settings'},
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => mockPersistedData,
            enableSchedule: true,
            schedule: const NavPagePersistenceSchedule(immediate: true),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Launch should restore persisted routes
      navService.launched([NavRouteInfo(path: '/default')]);
      await tester.pumpAndSettle();

      // Verify restored routes
      expect(navService.navigationHistory.length, equals(3));
      expect(navService.navigationHistory[0].path, equals('/home'));
      expect(navService.navigationHistory[1].path, equals('/profile'));
      expect(navService.navigationHistory[2].path, equals('/settings'));
    });

    testWidgets('should use default routes when no persisted data', (
      WidgetTester tester,
    ) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        NavRoute(
          path: '/default',
          builder: (context, state) => const Scaffold(body: Text('Default')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => [], // No persisted data
            enableSchedule: true,
            schedule: const NavPagePersistenceSchedule(immediate: true),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Launch with default route
      navService.launched([NavRouteInfo(path: '/default')]);
      await tester.pumpAndSettle();

      // Verify default route is used
      expect(navService.navigationHistory.length, equals(1));
      expect(navService.navigationHistory[0].path, equals('/default'));
    });

    testWidgets('should persist with extra data', (WidgetTester tester) async {
      final routes = [
        NavRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => [],
            enableSchedule: true,
            schedule: const NavPagePersistenceSchedule(immediate: true),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Launch with extra data
      navService.launched([
        NavRouteInfo(
          path: '/profile',
          extra: {'userId': 456, 'name': 'John Doe'},
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify persisted data includes extra
      expect(persistedData, isNotNull);
      expect(persistedData!.length, equals(1));
      expect(persistedData![0]['path'], equals('/profile'));
      expect(persistedData![0]['extra'], isNotNull);
      expect(persistedData![0]['extra']['userId'], equals(456));
      expect(persistedData![0]['extra']['name'], equals('John Doe'));
    });

    testWidgets('should persist on navigation events with immediate schedule', (
      WidgetTester tester,
    ) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        NavRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
      ];

      int persistCallCount = 0;

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistCallCount++;
              persistedData = data;
            },
            onRestore: () async => [],
            enableSchedule: true,
            schedule: const NavPagePersistenceSchedule(immediate: true),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Launch
      navService.launched([NavRouteInfo(path: '/home')]);
      await tester.pumpAndSettle();
      final launchCallCount = persistCallCount;

      // Push another route
      navService.push('/profile');
      await tester.pumpAndSettle();

      // Verify persistence was called again
      expect(persistCallCount, greaterThan(launchCallCount));
      expect(persistedData!.length, equals(2));
    });

    testWidgets('should not persist when schedule is disabled', (
      WidgetTester tester,
    ) async {
      final routes = [
        NavRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ];

      int persistCallCount = 0;

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistCallCount++;
              persistedData = data;
            },
            onRestore: () async => [],
            enableSchedule: false, // Disabled
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [navService.routeObserver],
          home: const Scaffold(body: Text('Root')),
        ),
      );

      // Push route
      navService.push('/home');
      await tester.pumpAndSettle();

      // Verify persistence was not called automatically
      expect(persistCallCount, equals(0));
    });

    test('should manually persist navigation state', () async {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => [],
          ),
        ),
      );

      // Manually call persist
      await navService.persist();

      // Verify onPersist was called
      expect(persistedData, isNotNull);
    });

    test('should handle invalid persisted data gracefully', () async {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
        NavRoute(path: '/default', builder: (context, state) => Container()),
      ];

      // Invalid persisted data
      final invalidData = [
        {'invalid': 'data'},
        {'path': null},
        {'path': 123}, // Non-string path
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => invalidData,
            enableSchedule: true,
          ),
        ),
      );

      // Should not throw, but return empty or handle gracefully
      expect(
        () => navService.launched([NavRouteInfo(path: '/default')]),
        returnsNormally,
      );
    });

    test('should validate serializable data before persisting', () {
      final routes = [
        NavRoute(path: '/home', builder: (context, state) => Container()),
      ];

      navService.init(
        NavServiceConfig(
          routes: routes,
          navigatorKey: navigatorKey,
          enableLogger: false,
          persistence: NavPagePersistence(
            onPersist: (data) async {
              persistedData = data;
            },
            onRestore: () async => [],
          ),
        ),
      );

      // Test persistBase with serializable data
      final result = navService.persistBase();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('NavPagePersistence configuration', () {
      final persistence = NavPagePersistence(
        onPersist: (data) async {},
        onRestore: () async => [],
        enableSchedule: true,
        schedule: const NavPagePersistenceSchedule(
          immediate: true,
          interval: Duration(seconds: 30),
        ),
      );

      expect(persistence.enableSchedule, isTrue);
      expect(persistence.schedule?.immediate, isTrue);
      expect(
        persistence.schedule?.interval,
        equals(const Duration(seconds: 30)),
      );
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
  void onRedirect(BuildContext context, NavLinkResult result) {
    lastResult = result;
  }

  void clearResults() {
    lastResult = null;
  }
}
