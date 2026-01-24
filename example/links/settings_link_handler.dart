import 'package:flutter/material.dart';
import 'package:advanced_nav_service/nav_service.dart';

class SettingsLinkHandler extends NavLinkHandler {
  @override
  List<String> get redirectPaths => [
    '/settings',
    '/settings/:tab',
    '/preferences/:section',
  ];

  @override
  void onRedirect(BuildContext context, NavLinkResult result) {
    debugPrint(
      'Redirected to Settings with result: matchedPath=${result.matchedRoutePath}, '
      'pathParameters=${result.pathParameters}, '
      'queryParameters=${result.queryParameters}',
    );

    // Navigate to settings with appropriate extra data
    final extra = <String, dynamic>{
      ...result.pathParameters,
      ...result.queryParameters,
    };

    if (result.pathParameters.containsKey('tab')) {
      extra['activeTab'] = result.pathParameters['tab'];
    }
    if (result.pathParameters.containsKey('section')) {
      extra['section'] = result.pathParameters['section'];
    }

    NavService.instance.navigate('/settings', extra: extra);
  }
}
