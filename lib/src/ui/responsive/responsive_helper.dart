import 'package:flutter/material.dart';

/// Responsive design utilities for production-ready mobile app
/// Provides consistent sizing, spacing, and layout across different screen sizes

class ResponsiveHelper {
  // Breakpoints based on Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 905;
  static const double desktopBreakpoint = 1240;

  /// Screen size categories
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return ScreenSize.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: const EdgeInsets.all(8),
      tablet: const EdgeInsets.all(12),
      desktop: const EdgeInsets.all(16),
    );
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseMobileSize,
  ) {
    return getResponsiveValue(
      context,
      mobile: baseMobileSize,
      tablet: baseMobileSize * 1.1,
      desktop: baseMobileSize * 1.2,
    );
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
  }

  /// Get responsive grid columns
  static int getResponsiveColumns(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  /// Create responsive container with max width
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: getMaxContentWidth(context),
      ),
      padding: padding ?? getResponsivePadding(context),
      margin: margin ?? getResponsiveMargin(context),
      child: child,
    );
  }

  /// Create responsive centered content
  static Widget responsiveCenterContent({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Center(
      child: responsiveContainer(
        context: context,
        padding: padding,
        child: child,
      ),
    );
  }

  /// Get orientation-aware layout
  static Widget orientationAwareLayout({
    required BuildContext context,
    required Widget portrait,
    required Widget landscape,
  }) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }

  /// Create adaptive layout based on screen size
  static Widget adaptiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Create responsive app bar
  static PreferredSizeWidget responsiveAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    final fontSize = getResponsiveFontSize(context, 20);
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(fontSize: fontSize),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      toolbarHeight: getResponsiveValue(
        context,
        mobile: 56.0,
        tablet: 64.0,
        desktop: 72.0,
      ),
    );
  }

  /// Create responsive bottom navigation
  static Widget responsiveBottomNavigation({
    required BuildContext context,
    required int currentIndex,
    required Function(int) onTap,
    required List<BottomNavigationBarItem> items,
  }) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: getResponsiveFontSize(context, 12),
      unselectedFontSize: getResponsiveFontSize(context, 10),
      iconSize: getResponsiveIconSize(context),
    );
  }

  /// Create responsive card
  static Widget responsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? elevation,
  }) {
    return Card(
      elevation: elevation ?? getResponsiveValue(
        context,
        mobile: 2.0,
        tablet: 4.0,
        desktop: 6.0,
      ),
      margin: margin ?? getResponsiveMargin(context),
      child: Padding(
        padding: padding ?? getResponsivePadding(context),
        child: child,
      ),
    );
  }

  /// Create responsive list tile
  static Widget responsiveListTile({
    required BuildContext context,
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: getResponsiveFontSize(context, 16),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: getResponsiveFontSize(context, 14),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: getResponsivePadding(context),
    );
  }

  /// Create responsive dialog
  static Future<T?> showResponsiveDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return Dialog(
          child: Container(
            width: getResponsiveValue(
              context,
              mobile: MediaQuery.of(context).size.width * 0.9,
              tablet: 400.0,
              desktop: 500.0,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Safe area with responsive padding
  static Widget responsiveSafeArea({
    required BuildContext context,
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Padding(
        padding: getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

enum ScreenSize {
  mobile,
  tablet,
  desktop,
}

/// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.adaptiveLayout(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    return builder(context, screenSize);
  }
}

/// Responsive value widget
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return builder(context, value);
  }
}

/// Extensions for easier responsive design
extension ResponsiveExtensions on BuildContext {
  ScreenSize get screenSize => ResponsiveHelper.getScreenSize(this);
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  EdgeInsets get responsivePadding => ResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveHelper.getResponsiveMargin(this);
  
  double responsiveFontSize(double baseMobileSize) =>
      ResponsiveHelper.getResponsiveFontSize(this, baseMobileSize);
  
  double get responsiveIconSize => ResponsiveHelper.getResponsiveIconSize(this);
  int get responsiveColumns => ResponsiveHelper.getResponsiveColumns(this);
  double get maxContentWidth => ResponsiveHelper.getMaxContentWidth(this);
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) => ResponsiveHelper.getResponsiveValue(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}