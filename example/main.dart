import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';
// Uncomment the following lines if using shared_preferences
// for persistence
// import 'package:shared_preferences/shared_preferences.dart';

import 'links/profile_link_handler.dart';
import 'links/settings_link_handler.dart';
import 'scenes/home.dart';
import 'scenes/profile.dart';
import 'scenes/settings.dart';

final navigatorKey = GlobalKey<NavigatorState>();
const restorationId = 'app_restoration_id';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NavService.instance.init(
    NavServiceConfig(
      navigatorKey: navigatorKey,
      routes: navRoutes,
      enableLogger: true,
      linkPrefixes: ['myapp://', 'https://myapp.com/'],
      linkHandlers: [SettingsLinkHandler(), ProfileLinkHandler()],
      persistence: NavPagePersistence(
        onPersist: (routes) async {
          // final pref = await SharedPreferences.getInstance();
          // await pref.setString(restorationId, jsonEncode(routes));
        },
        onRestore: () async {
          // final pref = await SharedPreferences.getInstance();
          // final jsonString = pref.getString(restorationId);
          // if (jsonString != null) {
          //   final List<dynamic> data = jsonDecode(jsonString);
          //   return List<Map<String, dynamic>>.from(data);
          // }
          return [];
        },
        enableSchedule: true,
        schedule: const NavPagePersistenceSchedule(immediate: true),
      ),
    ),
  );

  runApp(const NavServiceExample());

  // Launch the app with initial routes after a delay
  Future.delayed(const Duration(seconds: 2), () {
    // App started - restore previous routes or set default
    NavService.instance.launched([NavRouteInfo(path: '/home')]);
  });
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
      home: const PlashScreen(),
    );
  }
}

class PlashScreen extends StatelessWidget {
  const PlashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

final navRoutes = [
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
