import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/fila_dedole.dart';
import 'utils/preferencias_dedole.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FilaDedole.instance.inicializar();
  await PreferenciasDedole.instance.inicializar();
  runApp(const DedoleApp());
}

class DedoleApp extends StatelessWidget {
  const DedoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferenciasDedole.instance;
    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: prefs.themeMode,
        theme: AppColors.criarTema(
          escuro: false,
          altoContraste: prefs.altoContraste,
        ),
        darkTheme: AppColors.criarTema(
          escuro: true,
          altoContraste: prefs.altoContraste,
        ),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final escalaSistema = media.textScaler.scale(1.0);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                escalaSistema * (prefs.textoAmpliado ? 1.2 : 1.0),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
