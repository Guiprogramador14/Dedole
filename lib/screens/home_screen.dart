import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_actions.dart';
import 'tela_banco_de_palavras.dart';
import 'bluetooth_screen.dart';
import 'enviar_screen.dart';
import '../widgets/SquareButton.dart';
import 'tela_configuracoes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final deveColorirSvg = tema.brightness == Brightness.dark ||
        tema.scaffoldBackgroundColor != const Color(0xFFF6F7FF);
    final filtroIcone = deveColorirSvg
        ? ColorFilter.mode(tema.colorScheme.primary, BlendMode.srcIn)
        : null;
    final filtroLogo = deveColorirSvg
        ? ColorFilter.mode(tema.colorScheme.onSurface, BlendMode.srcIn)
        : null;

    Widget icone(String caminho) => SvgPicture.asset(
          caminho,
          width: 40,
          height: 40,
          colorFilter: filtroIcone,
        );

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Center(
                child: SvgPicture.asset(
                  'assets/vetores/logoSomenteTexto.svg',
                  height: 100,
                  colorFilter: filtroLogo,
                ),
              ),
              const SizedBox(height: 30),
              buildSquareButton(
                width: double.infinity,
                height: 130,
                icon: icone('assets/vetores/imgEnviar.svg'),
                label: 'Enviar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaEnviar()),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildSquareButton(
                      icon: icone('assets/vetores/imgBluetooth.svg'),
                      label: 'Bluetooth',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaBluetooth()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildSquareButton(
                      icon: icone('assets/vetores/imgBancoDePalavras.svg'),
                      label: 'Banco de palavras',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaBancoDePalavras()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildSquareButton(
                      icon: icone('assets/vetores/imgConfigurações.svg'),
                      label: 'Configurações',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildSquareButton(
                      icon: icone('assets/vetores/imgSair.svg'),
                      label: 'Sair',
                      onTap: sairDoApp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
