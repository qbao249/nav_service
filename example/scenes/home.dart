import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              _showNavigationInfo(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Home Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Demonstrates basic navigation operations:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                NavService.instance.push('/settings');
              },
              child: const Text('Push Settings'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.push(
                  '/profile',
                  extra: {
                    'userId': 456,
                    'name': 'John Doe',
                    'email': 'john@example.com',
                  },
                );
              },
              child: const Text('Push Profile with Data'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.pushReplacement('/settings');
              },
              child: const Text('Replace with Settings'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.navigate('/profile');
              },
              child: const Text('Navigate (Smart Navigation)'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        NavService.instance.canPop()
                            ? () => NavService.instance.pop()
                            : null,
                    child: const Text('Pop'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (NavService.instance.navigationHistory.length > 1) {
                        NavService.instance.popAll();
                      }
                    },
                    child: const Text('Pop All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationInfo(BuildContext context) {
    final history = NavService.instance.navigationHistory;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Navigation Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Location: ${NavService.instance.joinedLocation}'),
                const SizedBox(height: 8),
                Text('History Count: ${history.length}'),
                const SizedBox(height: 8),
                const Text('Navigation Stack:'),
                ...history.map((step) => Text('• ${step.currentState.path}')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
