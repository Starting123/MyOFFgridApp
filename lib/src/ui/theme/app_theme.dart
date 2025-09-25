import 'package:flutter/material.dart';

/// Modern Material 3 theme configuration for Off-Grid SOS app
class AppTheme {
  // Base colors
  static const Color _primaryBlue = Color(0xFF00D4FF);
  static const Color _emergencyRed = Color(0xFFFF4757);
  static const Color _rescuerGreen = Color(0xFF4CAF50);
  static const Color _warningAmber = Color(0xFFFFC107);
  
  // Dark theme colors
  static const Color _darkSurface = Color(0xFF0A0A0A);
  static const Color _darkSurfaceVariant = Color(0xFF1A1A2E);
  static const Color _darkBackground = Color(0xFF0F0F0F);
  
  // Text colors
  static const Color _onDarkPrimary = Colors.white;
  static const Color _onDarkSecondary = Color(0xFFE0E0E0);
  static const Color _onDarkTertiary = Color(0xFFB0B0B0);

  /// Light theme configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: _primaryBlue,
      secondary: _emergencyRed,
      tertiary: _rescuerGreen,
      error: _emergencyRed,
      surface: Color(0xFFFFFBFE),
      surfaceVariant: Color(0xFFF3F4F6),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      typography: Typography.material2021(),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: colorScheme.surfaceVariant,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Color(0xFF79747E),
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
    );
  }

  /// Dark theme configuration (primary theme for emergency app)
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: _primaryBlue,
      secondary: _emergencyRed,
      tertiary: _rescuerGreen,
      error: _emergencyRed,
      surface: _darkSurface,
      surfaceVariant: _darkSurfaceVariant,
      background: _darkBackground,
      onPrimary: _onDarkPrimary,
      onSecondary: _onDarkPrimary,
      onSurface: _onDarkPrimary,
      onSurfaceVariant: _onDarkSecondary,
      onBackground: _onDarkPrimary,
      outline: Color(0xFF938F99),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      typography: Typography.material2021(),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onDarkPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: _onDarkPrimary,
        ),
        iconTheme: IconThemeData(color: _onDarkPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: colorScheme.shadow.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: _darkSurfaceVariant,
        surfaceTintColor: _primaryBlue.withOpacity(0.1),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: colorScheme.shadow.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _emergencyRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: _onDarkSecondary),
        hintStyle: TextStyle(color: _onDarkSecondary.withOpacity(0.6)),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkSurfaceVariant,
        elevation: 8,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _onDarkTertiary,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // Scaffold Theme
      scaffoldBackgroundColor: _darkBackground,
    );
  }

  /// Emergency SOS button theme
  static ButtonStyle get emergencyButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: _emergencyRed,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: _emergencyRed.withOpacity(0.4),
      padding: const EdgeInsets.all(24),
      shape: const CircleBorder(),
      minimumSize: const Size(120, 120),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Rescuer mode button theme
  static ButtonStyle get rescuerButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: _rescuerGreen,
      foregroundColor: Colors.white,
      elevation: 6,
      shadowColor: _rescuerGreen.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Connection status indicator colors
  static Map<String, Color> get connectionStatusColors {
    return {
      'connected': _rescuerGreen,
      'connecting': _warningAmber,
      'disconnected': _onDarkTertiary,
      'error': _emergencyRed,
      'sos_active': _emergencyRed,
      'rescuer_active': _rescuerGreen,
    };
  }

  /// Gradient backgrounds for different sections
  static LinearGradient get emergencyGradient {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _emergencyRed.withOpacity(0.2),
        _emergencyRed.withOpacity(0.1),
        _darkBackground,
      ],
    );
  }

  static LinearGradient get rescuerGradient {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _rescuerGreen.withOpacity(0.2),
        _rescuerGreen.withOpacity(0.1),
        _darkBackground,
      ],
    );
  }

  static LinearGradient get mainGradient {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A1A2E),
        Color(0xFF16213E),
        _darkBackground,
      ],
    );
  }

  /// Text styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    color: _onDarkPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: _onDarkPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: _onDarkPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: _onDarkPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: _onDarkSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: _onDarkSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: _onDarkPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: _onDarkSecondary,
  );

  /// Status indicator theme
  static Widget statusIndicator({
    required String status,
    required String label,
    double size = 12,
  }) {
    final color = connectionStatusColors[status] ?? _onDarkTertiary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Animated pulse effect for emergency elements
  static Widget pulseEffect({
    required Widget child,
    bool isActive = false,
    Color color = _emergencyRed,
  }) {
    if (!isActive) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6 * (1 - value)),
                blurRadius: 20 * value,
                spreadRadius: 10 * value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Extension for custom colors in ColorScheme
extension CustomColorScheme on ColorScheme {
  Color get warning => const Color(0xFFFFC107);
  Color get success => const Color(0xFF4CAF50);
  Color get info => const Color(0xFF00D4FF);
}