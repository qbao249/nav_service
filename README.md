# Advanced Nav Service

A powerful and comprehensive navigation service package for Flutter applications that provides advanced routing, navigation state management, and declarative navigation utilities.

## Features

- **🎯 Singleton Navigation Service**: Access navigation functionality from anywhere in your app
- **📊 Navigation History Tracking**: Keep track of navigation stack and history
- **💾 Extra Data Support**: Pass and receive data between routes with type safety
- **🔄 Advanced Route Management**: Smart navigation, replace operations, and stack manipulation
- **📝 Route Observers**: Monitor navigation events with built-in observer
- **🚀 Declarative API**: Intuitive methods for all navigation scenarios
- **🔍 Navigation Debugging**: Built-in logging and navigation history inspection
- **⚡ Performance Optimized**: Efficient route management with minimal overhead

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  advanced_nav_service: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Setup

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
      enableLogger: true, // Enable navigation logging
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

## Core Navigation Methods

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

## Working with Extra Data

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

## Navigation History & Debugging

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

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:nav_service/nav_service.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  
  NavService.instance.init(
    NavServiceConfig(
      routes: [
        NavRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        NavRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(state: state),
        ),
      ],
      navigatorKey: navigatorKey,
      enableLogger: true,
    ),
  );
  
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [NavService.instance.routeObserver],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                NavService.instance.push('/profile', extra: {
                  'userId': 123,
                  'name': 'John Doe',
                });
              },
              child: const Text('Go to Profile'),
            ),
            ElevatedButton(
              onPressed: () {
                final history = NavService.instance.navigationHistory;
                print('Navigation history: ${history.length} items');
              },
              child: const Text('Print Navigation History'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final NavState state;
  
  const ProfileScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final extra = state.extra?.data ?? {};
    
    return Scaffold(
      appBar: AppBar(title: Text('Profile: ${extra['name']}')),
      body: Center(
        child: Column(
          children: [
            Text('User ID: ${extra['userId']}'),
            Text('Name: ${extra['name']}'),
            ElevatedButton(
              onPressed: () => NavService.instance.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### NavService

Main navigation service singleton.

#### Configuration Methods
- `init(NavServiceConfig config)` - Initialize the service with routes and configuration

#### Navigation Methods
- `push<T>(String path, {Map<String, dynamic>? extra})` - Push new route
- `pop<T>([T? result])` - Pop current route
- `popUntil(RoutePredicate predicate)` - Pop until condition
- `popUntilPath(String path)` - Pop until specific path
- `canPop()` - Check if can pop
- `maybePop<T>([T? result])` - Pop if possible

#### Smart Navigation
- `navigate(String path, {Map<String, dynamic>? extra, bool forcePush = false})` - Intelligent navigation

#### Replace Operations
- `pushReplacement(String path, {Map<String, dynamic>? extra})` - Replace with animation
- `replace(String path, {Map<String, dynamic>? extra})` - Replace without animation

#### Stack Management
- `pushAndRemoveUntil(String path, RoutePredicate predicate, {Map<String, dynamic>? extra})` - Push and remove until condition
- `popAll()` - Pop all routes with animation
- `removeAll()` - Remove all routes without animation

#### Bulk Operations
- `pushAll(List<NavRouteInfo> routeInfos)` - Push multiple routes
- `replaceAll(List<NavRouteInfo> routeInfos)` - Replace all routes
- `pushReplacementAll(List<NavRouteInfo> routeInfos)` - Replace last with multiple

#### Properties
- `navigationHistory` - List of navigation steps
- `joinedLocation` - Current location path
- `routeObserver` - Built-in route observer

### Core Classes

#### NavRoute
Defines a route with path and builder function.

#### NavState
Contains route path and extra data for each navigation state.

#### NavExtra
Container for extra data passed between routes.

#### NavStep
Represents a step in navigation history.

#### NavRouteInfo
Simple route information for bulk operations.

#### NavServiceConfig
Configuration object for initializing NavService.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
