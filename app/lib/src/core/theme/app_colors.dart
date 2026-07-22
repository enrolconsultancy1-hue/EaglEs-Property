import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Colors
  static const brandPrimary = Color(0xFF0B5FFF); // Eagle Blue
  static const brandDeep = Color(0xFF0A2540); // Midnight — headers, hero
  static const brandAccent = Color(0xFF00C48C); // Emerald — success/growth
  static const brandGold = Color(0xFFF5A623); // Premium highlights

  // Semantic Colors
  static const success = Color(0xFF17B26A);
  static const warning = Color(0xFFF79009);
  static const danger = Color(0xFFF04438);
  static const info = Color(0xFF2E90FA);

  // Light Neutrals
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF8FAFC);
  static const lightSurfaceCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E7EC);
  static const lightTextPrimary = Color(0xFF101828);
  static const lightTextSecondary = Color(0xFF475467);
  static const lightTextTertiary = Color(0xFF98A2B3);

  // Dark Neutrals
  static const darkSurface = Color(0xFF101828);
  static const darkSurfaceAlt = Color(0xFF0C1220);
  static const darkSurfaceCard = Color(0xFF1A2233);
  static const darkBorder = Color(0xFF2A3446);
  static const darkTextPrimary = Color(0xFFF2F4F7);
  static const darkTextSecondary = Color(0xFF98A2B3);
  static const darkTextTertiary = Color(0xFF667085);

  // Domain Status Colors
  static const statusAvailable = success;
  static const statusHeld = info;
  static const statusReserved = warning;
  static const statusSold = brandDeep;
  static const statusRented = Color(0xFF7A5AF8);
  static const statusBlocked = Color(0xFF667085);
}
