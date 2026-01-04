part of 'nav_service.dart';

/// A widget that is aware of navigation events such as appearing and disappearing.
///
/// It uses [RouteAware] to listen to navigation changes and triggers the provided
/// callbacks accordingly.
class PageAware extends StatefulWidget {
  final Widget child;

  const PageAware({
    required this.child,
    super.key,
    this.onAppear,
    this.onDisappear,
    this.onInit,
    this.onDispose,
    this.onAfterFirstFrame,
    this.waitForTransition,
    this.onDidPush,
    this.onDidPop,
  });

  /// Called when the Next Route has been popped, and this route is now visible.
  final VoidCallback? onAppear;

  /// Called when a Next Route has been pushed, and this route is no longer visible.
  final VoidCallback? onDisappear;

  /// Called when the widget is initialized.
  final VoidCallback? onInit;

  /// Called when the widget is disposed.
  final VoidCallback? onDispose;

  /// Called after the first frame is rendered.
  final VoidCallback? onAfterFirstFrame;

  /// Called when the route has been pushed.
  final VoidCallback? onDidPush;

  /// Called when the route has been popped.
  ///
  /// Will not affect when the widget is replaced / removed
  final VoidCallback? onDidPop;

  /// If true, wait for the route transition animation to complete
  /// before calling [onAfterFirstFrame]. Defaults to false.
  final bool? waitForTransition;

  @override
  State<PageAware> createState() => _PageAwareState();
}

class _PageAwareState extends State<PageAware> with RouteAware {
  bool _afterFirstFrameCalled = false;
  Animation<double>? _routeAnimation;
  void Function(AnimationStatus)? _routeAnimationListener;

  bool get _waitForTransition => widget.waitForTransition ?? false;

  //
  // Lifecycle Methods
  //

  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
    // Only run the post-frame callback immediately when we're NOT
    // waiting for the route transition to complete. If `waitForTransition`
    // is true, `didChangeDependencies` hooks the route animation and will
    // call the callback after animation completes.
    if (!_waitForTransition && widget.onAfterFirstFrame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_afterFirstFrameCalled) {
          _afterFirstFrameCalled = true;
          widget.onAfterFirstFrame?.call();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      NavService.instance.routeObserver.subscribe(this, route);
      // Handle onAfterFirstFrame timing.
      if (!_afterFirstFrameCalled && widget.onAfterFirstFrame != null) {
        if (_waitForTransition) {
          final animation = route.animation;
          if (animation != null) {
            _routeAnimation = animation;
            // If already completed, call on next frame.
            if (animation.status == AnimationStatus.completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (!_afterFirstFrameCalled) {
                  _afterFirstFrameCalled = true;
                  widget.onAfterFirstFrame?.call();
                }
              });
            } else {
              _routeAnimationListener = (AnimationStatus status) {
                if (status == AnimationStatus.completed &&
                    !_afterFirstFrameCalled) {
                  if (!mounted) return;
                  _afterFirstFrameCalled = true;
                  widget.onAfterFirstFrame?.call();
                  _routeAnimation?.removeStatusListener(
                    _routeAnimationListener!,
                  );
                }
              };
              animation.addStatusListener(_routeAnimationListener!);
            }
          } else {
            // No animation available, fallback to post-frame callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!_afterFirstFrameCalled) {
                _afterFirstFrameCalled = true;
                widget.onAfterFirstFrame?.call();
              }
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    NavService.instance.routeObserver.unsubscribe(this);
    if (_routeAnimation != null && _routeAnimationListener != null) {
      _routeAnimation?.removeStatusListener(_routeAnimationListener!);
    }
    widget.onDispose?.call();
    super.dispose();
  }

  //
  // Aware Methods
  //

  @override
  void didPopNext() {
    super.didPopNext();
    widget.onAppear?.call();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    widget.onDisappear?.call();
  }

  @override
  void didPop() {
    super.didPop();
    widget.onDidPop?.call();
  }

  @override
  void didPush() {
    super.didPush();
    widget.onDidPush?.call();
  }

  //
  // Build Method
  //

  @override
  Widget build(BuildContext context) => widget.child;
}
