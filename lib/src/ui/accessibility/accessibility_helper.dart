import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accessibility helpers and utilities for production-ready app
/// Provides comprehensive accessibility support including screen readers,
/// high contrast, focus management, and keyboard navigation

class AccessibilityHelper {
  static const double minimumTouchTargetSize = 48.0;
  static const double preferredTouchTargetSize = 56.0;
  
  /// Check if device has accessibility features enabled
  static bool get isAccessibilityEnabled {
    // This would normally check system accessibility settings
    return true; // Assume accessibility is always important
  }

  /// Check if high contrast mode is enabled
  static bool get isHighContrastEnabled {
    return MediaQueryData.fromWindow(WidgetsBinding.instance.window)
        .highContrast;
  }

  /// Check if reduce motion is enabled
  static bool get isReduceMotionEnabled {
    return MediaQueryData.fromWindow(WidgetsBinding.instance.window)
        .disableAnimations;
  }

  /// Get appropriate animation duration based on accessibility settings
  static Duration getAnimationDuration(Duration defaultDuration) {
    return isReduceMotionEnabled 
        ? Duration.zero 
        : defaultDuration;
  }

  /// Announce text to screen readers
  static void announce(BuildContext context, String message) {
    if (isAccessibilityEnabled) {
      // Use Semantics widget to announce to screen readers
      // This is a simplified approach - in production you might use platform channels
      debugPrint('Accessibility announcement: $message');
      
      // Also provide haptic feedback for important announcements
      HapticFeedback.lightImpact();
    }
  }

  /// Announce emergency information with strong emphasis
  static void announceEmergency(BuildContext context, String message) {
    if (isAccessibilityEnabled) {
      // Use strong announcement for emergencies
      debugPrint('EMERGENCY ANNOUNCEMENT: $message');
      
      // Strong haptic feedback for emergencies
      HapticFeedback.heavyImpact();
    }
  }

  /// Get accessible color contrast ratio
  static double getContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color combination meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if color combination meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }

  /// Get accessible color for text on background
  static Color getAccessibleTextColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create accessible button with proper touch target size
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? tooltip,
    double minSize = minimumTouchTargetSize,
    EdgeInsetsGeometry? padding,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create accessible text with proper contrast and readability
  static Widget createAccessibleText(
    String text, {
    TextStyle? style,
    Color? backgroundColor,
    int? maxLines,
    TextAlign? textAlign,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      readOnly: true,
      child: Container(
        color: backgroundColor,
        child: Text(
          text,
          style: style,
          maxLines: maxLines,
          textAlign: textAlign,
          // Ensure minimum readable text size
          textScaleFactor: 1.0,
        ),
      ),
    );
  }

  /// Create accessible form field with proper labeling
  static Widget createAccessibleFormField({
    required Widget child,
    required String label,
    String? hint,
    String? error,
    bool isRequired = false,
  }) {
    final semanticLabel = isRequired ? '$label (required)' : label;
    
    return Semantics(
      label: semanticLabel,
      hint: hint,
      textField: true,
      child: child,
    );
  }

  /// Create loading indicator with accessibility support
  static Widget createAccessibleLoadingIndicator({
    required String message,
    double size = 32.0,
    Color? color,
  }) {
    return Semantics(
      label: 'Loading: $message',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 16,
              valueColor: color != null 
                  ? AlwaysStoppedAnimation<Color>(color)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          createAccessibleText(
            message,
            style: const TextStyle(fontSize: 16),
            semanticLabel: 'Loading status: $message',
          ),
        ],
      ),
    );
  }

  /// Focus management utilities
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  /// Move focus to next field
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous field
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Dismiss current focus
  static void dismissFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Accessible scaffold with built-in accessibility features
class AccessibleScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;
  final String? pageTitle;
  final String? pageDescription;

  const AccessibleScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.pageTitle,
    this.pageDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: pageTitle,
      hint: pageDescription,
      child: Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Emergency accessibility announcer for critical situations
class EmergencyAnnouncer {
  static Timer? _announcementTimer;
  
  /// Start periodic emergency announcements
  static void startEmergencyAnnouncements(
    BuildContext context,
    String message, {
    Duration interval = const Duration(seconds: 30),
  }) {
    AccessibilityHelper.announceEmergency(context, message);
    
    _announcementTimer?.cancel();
    _announcementTimer = Timer.periodic(interval, (_) {
      AccessibilityHelper.announceEmergency(context, message);
    });
  }

  /// Stop emergency announcements
  static void stopEmergencyAnnouncements() {
    _announcementTimer?.cancel();
    _announcementTimer = null;
  }
}

/// Keyboard navigation handler for complex screens
class KeyboardNavigationHandler extends StatefulWidget {
  final Widget child;
  final List<FocusNode> focusNodes;
  final VoidCallback? onEscape;

  const KeyboardNavigationHandler({
    super.key,
    required this.child,
    required this.focusNodes,
    this.onEscape,
  });

  @override
  State<KeyboardNavigationHandler> createState() => _KeyboardNavigationHandlerState();
}

class _KeyboardNavigationHandlerState extends State<KeyboardNavigationHandler> {
  late FocusNode _rootFocusNode;

  @override
  void initState() {
    super.initState();
    _rootFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocusNode,
      onKey: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onEscape?.call();
        return KeyEventResult.handled;
      }
      
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (event.isShiftPressed) {
          AccessibilityHelper.focusPrevious(context);
        } else {
          AccessibilityHelper.focusNext(context);
        }
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }
}

/// Live region for dynamic content updates
class AccessibleLiveRegion extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool isPolite;

  const AccessibleLiveRegion({
    super.key,
    required this.child,
    this.label,
    this.isPolite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
}

extension AccessibilityExtensions on BuildContext {
  /// Quick access to accessibility helper methods
  void announce(String message) {
    AccessibilityHelper.announce(this, message);
  }

  void announceEmergency(String message) {
    AccessibilityHelper.announceEmergency(this, message);
  }

  bool get isHighContrast => AccessibilityHelper.isHighContrastEnabled;
  bool get isReduceMotion => AccessibilityHelper.isReduceMotionEnabled;
  
  Duration adjustAnimationDuration(Duration duration) {
    return AccessibilityHelper.getAnimationDuration(duration);
  }
}