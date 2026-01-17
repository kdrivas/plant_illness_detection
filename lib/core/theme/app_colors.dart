import 'package:flutter/material.dart';

class AppColors {
  // Primary Green Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  
  // Secondary Colors
  static const Color mintGreen = Color(0xFF81C784);
  static const Color sageGreen = Color(0xFFA5D6A7);
  static const Color leafGreen = Color(0xFF66BB6A);
  static const Color forestGreen = Color(0xFF388E3C);
  static const Color emeraldGreen = Color(0xFF00C853);
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF8A65);
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color accentPurple = Color(0xFFBA68C8);
  static const Color accentTeal = Color(0xFF26A69A);
  
  // Alert & Status Colors
  static const Color harvestGold = Color(0xFFFFB300);
  static const Color warningAmber = Color(0xFFFF8F00);
  static const Color criticalRed = Color(0xFFD32F2F);
  static const Color optimalTeal = Color(0xFF00897B);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF29B6F6);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF1F8E9);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundDarkCard = Color(0xFF1E1E1E);
  
  // Surface Colors
  static const Color surfaceLight = Color(0xFFE8F5E9);
  static const Color surfaceMedium = Color(0xFFC8E6C9);
  static const Color surfaceDark = Color(0xFF2D2D2D);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Plant-specific Colors
  static const Color lettuce = Color(0xFF8BC34A);
  static const Color strawberry = Color(0xFFE91E63);
  static const Color blueberry = Color(0xFF5C6BC0);
  
  // Sensor Gauge Colors
  static const Color gaugeOptimal = Color(0xFF4CAF50);
  static const Color gaugeWarning = Color(0xFFFFB300);
  static const Color gaugeCritical = Color(0xFFE53935);
  static const Color gaugeBackground = Color(0xFFE0E0E0);
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2E7D32),
    Color(0xFF4CAF50),
    Color(0xFF81C784),
    Color(0xFFFF8A65),
    Color(0xFF4FC3F7),
    Color(0xFFFFD54F),
    Color(0xFFBA68C8),
    Color(0xFF26A69A),
  ];
  
  // Chart line colors for specific sensors
  static const Color chartPh = Color(0xFF7E57C2);
  static const Color chartPH = chartPh; // Alias for consistent naming
  static const Color chartEc = Color(0xFFFFB300);
  static const Color chartEC = chartEc; // Alias for consistent naming
  static const Color chartWaterTemp = Color(0xFF29B6F6);
  static const Color chartHumidity = Color(0xFF26A69A);
  static const Color chartWeatherTemp = Color(0xFFFF7043);
  static const Color chartUv = Color(0xFFFFEE58);
  static const Color chartUV = chartUv; // Alias for consistent naming
  static const Color chartVoc = Color(0xFF78909C);
  static const Color chartMoisture = Color(0xFF66BB6A);
  static const Color chartWaterSupplied = Color(0xFF42A5F5);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenLight],
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, primaryGreenLight, surfaceLight],
    stops: [0.0, 0.7, 1.0],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLight, backgroundCard],
  );
  
  static const LinearGradient harvestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [harvestGold, Color(0xFFFFCA28)],
  );
  
  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningAmber, accentOrange],
  );
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
