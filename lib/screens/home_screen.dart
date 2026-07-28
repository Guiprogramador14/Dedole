import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_actions.dart';
import 'word_bank_screen.dart';
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

            // ENVIAR
            SizedBox(
              width: double.infinity,
              height: 70,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaEnviar(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF394A94),
                        width: 5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/vetores/imgEnviar.svg',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ),
              ),
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
                        builder: (context) => const TelaConfig(),
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