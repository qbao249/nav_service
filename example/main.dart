import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';

import 'scenes/home.dart';
import 'scenes/profile.dart';
import 'scenes/settings.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  NavService.instance.init(
    NavServiceConfig(
      routes: _routes,
      navigatorKey: navigatorKey,
      enableLogger: true,
    ),
  );
  runApp(const NavServiceExample());
}

class NavServiceExample extends StatelessWidget {
  const NavServiceExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavService Example',
      navigatorKey: navigatorKey,
      navigatorObservers: [NavService.instance.routeObserver],
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LaunchScreen(),
    );
  }
}

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NavService Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to NavService Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                NavService.instance.push('/home');
              },
              child: const Text('Navigate to Home'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NavService.instance.push('/settings', extra: {'theme': 'dark'});
              },
              child: const Text('Navigate to Settings with Extra Data'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                NavService.instance.pushAll([
                  NavRouteInfo(path: '/home'),
                  NavRouteInfo(path: '/profile', extra: {'userId': 123}),
                ]);
              },
              child: const Text('Push Multiple Routes'),
            ),
          ],
        ),
      ),
    );
  }
}

final _routes = [
  NavRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  NavRoute(
    path: '/settings',
    builder: (context, state) => SettingsScreen(state: state),
  ),
  NavRoute(
    path: '/profile',
    builder: (context, state) => ProfileScreen(state: state),
  ),
];
