# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-01-24

### Added
- **Navigation Persistence System**: Complete infrastructure for persisting and restoring navigation state
- **NavPagePersistence**: Configuration class for persistence with `onPersist` and `onRestore` callbacks
- **NavPagePersistenceSchedule**: Schedule configuration supporting immediate and interval-based persistence
- **PersistenceServiceExt**: Extension methods for persisting and restoring navigation history
- **launched() Method**: New method to handle app launch with route restoration or default routes
- **Automatic State Persistence**: Routes are automatically persisted on navigation events when schedule is enabled
- **Data Serialization Validation**: Built-in validation to ensure only serializable data is persisted
- **Restoration Failure Handling**: Graceful fallback behavior when restoration fails

### Changed
- **NavLinkHandler.onRedirect()**: Now requires `BuildContext` as first parameter for better navigation context
- **LinkingServiceExt**: Updated to pass BuildContext to link handlers with null-safety checks
- **Example App**: Updated with SharedPreferences-based persistence implementation
- **Documentation**: README expanded with persistence section and updated examples

### Enhanced
- **Route Observers**: All navigation methods now trigger immediate persistence when configured
- **Navigation History**: Enhanced validation and parsing for restored route data
- **Error Handling**: Improved error messages and fallback behaviors for persistence operations
- Link handlers now receive proper BuildContext for navigation operations
- Better handling of navigation context availability in deep linking

### Tests
- Added 11 comprehensive persistence test scenarios (state restoration, schedules, data validation, error handling)
- Fixed test structure by separating PageAware tests into dedicated group
- Improved navigation and deep linking tests with proper widget test setup
- Total: 29 passing tests covering navigation, persistence, deep linking, and lifecycle management

### Fixed
- Test structure issues with nested group() calls
- Deep linking tests now properly handle BuildContext requirements
- Navigation tests work correctly with actual navigation flow

## [0.4.0] - 2026-01-05

### Added
- Introduced `PageAware` widget for route-aware lifecycle hooks (see `lib/nav_service/page_aware.dart`).
- Example updated: `example/scenes/home.dart` now demonstrates `PageAware` usage.
- Tests updated to cover `PageAware` lifecycle behaviors (`test/nav_service_test.dart`).

### Changed
- Documentation: README updated and installation snippets bumped to `^0.4.0`.

### Fixed
- Minor code cleanups and test updates.

## [0.3.3] - 2026-01-03

### Added
- Added `topics` to `pubspec.yaml`: `nav-service`, `navigation`, `navigator`, `router`, `deep-linking`

### Changed
- Bumped package version to 0.3.3

## [0.3.2] - 2026-01-03

### Added
- Expanded README with `LaunchScreen` initial logic example and `app_links` deep-linking setup

### Changed
- Updated installation snippet to reference `^0.3.2`

## [0.3.1] - 2026-01-03

### Added
- Bump package version to 0.3.1
- Minor documentation clarifications and README examples

## [0.3.0] - 2026-01-03

### Added
- **Deep Linking System**: Complete deep linking infrastructure for handling custom URLs and app links
- **NavLinkHandler**: Abstract class for creating custom link handlers with redirect path patterns
- **NavLinkResult**: Data class containing matched route path, path parameters, and query parameters from URL parsing
- **LinkingServiceExt**: Extension methods for URL processing and link handling with `openUrl()` method
- **Link Prefixes**: Support for multiple URL prefixes (scheme-based like `myapp://` or domain-based like `https://example.com`)
- **Path Parameter Extraction**: Automatic extraction of path parameters using `:paramName` syntax in redirect paths
- **Query Parameter Support**: Full query parameter parsing and passing to link handlers
- **Duplicate Path Detection**: Built-in validation to prevent duplicate redirect paths across handlers
- **URL Pattern Matching**: Advanced pattern matching for complex URL structures with parameters

### Enhanced
- **NavServiceConfig**: Extended with `linkPrefixes` and `linkHandlers` properties for deep linking configuration
- **Export Structure**: Added exports for `NavLinkHandler` and `NavLinkResult` classes in main library

### Fixed
- **Enhanced Navigation Methods**: Improved reliability and error handling in core navigation functions
  - Fixed `replace()` method with better edge case handling when no navigation steps exist
  - Enhanced `pushReplacementAll()` method with improved animation control and route management
  - Improved `replaceAll()` method with enhanced null validation and proper route removal
  - Fixed `removeAll()` method with GoRouter integration warnings and improved state management
- **Animation Improvements**: Added `_NoTransitionMaterialPageRoute` class for smoother route transitions in replace operations when the steps empty
- **Data Processing**: Enhanced NavExtra constructor with optional `processData` parameter for better data handling flexibility
- **Navigation State Consistency**: Fixed navigation state consistency across all replace operations

### Documentation
- Comprehensive deep linking examples in example application
- Link handler implementations for profile and settings navigation
- Integration guides for GoRouter and app_links packages

### Notes
- Deep linking system is fully backward compatible with existing navigation methods
- Supports both custom URL schemes (`myapp://`) and universal links (`https://domain.com`)
- Link handlers provide flexible routing logic for complex navigation scenarios

## [0.2.1] - 2026-01-01

### Added
- Error boundaries: wrapped navigation entry points with `try/catch` to surface and log unexpected exceptions

### Fixed
- Fixed generic type handling for page routes and route builders (preserve `T` result types)
- Fixed `NavState.fromRoute` null-safety when reading `RouteSettings.arguments`
- Fixed `NavStep` constructor ordering and `prevState` handling

### Changed
- Switched several imports from `package:flutter/material.dart` to `package:flutter/widgets.dart` to reduce dependency surface
- Improved and unified debug logging messages across navigation methods
- Reordered singleton initialization and tightened route map construction for consistency

## [0.2.0] - 2025-12-24

### Enhanced
- Improved `NavExtra` data processing with automatic JSON serialization for better data consistency
- Enhanced data integrity when passing complex objects between routes
- Added automatic deep cloning of data to prevent reference issues

## [0.1.0] - 2025-12-23

### Added
- Initial stable release of advanced_nav_service package
- `NavService` singleton class for advanced navigation management
- Route configuration with `NavServiceConfig` and `NavRoute` definitions
- Smart navigation with `navigate()` method that intelligently handles existing routes
- Navigation history tracking with `NavStep` and full stack inspection
- Extra data support with `NavExtra` for type-safe data passing between routes
- Navigation state management with `NavState` for route-aware widgets
- Comprehensive navigation methods:
  - `push()` and `pop()` with animation support
  - `pushReplacement()` and `replace()` for route replacement
  - `pushAndRemoveUntil()` for conditional stack management
  - `popUntil()` and `popUntilPath()` for targeted navigation
  - `popAll()` and `removeAll()` for complete stack clearing
- Bulk navigation operations:
  - `pushAll()` for multiple route pushing
  - `replaceAll()` for complete stack replacement
  - `pushReplacementAll()` for advanced stack manipulation
- Built-in route observer with automatic navigation event tracking
- Navigation debugging with `joinedLocation` and history inspection
- Configurable logging for development and debugging
- Custom page route with optimized animations
- Complete example application demonstrating all features
- Comprehensive test coverage for all navigation scenarios
- Full API documentation and usage examples
