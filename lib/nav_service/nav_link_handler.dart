import 'package:flutter/widgets.dart';

import 'nav_link_result.dart';

/// This class extends [NavLinkHandler] and defines the paths that should
/// redirect to a specific scenerio in the app.
///
/// It also provides a method
/// to handle this redirection logic.
abstract class NavLinkHandler {
  List<String> get redirectPaths;

  void onRedirect(BuildContext context, NavLinkResult result);
}
