# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
