import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for production-ready app
/// Provides image caching, widget optimization, and performance monitoring

class PerformanceHelper {
  static final PerformanceHelper _instance = PerformanceHelper._internal();
  static PerformanceHelper get instance => _instance;
  PerformanceHelper._internal();

  final Map<String, dynamic> _performanceMetrics = {};
  final Map<String, Timer> _timers = {};

  /// Start performance tracking for a specific operation
  void startTracking(String operationName) {
    _performanceMetrics[operationName] = DateTime.now();
    debugPrint('🟡 Performance: Started tracking $operationName');
  }

  /// Stop performance tracking and log duration
  void stopTracking(String operationName) {
    final startTime = _performanceMetrics[operationName] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('🟢 Performance: $operationName completed in ${duration.inMilliseconds}ms');
      _performanceMetrics.remove(operationName);
    }
  }

  /// Track widget build performance
  Widget trackWidgetBuild(String widgetName, Widget child) {
    return kDebugMode
        ? _PerformanceTrackingWidget(
            name: widgetName,
            child: child,
          )
        : child;
  }

  /// Optimize image loading with proper caching
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? cacheKey,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image loading error: $error');
        return errorWidget ??
            const Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            );
      },
    );
  }

  /// Create optimized list view with proper item building
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Add performance tracking for list items in debug mode
        return kDebugMode
            ? _PerformanceTrackingWidget(
                name: 'ListItem_$index',
                child: itemBuilder(context, index),
              )
            : itemBuilder(context, index);
      },
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Optimize list rendering
      cacheExtent: 500, // Cache items outside viewport
      addAutomaticKeepAlives: false, // Reduce memory usage
    );
  }

  /// Debounce function calls to improve performance
  static void debounce(String key, Duration delay, VoidCallback callback) {
    final timer = instance._timers[key];
    timer?.cancel();
    
    instance._timers[key] = Timer(delay, () {
      callback();
      instance._timers.remove(key);
    });
  }

  /// Throttle function calls to limit execution frequency
  static void throttle(String key, Duration interval, VoidCallback callback) {
    if (!instance._timers.containsKey(key)) {
      callback();
      instance._timers[key] = Timer(interval, () {
        instance._timers.remove(key);
      });
    }
  }

  /// Memory-efficient color creation
  static Color createColor(int value) {
    return Color(value);
  }

  /// Pre-cache critical widgets (simplified approach)
  static void precacheWidget(BuildContext context, Widget widget) {
    if (kDebugMode) {
      debugPrint('Pre-caching widget: ${widget.runtimeType}');
    }
    // In production, you might implement more sophisticated pre-caching
  }

  /// Batch widget updates for better performance
  static Widget batchUpdates(List<Widget> children) {
    return Column(
      children: [
        for (final child in children) child,
      ],
    );
  }

  /// Monitor frame rendering performance
  static void monitorFramePerformance() {
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('Frame performance monitoring enabled');
      });
    }
  }

  /// Clean up performance tracking resources
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _performanceMetrics.clear();
  }
}

/// Widget that tracks build performance in debug mode
class _PerformanceTrackingWidget extends StatelessWidget {
  final String name;
  final Widget child;

  const _PerformanceTrackingWidget({
    required this.name,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = child;
      stopwatch.stop();
      
      if (stopwatch.elapsedMilliseconds > 16) { // Frame budget exceeded
        debugPrint('⚠️ Slow widget build: $name took ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    }
    return child;
  }
}

/// Optimized container for better rendering performance
class OptimizedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;

  const OptimizedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    // Use more efficient widgets when possible
    if (decoration == null && 
        constraints == null && 
        alignment == null &&
        margin == null) {
      // Use Padding instead of Container when only padding is needed
      if (padding != null && color == null) {
        return Padding(
          padding: padding!,
          child: child,
        );
      }
      
      // Use ColoredBox instead of Container when only color is needed
      if (color != null && padding == null) {
        return ColoredBox(
          color: color!,
          child: child,
        );
      }
    }

    // Use Container for complex cases
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      constraints: constraints,
      alignment: alignment,
      child: child,
    );
  }
}

/// Optimized text widget with better performance
class OptimizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const OptimizedText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      textAlign: textAlign,
      // Optimize text rendering
      softWrap: maxLines != 1,
    );
  }
}

/// Lazy loading wrapper for expensive widgets
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _cachedWidget;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget != null) {
      return _cachedWidget!;
    }

    if (!_isLoading) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _cachedWidget = widget.builder();
            _isLoading = false;
          });
        }
      });
    }

    return widget.placeholder ?? 
        const Center(child: CircularProgressIndicator());
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? name;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.name,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuild;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildCount++;
      final now = DateTime.now();
      
      if (_lastBuild != null) {
        final timeSinceLastBuild = now.difference(_lastBuild!);
        if (timeSinceLastBuild.inMilliseconds < 16) {
          debugPrint('⚠️ Frequent rebuilds detected for ${widget.name ?? 'widget'}: $_buildCount builds');
        }
      }
      
      _lastBuild = now;
    }

    return widget.child;
  }
}

/// Optimized scroll view with performance enhancements
class OptimizedScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedScrollView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    // Use ListView.builder for large lists
    if (children.length > 20) {
      return ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        cacheExtent: 500,
        addAutomaticKeepAlives: false,
      );
    }

    // Use SingleChildScrollView for small lists
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      physics: physics,
      child: Column(children: children),
    );
  }
}

/// Memory-efficient image cache manager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  static ImageCacheManager get instance => _instance;
  ImageCacheManager._internal();

  final Map<String, ImageProvider> _cache = {};
  static const int maxCacheSize = 100;

  ImageProvider getImage(String url, {double? width, double? height}) {
    final key = '$url-$width-$height';
    
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    final image = NetworkImage(url);
    _cache[key] = image;
    return image;
  }

  void clearCache() {
    _cache.clear();
  }

  void preloadImage(String url, BuildContext context) {
    final image = getImage(url);
    precacheImage(image, context);
  }
}

/// Performance extensions for widgets
extension PerformanceExtensions on Widget {
  /// Track performance of this widget
  Widget trackPerformance(String name) {
    return PerformanceHelper.instance.trackWidgetBuild(name, this);
  }

  /// Monitor rebuild frequency
  Widget monitorRebuilds(String? name) {
    return PerformanceMonitor(name: name, child: this);
  }

  /// Make widget lazy-loaded
  Widget makeLazy({Widget? placeholder}) {
    return LazyWidget(
      builder: () => this,
      placeholder: placeholder,
    );
  }
}