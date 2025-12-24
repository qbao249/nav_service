import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});

  final NavState state;

  @override
  Widget build(BuildContext context) {
    final extraData = state.extra?.data ?? {};
    final userId = extraData['userId'] ?? 'Unknown';
    final name = extraData['name'] ?? 'Anonymous User';
    final email = extraData['email'] ?? 'no-email@example.com';
    final source = extraData['source'] ?? 'direct';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('User ID', userId.toString()),
                    _buildInfoRow('Name', name.toString()),
                    _buildInfoRow('Email', email.toString()),
                    _buildInfoRow('Source', source.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Navigation Actions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.push(
                  '/settings',
                  extra: {'fromProfile': true, 'userId': userId},
                );
              },
              child: const Text('Push Settings'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.navigate(
                  '/home',
                  extra: {'returnFrom': 'profile'},
                );
              },
              child: const Text('Navigate to Home (Smart)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                NavService.instance.replace(
                  '/settings',
                  extra: {'replacedFrom': 'profile'},
                );
              },
              child: const Text('Replace with Settings'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        NavService.instance.canPop()
                            ? () => NavService.instance.pop({
                              'profileData': {
                                'userId': userId,
                                'visited': DateTime.now().toString(),
                              },
                            })
                            : null,
                    child: const Text('Pop with Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showNavigationHistory(context);
                    },
                    child: const Text('Show History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showNavigationHistory(BuildContext context) {
    final history = NavService.instance.navigationHistory;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Navigation History'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current: ${NavService.instance.joinedLocation}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Navigation Stack:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    const Text('No navigation history')
                  else
                    ...history.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${index + 1}. ${step.currentState.path}',
                          style: TextStyle(
                            color:
                                index == history.length - 1
                                    ? Colors.blue
                                    : Colors.black54,
                            fontWeight:
                                index == history.length - 1
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                ],
              ),
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
