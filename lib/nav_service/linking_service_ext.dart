part of 'nav_service.dart';

extension LinkingServiceExt on NavService {
  /// Open a URL and handle navigation based on registered link handlers
  ///
  /// [url] The URL to be opened
  ///
  /// If the URL matches any registered link handler's redirect paths,
  /// the corresponding onRedirect method will be invoked.
  void openUrl(String url) {
    final uri = Uri.parse(url);

    final path = _getValidPath(url, uri);

    if (path.isEmpty) {
      if (_enableLogger) {
        debugPrint(
          'LinkingServiceExt.openUrl: No valid path found for URL: $url'
          ' may be no matching link prefix in linkPrefixes: $_linkPrefixes',
        );
      }
      return;
    }

    _linking(path, uri.queryParameters);
  }

  /// Get the valid path from the URL based on registered link prefixes
  ///
  /// [url] The URL to be parsed
  /// [uri] The parsed Uri object
  ///
  /// Returns the valid path if a matching prefix is found, otherwise returns an empty string
  String _getValidPath(String url, Uri uri) {
    final path = uri.path; // includes leading '/'

    String normalize(String p) {
      if (p.isEmpty) return '';
      return p.startsWith('/') ? p : '/$p';
    }

    if (_linkPrefixes.isEmpty) return normalize(path);

    for (final prefix in _linkPrefixes) {
      if (prefix.isEmpty) continue;

      // If the raw URL starts with the prefix (handles scheme prefixes like 'myapp://')
      if (url.startsWith(prefix)) {
        final remainder = url.substring(prefix.length);
        final parsed = Uri.parse(remainder.isEmpty ? '/' : remainder);
        return normalize(parsed.path);
      }

      // If the parsed path starts with the prefix (handles path prefixes like '/app')
      if (path.startsWith(prefix)) {
        final remainder = path.substring(prefix.length);
        return normalize(remainder.isEmpty ? '/' : remainder);
      }
    }

    return '';
  }

  /// Internal method to handle linking logic
  ///
  /// [path] The path extracted from the URL
  ///
  /// [queryParameters] The query parameters extracted from the URL
  ///
  /// This method checks registered link handlers for matching redirect paths
  /// and invokes their onRedirect methods with the appropriate NavLinkResult.
  void _linking(String path, Map<String, String> queryParameters) {
    final pathSegments =
        path.split('/').where((segment) => segment.isNotEmpty).toList();
    for (final linkHandler in _linkHandlers) {
      for (final redirectURL in linkHandler.redirectPaths) {
        // parse redirectURL so any query string in the pattern is removed
        final parsedRedirect = Uri.parse(redirectURL);
        final redirectSegments =
            parsedRedirect.path.split('/').where((s) => s.isNotEmpty).toList();
        if (redirectSegments.length != pathSegments.length) continue;

        final pathParameters = <String, String>{};
        var isMatch = true;

        for (var i = 0; i < redirectSegments.length; i++) {
          final redirectSegment = redirectSegments[i];
          final pathSegment = pathSegments[i];

          if (redirectSegment.startsWith(':')) {
            final paramName = redirectSegment.substring(1);
            final value = Uri.decodeComponent(pathSegment);
            pathParameters[paramName] = value;
          } else if (redirectSegment != pathSegment) {
            isMatch = false;
            break;
          }
        }

        if (isMatch) {
          // use parsed path (without query) as matched route path
          final matchedRoutePath = parsedRedirect.path;
          final result = NavLinkResult(
            matchedRoutePath: matchedRoutePath,
            pathParameters: pathParameters,
            queryParameters: queryParameters,
          );
          if (_currentContext == null) {
            if (_enableLogger) {
              debugPrint(
                'LinkingService._linking: Navigator context is null, '
                'cannot perform navigation for path: $path',
              );
            }
          } else {
            linkHandler.onRedirect(_currentContext!, result);
          }
        }
      }
    }
  }

  /// Initialize link handlers with duplicate path checking
  ///
  /// [linkHandlers] The list of NavLinkHandler instances to be registered
  ///
  /// This method checks for duplicate redirect paths across all handlers.
  /// If duplicates are found, an exception is thrown to enforce uniqueness.
  void _initLinkHandlers(List<NavLinkHandler> linkHandlers) {
    // check for duplicates
    // if duplicates found, throw error and skip adding

    final seenPaths = <String>{};
    for (final handler in linkHandlers) {
      for (final path in handler.redirectPaths) {
        if (seenPaths.contains(path)) {
          throw Exception(
            'Duplicate redirect path "$path" found in NavLinkHandlers. '
            'Each redirect path must be unique across all NavLinkHandlers.',
          );
        }
        seenPaths.add(path);
      }
    }

    // No duplicates found, clean up and add all handlers
    _linkHandlers.clear();
    _linkHandlers.addAll(linkHandlers);
  }
}
