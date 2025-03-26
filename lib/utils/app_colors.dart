import 'package:flutter/material.dart';

class AppColors {
  // Main color palette from the provided image
  static const Color primary = Color(0xFF222831);    // #222831 - Dark navy blue
  static const Color secondary = Color(0xFF393E46);  // #393E46 - Dark slate
  static const Color tertiary = Color(0xFF00ADB5);   // #00ADB5 - Teal/turquoise
  static const Color quaternary = Color(0xFFEEEEEE); // #EEEEEE - Off-white
  static const Color white = Color(0xFFFFFFFF);      // #FFFFFF - White
  
  // Additional colors for specific UI elements
  static const Color background = primary;
  static const Color cardBackground = secondary;
  static const Color buttonColor = tertiary;
  static const Color accentColor = tertiary;
  static const Color primaryText = quaternary;       // Text is light for contrast on dark backgrounds
  static const Color secondaryText = tertiary;       // Secondary text in teal

  // Aliases for backward compatibility with the old grey theme
  static const Color darkest = primary;              // Darkest is now dark navy
  static const Color darkGrey = secondary;           // Dark grey is now dark slate
  static const Color mediumGrey = tertiary;          // Medium grey is now teal
  static const Color lightGrey = quaternary;         // Light grey is now off-white
  static const Color lightest = white;               // Lightest remains white
}
