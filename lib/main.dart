
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const DedoleApp());
}

class DedoleApp extends StatelessWidget {
  const DedoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Idioma padrão do aplicativo
      locale: const Locale('pt', 'BR'),

      // Idiomas disponíveis
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // Traduções dos componentes Flutter
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        fontFamily: 'NunitoSans',
        scaffoldBackgroundColor: AppColors.background,
      ),

      home: const SplashScreen(),
    );
  }
}
