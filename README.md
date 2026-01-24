# Advanced Nav Service

A powerful navigation service package for Flutter applications that provides advanced routing, navigation state management, and declarative navigation utilities.

Note: An alternative interface of this project is available at https://pub.dev/packages/flutter_nav

## Table of Contents

1. [Installation](#1-installation)
2. [Features](#2-features)
3. [Standalone Setup](#3-standalone-setup)
4. [Core Navigation](#4-core-navigation)
5. [Deep Linking](#5-deep-linking)
6. [Navigation Persistence](#6-navigation-persistence)
7. [GoRouter Integration](#7-gorouter-integration)
8. [Working with Extra Data](#8-working-with-extra-data)
9. [Navigation History & Debugging](#9-navigation-history--debugging)
10. [API Reference](#10-api-reference)
11. [Ultilities](#11-ultilities)

## 1. Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  advanced_nav_service: ^0.5.0
```

Then run:

```bash
flutter pub get
```

## 2. Features

- **🎯 Singleton Navigation Service**: Access navigation functionality from anywhere in your app
- **📊 Navigation History Tracking**: Keep track of navigation stack and history
- **💾 Extra Data Support**: Pass and receive data between routes with type safety
- **🔄 Advanced Route Management**: Smart navigation, replace operations, and stack manipulation
- **📝 Route Observers**: Monitor navigation events with built-in observer
- **🚀 Declarative API**: Intuitive methods for all navigation scenarios
- **🔍 Navigation Debugging**: Built-in logging and navigation history inspection
- **⚡ Performance Optimized**: Efficient route management with minimal overhead
- **🔗 Deep Linking Handling**: Complete infrastructure for handling custom URLs with app_links integration, path parameters extraction, and flexible link handlers
- **💾 Navigation Persistence**: Automatic state persistence and restoration with customizable schedules
- **🧰 Utilities**: Other navigation utilities, make navigation easier and more efficient 
## 3. Standalone Setup

### 1. Define Your Routes

```dart
import 'package:advanced_nav_service/nav_service.dart';

final routes = [
  NavRoute(
    path: '/home',
    builder: (context, state) => HomeScreen(state: state),
  ),
  NavRoute(
    path: '/profile',
    builder: (context, state) => ProfileScreen(state: state),
  ),
  NavRoute(
    path: '/settings',
    builder: (context, state) => SettingsScreen(state: state),
  ),
];
```

### 2. Initialize NavService

```dart
void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  
  NavService.instance.init(
    NavServiceConfig(
      routes: routes,
      navigatorKey: navigatorKey,
      enableLogger: true,
    ),
  );
  
  runApp(MyApp(navigatorKey: navigatorKey));
}
```

### 3. Setup Your App

```dart
class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [NavService.instance.routeObserver],
      home: const SplashScreen(),
    );
  }
}
```

### 4. Handle App Launch

Move initialization logic outside of widgets and use the `launched()` method to set initial routes:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final navigatorKey = GlobalKey<NavigatorState>();
  
  NavService.instance.init(
    NavServiceConfig(
      routes: routes,
      navigatorKey: navigatorKey,
      enableLogger: true,
    ),
  );
  
  runApp(MyApp(navigatorKey: navigatorKey));
  
  // Handle initial logic after app starts
  Future.delayed(const Duration(seconds: 2), () async {
    // Check authentication, deep links, etc.
    final bool isAuthenticated = await checkAuth();
    
    if (isAuthenticated) {
      NavService.instance.launched([NavRouteInfo(path: '/home')]);
    } else {
      NavService.instance.launched([NavRouteInfo(path: '/login')]);
    }
  });
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

## 4. Core Navigation

### Basic Navigation

```dart
// Push a new route
NavService.instance.push('/profile');

// Push with extra data
NavService.instance.push('/profile', extra: {
  'userId': 123,
  'name': 'John Doe',
});

// Pop current route
NavService.instance.pop();

// Pop with result data
NavService.instance.pop({'result': 'success'});

// Check if can pop
if (NavService.instance.canPop()) {
  NavService.instance.pop();
}

// Try to pop if possible and get whether pop occurred
if (NavService.instance.maybePop()) {
  // pop was performed
} else {
  // nothing to pop
}
```

### Smart Navigation

```dart
// Navigate intelligently - if route exists in stack, pop to it; otherwise push
NavService.instance.navigate('/home');

// Force push even if route exists in history
NavService.instance.navigate('/home', forcePush: true);
```

### Replace Operations

```dart
// Replace current route with push animation
NavService.instance.pushReplacement('/settings');

// Replace current route without animation
NavService.instance.replace('/settings');
```

### Stack Management

```dart
// Push and remove all previous routes
NavService.instance.pushAndRemoveUntil('/home', (route) => false);

// Pop until specific condition
NavService.instance.popUntil((route) => route.settings.name == '/home');

// Pop until specific path
NavService.instance.popUntilPath('/home');

// Pop all routes
NavService.instance.popAll();

// Remove all routes without animation
// Caution: just use this method when switch to gorouter
NavService.instance.removeAll();
```

### Bulk Operations

```dart
// Push multiple routes at once
NavService.instance.pushAll([
  NavRouteInfo(path: '/home'),
  NavRouteInfo(path: '/profile', extra: {'userId': 123}),
  NavRouteInfo(path: '/settings'),
]);

// Replace all routes with new stack
NavService.instance.replaceAll([
  NavRouteInfo(path: '/home'),
  NavRouteInfo(path: '/dashboard'),
]);

// Replace last route with multiple routes
NavService.instance.pushReplacementAll([
  NavRouteInfo(path: '/profile'),
  NavRouteInfo(path: '/edit'),
]);
```

## 5. Deep Linking

### Define Link Handlers

Create custom link handlers by extending `NavLinkHandler`:

```dart
import 'package:advanced_nav_service/nav_service.dart';

class ProfileLinkHandler extends NavLinkHandler {
  @override
  List<String> get redirectPaths => [
    '/profile',
    '/profile/:id',
    '/user/:userId',
  ];

  @override
  void onRedirect(BuildContext context, NavLinkResult result) {
    // Handle the deep link navigation
    NavService.instance.navigate('/profile', extra: {
      ...result.pathParameters,  // e.g., {'id': '123'}
      ...result.queryParameters, // e.g., {'tab': 'settings'}
    });
  }
}

class SettingsLinkHandler extends NavLinkHandler {
  @override
  List<String> get redirectPaths => [
    '/settings',
    '/settings/:tab',
  ];

  @override
  void onRedirect(BuildContext context, NavLinkResult result) {
    NavService.instance.navigate('/settings', extra: {
      ...result.pathParameters,
      ...result.queryParameters,
    });
  }
}
```

### Setup with app_links

1. **Install dependencies**:

```yaml
dependencies:
  advanced_nav_service: ^0.5.0
  app_links: ^latest_version
```

2. **Configure NavService with deep linking**:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();

  NavService.instance.init(
    NavServiceConfig(
      navigatorKey: navigatorKey,
      routes: routes,
      enableLogger: true,
      // Deep linking configuration
      linkPrefixes: [
        'myapp://',                    // Custom scheme
        'https://myapp.com/',          // Universal links
        'https://www.myapp.com/',      // Alternative domain
      ],
      linkHandlers: [
        ProfileLinkHandler(),
        SettingsLinkHandler(),
      ],
    ),
  );

  // Start the app first so the navigator and NavService are available.
  runApp(MyApp(navigatorKey: navigatorKey));

  // Initialize app_links integration after the first frame.
  // This ensures `NavService.instance.openUrl(...)` runs only when the
  // navigator and route observers are ready.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeAppLinks();
  });
}

Future<void> _initializeAppLinks() async {
  final appLinks = AppLinks();

  // Handle initial link when app is launched
  final initialLink = await appLinks.getInitialLink();
  if (initialLink != null) {
    // Safe to open URL now that the app has been started
    NavService.instance.openUrl(initialLink.toString());
  }

  // Handle incoming links when app is running
  appLinks.uriLinkStream.listen((Uri uri) {
    NavService.instance.openUrl(uri.toString());
  });
}

// NOTE: If you handle initial logic in main() (see "Handle App Launch" above),
// coordinate the initial link handling with your launch logic to avoid
// duplicate navigation.
```

### Usage

```dart
// Open URLs programmatically
NavService.instance.openUrl('myapp://profile/123?tab=settings');
NavService.instance.openUrl('https://myapp.com/profile/456?source=share');
```

### URL Pattern Features

- **Static paths**: `/profile`, `/settings`
- **Dynamic parameters**: `/user/:userId`, `/product/:id` 
- **Query parameters**: Automatically parsed and available
- **Custom schemes**: `myapp://`, `yourapp://`
- **Universal links**: `https://domain.com/`

## 6. Navigation Persistence

NavService provides built-in support for persisting and restoring navigation state across app restarts.

### Setup Persistence

First, add a storage dependency (example uses SharedPreferences):

```yaml
dependencies:
  advanced_nav_service: ^0.5.0
  shared_preferences: ^latest_version
```

Configure persistence with SharedPreferences or any storage mechanism:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advanced_nav_service/nav_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final navigatorKey = GlobalKey<NavigatorState>();
  const restorationId = 'app_restoration_id';
  
  NavService.instance.init(
    NavServiceConfig(
      navigatorKey: navigatorKey,
      routes: routes,
      enableLogger: true,
      persistence: NavPagePersistence(
        onPersist: (routes) async {
          final pref = await SharedPreferences.getInstance();
          await pref.setString(restorationId, jsonEncode(routes));
        },
        onRestore: () async {
          final pref = await SharedPreferences.getInstance();
          final jsonString = pref.getString(restorationId);
          if (jsonString != null) {
            final List<dynamic> data = jsonDecode(jsonString);
            return List<Map<String, dynamic>>.from(data);
          }
          return [];
        },
        enableSchedule: true,
        schedule: const NavPagePersistenceSchedule(immediate: true),
      ),
    ),
  );
  
  runApp(MyApp(navigatorKey: navigatorKey));
  
  // Launch app with restoration or default routes
  Future.delayed(const Duration(seconds: 2), () {
    NavService.instance.launched([NavRouteInfo(path: '/home')]);
  });
}
```

### Persistence Configuration

**NavPagePersistence** properties:
- `onPersist` - Callback to save navigation state (receives List<Map<String, dynamic>>)
- `onRestore` - Callback to load navigation state (returns List<Map<String, dynamic>>)
- `enableSchedule` - Enable automatic persistence on navigation events
- `schedule` - Configure when to persist (immediate or interval-based)

**NavPagePersistenceSchedule** options:
- `immediate: true` - Save state immediately on every navigation change
- `interval: Duration(seconds: 30)` - Save state at regular intervals

### Using launched() Method

Call `launched()` after app initialization to restore previous state or set default routes:

```dart
// Restore previous state if available, otherwise use default routes
NavService.instance.launched([NavRouteInfo(path: '/home')]);

// If persisted state exists, it will be restored
// If no persisted state, the provided routes will be used
```

### Manual Persistence Control

```dart
// Manually persist current navigation state
await NavService.instance.persist();

// Manually restore navigation state
await NavService.instance.restore();
```

### Best Practices

- **Serializable Data Only**: Only pass JSON-serializable data in route extras for persistence
- **Coordinate with Auth**: Check authentication state before restoring routes
- **Error Handling**: Implement fallback logic in onRestore if data is corrupted
- **Performance**: Use `immediate: true` for critical apps or `interval` for less frequent saves

## 7. GoRouter Integration

### Setup

1. **Install dependencies**:

```yaml
dependencies:
  advanced_nav_service: ^0.5.0
  go_router: ^latest_version
```

2. **Configure both systems**:

```dart
import 'package:go_router/go_router.dart';
import 'package:advanced_nav_service/nav_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Configure GoRouter
final GoRouter goRouter = GoRouter(
  navigatorKey: navigatorKey,
  observers: [NavService.instance.routeObserver],
  routes: [
    // ... go router routes
  ],
);

void main() {
  // Configure NavService with the same navigator key
  NavService.instance.init(
    NavServiceConfig(
      routes: navServiceRoutes,
      navigatorKey: navigatorKey,
      enableLogger: true,
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: goRouter,
    );
  }
}
```

### Usage with removeAll()

When switching from NavService to GoRouter navigation, call `removeAll()` first:

```dart
ElevatedButton(
  onPressed: () {
    // Clear NavService stack before using GoRouter
    NavService.instance.removeAll();
    // Then use GoRouter navigation
    context.go('/go-profile/123');
  },
  child: Text('Switch to GoRouter'),
),
```

### Best Practices

- **Call `removeAll()` before `context.go()`**: Ensures NavService doesn't interfere with GoRouter
- **Use consistent navigator key**: Both systems should share the same `GlobalKey<NavigatorState>`
- **Include NavService route observer**: Add to GoRouter's observers for complete tracking
- **Separate concerns by use case**:
  - **Use GoRouter for**: Static routes, initial redirects, resetting all routes
  - **Use NavService for**: Dynamic routes, push notifications, unpredictable navigation flows

## 8. Working with Extra Data

### Passing Data

```dart
NavService.instance.push('/profile', extra: {
  'userId': 123,
  'name': 'John Doe',
  'email': 'john@example.com',
  'preferences': {
    'theme': 'dark',
    'notifications': true,
  },
});
```

### Receiving Data in Screens

```dart
class ProfileScreen extends StatelessWidget {
  final NavState state;
  
  const ProfileScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Access extra data
    final extraData = state.extra?.data ?? {};
    final userId = extraData['userId'];
    final name = extraData['name'];
    
    return Scaffold(
      appBar: AppBar(title: Text('Profile: $name')),
      body: Column(
        children: [
          Text('User ID: $userId'),
          Text('Name: $name'),
          // ... rest of your UI
        ],
      ),
    );
  }
}
```

## 9. Navigation History & Debugging

### Accessing Navigation History

```dart
// Get current navigation stack
List<NavStep> history = NavService.instance.navigationHistory;

// Get current location path
String currentLocation = NavService.instance.joinedLocation;

// Print navigation history
for (int i = 0; i < history.length; i++) {
  print('${i + 1}. ${history[i].currentState.path}');
}
```

### Navigation Observer

The package includes a built-in route observer that automatically tracks navigation events:

```dart
MaterialApp(
  navigatorObservers: [NavService.instance.routeObserver],
  // ...
)
```

## 10. API Reference

### NavService

Main navigation service singleton.

#### Configuration Methods
- `init(NavServiceConfig config)` - Initialize the service with routes and configuration

#### Navigation Methods
- `push<T>(String path, {Map<String, dynamic>? extra})` - Push new route
- `pop<T>([T? result])` - Pop current route
- `navigate(String path, {Map<String, dynamic>? extra, bool forcePush = false})` - Intelligent navigation
- `canPop()` - Check if can pop

#### Replace Operations
- `pushReplacement(String path, {Map<String, dynamic>? extra})` - Replace with animation
- `replace(String path, {Map<String, dynamic>? extra})` - Replace without animation

#### Stack Management
- `pushAndRemoveUntil(String path, RoutePredicate predicate, {Map<String, dynamic>? extra})` - Push and remove until condition
- `popUntilPath(String path)` - Pop until specific path
- `removeAll()` - Remove all routes without animation

#### Bulk Operations
- `pushAll(List<NavRouteInfo> routeInfos)` - Push multiple routes
- `replaceAll(List<NavRouteInfo> routeInfos)` - Replace all routes

#### Deep Linking
- `openUrl(String url)` - Handle deep links via registered link handlers

#### Persistence
- `launched(List<NavRouteInfo> routes)` - Launch app with restored or default routes
- `persist()` - Manually persist current navigation state
- `restore()` - Manually restore navigation state

#### Properties
- `navigationHistory` - List of navigation steps
- `joinedLocation` - Current location path
- `routeObserver` - Built-in route observer

### Core Classes

- **NavRoute** - Defines a route with path and builder function
- **NavState** - Contains route path and extra data for each navigation state
- **NavExtra** - Container for extra data passed between routes
- **NavStep** - Represents a step in navigation history
- **NavRouteInfo** - Simple route information for bulk operations
- **NavServiceConfig** - Configuration object for initializing NavService
- **NavLinkHandler** - Abstract class for defining deep link handlers (onRedirect requires BuildContext)
- **NavLinkResult** - Contains matched route path, path parameters, and query parameters
- **NavPagePersistence** - Configuration for navigation state persistence
- **NavPagePersistenceSchedule** - Schedule configuration for persistence timing

## 11. Ultilities

### PageAware

`PageAware` is a small utility widget that integrates with the package's
built-in `RouteObserver` to provide easy hooks for common route lifecycle
events: initialization, disposal, appearance/disappearance, and a callback
after the first frame (optionally waiting for the route transition to
complete).

Example usage:

```dart
PageAware(
  onInit: () => debugPrint('init'),
  onAfterFirstFrame: () => debugPrint('after first frame'),
  onAppear: () => debugPrint('appeared'),
  onDisappear: () => debugPrint('disappeared'),
  onDispose: () => debugPrint('disposed'),
  waitForTransition: true, // optionally wait for route animation
  child: Scaffold(...),
)
```

Notes:
- **onInit / onDispose**: called during the widget's `initState` and `dispose`.
- **onAfterFirstFrame**: called after the first frame; if `waitForTransition`
  is true, the callback waits until the route's push animation completes.
- **onAppear / onDisappear**: called when this route becomes visible or hidden
  due to navigation events (uses `RouteAware` hooks).

`PageAware` is convenient for analytics, lazy-loading content when a screen
becomes visible, or coordinating animations that depend on route transitions.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the BSD-3-Clause License - see the LICENSE file for details.
