import 'package:flutter/material.dart';

/// Paleta central. Para telas antigas que usam Color(...) fixo, substitua
/// essas constantes por AppColors.of(context) para acompanhar o tema.
class AppColors {
  static const background = Color(0xFFF6F7FF);
  static const primary = Color(0xFF1B2161);

  static Color backgroundOf(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;
}
