import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_actions.dart';
import 'tela_banco_de_palavras.dart';
import 'bluetooth_screen.dart';
import 'enviar_screen.dart';
import '../widgets/SquareButton.dart';
import 'configurações_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 65),

            // LOGO
            Center(
              child: SvgPicture.asset(
                'assets/vetores/logoSomenteTexto.svg',
                height: 100,
              ),
            ),

            const SizedBox(height: 30),

            buildSquareButton(
              width: double.infinity,
              height: 130,
              icon: SvgPicture.asset(
                'assets/vetores/imgEnviar.svg',
                width: 40,
                height: 40,
              ),
              label: 'Enviar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaEnviar()),
                );
              },
            ),

            const SizedBox(height: 20),

            // LINHA 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildSquareButton(
                  icon: SvgPicture.asset(
                    'assets/vetores/imgBluetooth.svg',
                    width: 40,
                    height: 40,
                  ),
                  label: 'Bluetooth',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaBluetooth(),
                      ),
                    );
                  },
                ),
                buildSquareButton(
                  icon: SvgPicture.asset(
                    'assets/vetores/imgBancoDePalavras.svg',
                    width: 40,
                    height: 40,
                  ),
                  label: 'Banco de palavras',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaBancoDePalavras(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // LINHA 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildSquareButton(
                  icon: SvgPicture.asset(
                    'assets/vetores/imgConfigurações.svg',
                    width: 40,
                    height: 40,
                  ),
                  label: 'Configurações',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaConfiguracoes(),
                      ),
                    );
                  },
                ),
                buildSquareButton(
                  icon: SvgPicture.asset(
                    'assets/vetores/imgSair.svg',
                    width: 40,
                    height: 40,
                  ),
                  label: 'Sair',
                  onTap: sairDoApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
