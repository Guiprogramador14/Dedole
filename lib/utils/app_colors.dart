import 'package:flutter/material.dart';

class AppColors {
  // Compatibilidade com telas antigas; prefira os métodos com context.
  static const Color background = Color(0xFFF6F7FF);
  static const Color primary = Color(0xFF1B2161);

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color textOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color dividerOf(BuildContext context) =>
      Theme.of(context).dividerColor;

  static ThemeData criarTema({required bool escuro, required bool altoContraste}) {
    final Color fundo;
    final Color superficie;
    final Color principal;
    final Color texto;
    final Color sobrePrincipal;
    final Color borda;

    if (altoContraste && escuro) {
      fundo = const Color(0xFF080808);
      superficie = const Color(0xFF181818);
      principal = const Color(0xFFFFE45C);
      texto = const Color(0xFFFFF2A0);
      sobrePrincipal = Colors.black;
      borda = const Color(0xFFFFE45C);
    } else if (altoContraste) {
      fundo = const Color(0xFFFFF4AE);
      superficie = const Color(0xFFFFFBE0);
      principal = const Color(0xFF171717);
      texto = const Color(0xFF171717);
      sobrePrincipal = const Color(0xFFFFF4AE);
      borda = const Color(0xFF171717);
    } else if (escuro) {
      fundo = const Color(0xFF141627);
      superficie = const Color(0xFF252A44);
      principal = const Color(0xFFC6CDFF);
      texto = const Color(0xFFF5F6FF);
      sobrePrincipal = const Color(0xFF171A30);
      borda = const Color(0xFF626B94);
    } else {
      fundo = background;
      superficie = Colors.white;
      principal = primary;
      texto = primary;
      sobrePrincipal = Colors.white;
      borda = const Color(0xFFD8DCEF);
    }

    final esquema = ColorScheme.fromSeed(
      seedColor: principal,
      brightness: escuro ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: principal,
      onPrimary: sobrePrincipal,
      surface: superficie,
      onSurface: texto,
      outline: borda,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NunitoSans',
      brightness: escuro ? Brightness.dark : Brightness.light,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      dividerColor: borda,
      appBarTheme: AppBarTheme(backgroundColor: fundo, foregroundColor: texto),
      iconTheme: IconThemeData(color: texto),
      listTileTheme: ListTileThemeData(textColor: texto, iconColor: principal),
      cardTheme: CardThemeData(color: superficie),
      textTheme: ThemeData(
        brightness: escuro ? Brightness.dark : Brightness.light,
        fontFamily: 'NunitoSans',
      ).textTheme.apply(bodyColor: texto, displayColor: texto),
    );
  }
}
