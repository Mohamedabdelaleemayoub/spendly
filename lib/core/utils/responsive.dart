import 'package:flutter/material.dart';

/// Screen device categories based on available viewport width.
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Standardized breakpoints and layout constraints for Spendly.
class Breakpoints {
  const Breakpoints._();

  /// Viewports strictly below 600px are treated as Mobile.
  static const double mobileMax = 599.0;

  /// Viewports from 600px to 1023px are treated as Tablet.
  static const double tabletMin = 600.0;
  static const double tabletMax = 1023.0;

  /// Viewports of 1024px and above are treated as Desktop / Large screens.
  static const double desktopMin = 1024.0;

  /// Minimum width threshold where NavigationRail is preferred over BottomNavigationBar.
  static const double navigationRailMin = 720.0;

  /// Maximum comfortable content width on wide desktop screens.
  static const double maxContentWidth = 1200.0;

  /// Maximum comfortable width for forms and input cards.
  static const double maxFormWidth = 640.0;

  /// Maximum comfortable width for authentication and onboarding screens.
  static const double maxAuthWidth = 460.0;

  /// Maximum comfortable width for popup dialogs and action sheets.
  static const double maxDialogWidth = 520.0;

  /// Maximum comfortable width for bottom sheets on wide screens.
  static const double maxSheetWidth = 600.0;
}

/// Helper utility class for responsive queries and layout adaptations.
class Responsive {
  const Responsive._();

  /// Returns true if the screen width is less than [Breakpoints.tabletMin].
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.tabletMin;
  }

  /// Returns true if the screen width is between [Breakpoints.tabletMin] and [Breakpoints.desktopMin] - 1.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
  }

  /// Returns true if the screen width is at least [Breakpoints.desktopMin].
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.desktopMin;
  }

  /// Returns true if the screen width is wide enough for a side NavigationRail.
  static bool useNavRail(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.navigationRailMin;
  }

  /// Returns true if the device is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Returns the current [ScreenType].
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktopMin) {
      return ScreenType.desktop;
    } else if (width >= Breakpoints.tabletMin) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  /// Returns a responsive value based on the current screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  /// Returns a responsive grid cross-axis count.
  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return value<int>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Returns standard horizontal padding scaled appropriately for the screen size.
  static EdgeInsets pagePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    );
  }
}

/// A widget that builds different layouts based on available box constraints.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktopMin && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= Breakpoints.tabletMin && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

/// Centers content horizontally and clamps it to [maxWidth] on tablets and desktops.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Centers form content horizontally with appropriate maximum constraints and padding.
class ResponsiveFormContainer extends StatelessWidget {
  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxFormWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
