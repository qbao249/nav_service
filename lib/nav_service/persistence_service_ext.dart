part of 'nav_service.dart';

/// Extension methods for persisting and restoring routes
extension PersistenceServiceExt on NavService {
  /// Persists the current navigation history using the configured
  /// persistence handler
  Future<void> persist() async {
    final onPersist = _persistence?.onPersist;
    if (onPersist == null) return;
    final data = persistBase();
    await onPersist(data);
  }

  /// Restores navigation history using the configured persistence handler
  Future<void> restore() async {
    final onRestore = _persistence?.onRestore;
    if (onRestore == null) return;
    final data = await onRestore();
    restoreBase(data);
  }

  /// Persists the current navigation history to a serializable format
  /// Returns a list of maps containing path and extra data for each route
  List<Map<String, dynamic>> persistBase() {
    try {
      return _steps.map((step) {
        final data = <String, dynamic>{'path': step.path};

        // Only include extra if it exists and is serializable
        final extra = step.currentState.extra?.data;
        if (extra != null && _isSerializable(extra)) {
          data['extra'] = extra;
        }

        return data;
      }).toList();
    } catch (e) {
      // Log error and return empty list as fallback
      debugPrint('Failed to persist navigation history: $e');
      return [];
    }
  }

  /// Restores navigation history from persisted data
  /// [data] should be a List<Map<String, dynamic>> containing route information
  void restoreBase(dynamic data) {
    try {
      final validatedRoutes = _validateAndParseRoutes(data);
      if (validatedRoutes.isEmpty) {
        debugPrint('No valid routes to restore');
        return;
      }

      replaceAll(validatedRoutes);
      debugPrint('Successfully restored ${validatedRoutes.length} routes');
    } catch (e) {
      debugPrint('Failed to restore navigation history: $e');
      // Consider fallback behavior like navigating to home route
      _handleRestorationFailure();
    }
  }

  /// Validates and parses route data from persisted format
  List<NavRouteInfo> _validateAndParseRoutes(dynamic data) {
    if (data is! List || data.isEmpty) {
      return [];
    }

    final List<NavRouteInfo> restoredRoutes = [];

    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        debugPrint('Skipping invalid route item: $item');
        continue;
      }

      final path = _tryParseString(item['path']);
      if (path.isEmpty) {
        debugPrint('Skipping route with invalid path');
        continue;
      }

      final extra = item['extra'];
      Map<String, dynamic>? extraData;

      if (extra is Map<String, dynamic>) {
        extraData = extra;
      } else if (extra != null) {
        debugPrint('Ignoring non-map extra data for route: $path');
      }

      final routeInfo = NavRouteInfo(path: path, extra: extraData);

      restoredRoutes.add(routeInfo);
    }

    return restoredRoutes;
  }

  /// Safely parses a dynamic value to String
  String _tryParseString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return '';
  }

  /// Checks if a value can be safely serialized
  bool _isSerializable(dynamic value) {
    if (value == null) return true;

    if (value is String || value is num || value is bool) {
      return true;
    }

    if (value is List) {
      return value.every(_isSerializable);
    }

    if (value is Map<String, dynamic>) {
      return value.values.every(_isSerializable);
    }

    return false;
  }

  /// Handles restoration failure by implementing fallback behavior
  void _handleRestorationFailure() {
    // Consider implementing fallback logic here, such as:
    // - Navigate to home route
    // - Clear navigation stack
    // - Show error dialog
    debugPrint('Implementing restoration failure fallback');
  }
}
