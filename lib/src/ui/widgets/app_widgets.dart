import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Production-ready UI components with loading states and responsive design
/// Provides consistent, accessible, and polished user interface elements

/// Enhanced loading indicator with customizable appearance
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool showMessage;

  const AppLoadingIndicator({
    super.key,
    this.size = 32.0,
    this.color,
    this.message,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size / 16,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        if (showMessage && message != null) ...[
          const SizedBox(height: DesignTokens.spaceMD),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Enhanced button with loading state and accessibility
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEmergency;
  final IconData? icon;
  final ButtonVariant variant;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEmergency = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;
    
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.outlined 
                    ? Theme.of(context).primaryColor
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSM),
        ] else if (icon != null) ...[
          Icon(icon, size: DesignTokens.iconSM),
          const SizedBox(width: DesignTokens.spaceSM),
        ],
        Text(text),
      ],
    );

    Widget button;
    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: isEmergency 
              ? EmergencyTheme.emergencyButtonStyle
              : null,
          child: buttonContent,
        );
        break;
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          child: buttonContent,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          child: buttonContent,
        );
        break;
    }

    if (width != null) {
      button = SizedBox(width: width, child: button);
    }

    if (padding != null) {
      button = Padding(padding: padding!, child: button);
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: '$text ${isEmergency ? 'Emergency button' : 'button'}',
      child: button,
    );
  }
}

enum ButtonVariant { primary, outlined, text }

/// Responsive card with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final bool isSelected;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      elevation: elevation ?? (isSelected ? DesignTokens.elevationMD : DesignTokens.elevationSM),
      color: color ?? (isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null),
      margin: margin ?? const EdgeInsets.all(DesignTokens.spaceSM),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(DesignTokens.spaceMD),
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        child: card,
      );
    }

    return card;
  }
}

/// Status indicator with semantic colors
class StatusIndicator extends StatelessWidget {
  final StatusType status;
  final String? text;
  final double size;
  final bool showText;

  const StatusIndicator({
    super.key,
    required this.status,
    this.text,
    this.size = DesignTokens.iconSM,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: statusConfig.color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusConfig.icon,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
        if (showText && (text != null || statusConfig.defaultText != null)) ...[
          const SizedBox(width: DesignTokens.spaceSM),
          Text(
            text ?? statusConfig.defaultText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusConfig.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  _StatusConfig _getStatusConfig(StatusType status) {
    switch (status) {
      case StatusType.online:
        return _StatusConfig(
          color: AppTheme.successColor,
          icon: Icons.check_circle,
          defaultText: 'Online',
        );
      case StatusType.offline:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.offline_bolt,
          defaultText: 'Offline',
        );
      case StatusType.connecting:
        return _StatusConfig(
          color: AppTheme.warningColor,
          icon: Icons.sync,
          defaultText: 'Connecting',
        );
      case StatusType.error:
        return _StatusConfig(
          color: AppTheme.emergencyColor,
          icon: Icons.error,
          defaultText: 'Error',
        );
      case StatusType.emergency:
        return _StatusConfig(
          color: AppTheme.emergencyColor,
          icon: Icons.warning,
          defaultText: 'Emergency',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String? defaultText;

  _StatusConfig({
    required this.color,
    required this.icon,
    this.defaultText,
  });
}

enum StatusType { online, offline, connecting, error, emergency }

/// Enhanced list tile with proper spacing and accessibility
class AppListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isDense;

  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isSelected ? BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
      ) : null,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ) : null,
        trailing: trailing,
        onTap: onTap,
        dense: isDense,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMD,
          vertical: DesignTokens.spaceSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        ),
      ),
    );
  }
}

/// Loading overlay for full screen loading states
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.message,
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isVisible)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spaceLG),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
                child: AppLoadingIndicator(
                  size: 48,
                  message: message,
                  showMessage: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty state widget with illustration and action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: DesignTokens.iconXL * 2,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: DesignTokens.spaceLG),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spaceLG),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                variant: ButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxCrossAxisExtent = 300,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(DesignTokens.spaceMD),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: DesignTokens.spaceMD,
        mainAxisSpacing: DesignTokens.spaceMD,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Animated slide transition
class SlideTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Offset end;

  const SlideTransition({
    super.key,
    required this.child,
    this.duration = DesignTokens.animationMedium,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(offset.dx * MediaQuery.of(context).size.width, 
                        offset.dy * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Success/Error snackbar helpers
class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: DesignTokens.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: DesignTokens.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.emergencyColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: DesignTokens.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}