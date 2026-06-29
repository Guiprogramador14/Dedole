import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Cores reutilizadas (mesma paleta da tela principal). Se preferir,
// mova esta classe para um arquivo único (ex: app_colors.dart) e
// importe nas duas telas em vez de duplicar.
// ---------------------------------------------------------------------
class AppColors {
  static const navy = Color(0xFF1B2161);
  static const background = Color(0xFFF6F6FB);
  static const divider = Color(0xFFE3E3EC);
  static const subtitle = Color(0xFF8C8C99);
}

// ---------------------------------------------------------------------
// Tela: "Alfabeto" — lista de A a Z + opção "Alfabeto completo"
// ---------------------------------------------------------------------
class TelaAlfabeto extends StatelessWidget {
  const TelaAlfabeto({super.key});

  // Gera ['A', 'B', ..., 'Z']
  static final List<String> _letras = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );

  void _transcreverLetra(String letra) {
    // TODO: converter a letra para o padrão Braille (6 bits) e enviar
    // pelo Bluetooth para o ESP32 acionar os pinos correspondentes.
    debugPrint('Transcrever letra: $letra');
  }

  void _transcreverAlfabetoCompleto() {
    // TODO: percorrer A-Z, convertendo e enviando cada letra em
    // sequência (com um intervalo entre cada uma) para o ESP32.
    debugPrint('Transcrever alfabeto completo');
  }

  void _abrirBluetooth() {
    // TODO: navegar para a tela de pareamento/conexão BLE
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Selecione uma para transcrever',
                style: TextStyle(color: AppColors.subtitle, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _letras.length + 1, // +1 = "Alfabeto completo"
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ItemLista(
                      titulo: 'Alfabeto completo',
                      onTap: _transcreverAlfabetoCompleto,
                    );
                  }
                  final letra = _letras[index - 1];
                  return _ItemLista(
                    titulo: 'LETRA $letra',
                    onTap: () => _transcreverLetra(letra),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Cabeçalho: seta de voltar, título e ícone de bluetooth ----------
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        const Expanded(
          child: Text(
            'Alfabeto',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.bluetooth, color: AppColors.navy),
          onPressed: _abrirBluetooth,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Linha da lista: texto à esquerda + botão de "play" circular à direita
// ---------------------------------------------------------------------
class _ItemLista extends StatelessWidget {
  const _ItemLista({required this.titulo, required this.onTap});

  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy, width: 1.3),
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 16,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Apenas para testar a tela isoladamente (opcional, pode remover)
// ---------------------------------------------------------------------
void main() {
  runApp(const MaterialApp(
    home: TelaAlfabeto(),
    debugShowCheckedModeBanner: false,
  ));
}