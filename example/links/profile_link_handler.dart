import 'package:flutter/material.dart';
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
    // Handle any additional logic on redirect if needed
    debugPrint(
      'Redirected to Profile with result: matchedPath=${result.matchedRoutePath}, '
      'pathParameters=${result.pathParameters}, '
      'queryParameters=${result.queryParameters}',
    );

    // Navigate to Profile using NavService
    NavService.instance.navigate(
      '/profile',
      extra: {...result.pathParameters, ...result.queryParameters},
    );
  }
}
