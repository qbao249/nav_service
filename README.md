# Advanced Nav Service

A powerful navigation service package for Flutter applications that provides advanced routing, navigation state management, and declarative navigation utilities.

## Table of Contents

1. [Installation](#1-installation)
2. [Features](#2-features)
3. [Standalone Setup](#3-standalone-setup)
4. [Core Navigation](#4-core-navigation)
5. [Deep Linking](#5-deep-linking)
6. [GoRouter Integration](#6-gorouter-integration)
7. [Working with Extra Data](#7-working-with-extra-data)
8. [Navigation History & Debugging](#8-navigation-history--debugging)
9. [API Reference](#9-api-reference)

## 1. Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  advanced_nav_service: ^0.3.2
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
      home: const LaunchScreen(),
    );
  }
}
```

### 4. LaunchScreen (handle initial logic)

Use a dedicated LaunchScreen that runs initial checks in initState (authentication, initial push notification, onboarding, etc.) and then redirects with NavService. Keep logic in a single async method called from initState to avoid making initState async.

```dart
import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    // Defer async work to a helper; run after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialLogic();
    });
  }

  Future<void> _handleInitialLogic() async {
    // 1) Check if the user is authenticated
    final bool isAuthenticated = await _checkAuth();
    // 2) Check if app was opened from a push notification / deep link
    // Replace with your push/deep-link SDK fetch (e.g., FirebaseMessaging.getInitialMessage())
    final Uri? initialDeepLink = await _getInitialDeepLink();

    // Decide target route
    if (initialDeepLink != null) {
      // Convert deep link to a route or call NavService.openUrl
      NavService.instance.openUrl(initialDeepLink.toString());
      return;
    }

    if (!isAuthenticated) {
      // Redirect to login or onboarding
      NavService.instance.replaceAll([
        NavRouteInfo(path: '/login', extra: {}), 
        // ...
      ]);
      return;
    }

    // Default: go to home
    NavService.instance.pushReplacement('/home');
  }

  // Dummy implementations - replace with real logic
  Future<bool> _checkAuth() async {
    // e.g., await authService.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 200));
    return false; // change to actual auth result
  }

  Future<Uri?> _getInitialDeepLink() async {
    // e.g., final message = await FirebaseMessaging.instance.getInitialMessage();
    // if (message != null) parse message.data or message.link
    await Future.delayed(const Duration(milliseconds: 50));
    return null; // return a Uri if the app was opened via push/deep-link
  }

  @override
  Widget build(BuildContext context) {
    // Can define as a plash screen
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
  void onRedirect(NavLinkResult result) {
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
  void onRedirect(NavLinkResult result) {
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
  advanced_nav_service: ^0.3.0
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

// NOTE: If you use a `LaunchScreen` that already handles initial logic
// (see "LaunchScreen (handle initial logic)" above), prefer handling the
// initial deep link inside that screen's `_handleInitialLogic()` to avoid
// duplicate navigation. Use either `LaunchScreen` or `_initializeAppLinks()`
// for initial link handling — not both.
```
See [LaunchScreen](#4-launchscreen-handle-initial-logic) for more details.

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

## 6. GoRouter Integration

### Setup

1. **Install dependencies**:

```yaml
dependencies:
  advanced_nav_service: ^0.3.0
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

## 7. Working with Extra Data

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

## 8. Navigation History & Debugging

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

## 9. API Reference

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
- **NavLinkHandler** - Abstract class for defining deep link handlers
- **NavLinkResult** - Contains matched route path, path parameters, and query parameters

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
