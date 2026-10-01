import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (Deep Teal / Pine Green from reference images)
  static const Color primaryTeal = Color(0xFF07675D);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color lightTeal = Color(0xFFE0F2F1);
  static const Color accentTeal = Color(0xFF0B7B6E);

  // Backgrounds
  static const Color scaffoldBackground = Color(0xFFF7F9FA);
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Color(0xFFFAFCFD);
  static const Color headerGray = Color(0xFFF1F5F9);
  static const Color infoBackground = Color(0xFFF1F5F9);

  // Status Badges
  static const Color requiredBadgeBg = Color(0xFF56BAA7);
  static const Color requiredBadgeText = Colors.white;
  static const Color optionalBadgeBg = Color(0xFFE2E8F0);
  static const Color optionalBadgeText = Color(0xFF64748B);

  // Dashed Borders
  static const Color dashedRed = Color(0xFFE53935);
  static const Color dashedGreen = Color(0xFF66BB6A);
  static const Color dashedTeal = Color(0xFF07675D);
  static const Color dashedDefault = Color(0xFFCBD5E1);

  // Alert & Corruption (Discrepancy)
  static const Color alertRedBg = Color(0xFFFFEBEE);
  static const Color alertRedBorder = Color(0xFFFFCDD2);
  static const Color alertRedIcon = Color(0xFFC62828);
  static const Color alertRedTitle = Color(0xFFB71C1C);
  static const Color alertRedSubtitle = Color(0xFFC62828);

  // Success & In-Sync
  static const Color successGreenBg = Color(0xFFE8F5E9);
  static const Color successGreenBorder = Color(0xFFA5D6A7);
  static const Color successGreenIcon = Color(0xFF2E7D32);
  static const Color successGreenTitle = Color(0xFF1B5E20);
  static const Color successGreenSubtitle = Color(0xFF2E7D32);

  // Typography / Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Dividers & Borders
  static const Color divider = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Figma Admin Theme Palette
  static const Color figmaDarkGreen = Color(0xFF064E3B);
  static const Color figmaDeepGreen = Color(0xFF04382A);
  static const Color figmaEmerald = Color(0xFF056044);
  static const Color figmaPrimaryBtn = Color(0xFF0D5D44);
  static const Color figmaCardBg = Colors.white;

  // Active / Inactive / Checked Badges
  static const Color badgeActiveBg = Color(0xFFD1FAE5);
  static const Color badgeActiveText = Color(0xFF065F46);
  static const Color badgeInactiveBg = Color(0xFFFEE2E2);
  static const Color badgeInactiveText = Color(0xFFB91C1C);
  static const Color badgeCheckedBg = Color(0xFFDCFCE7);
  static const Color badgeCheckedText = Color(0xFF15803D);

  // Filter Chips
  static const Color chipActiveBg = Color(0xFF0D5D44);
  static const Color chipActiveText = Colors.white;
  static const Color chipInactiveBg = Color(0xFFF1F5F9);
  static const Color chipInactiveText = Color(0xFF64748B);

  // Logout & Destructive
  static const Color logoutRed = Color(0xFFDC2626);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color logoutBorder = Color(0xFFFCA5A5);
  static const Color logoutBg = Color(0xFFFEF2F2);
}
