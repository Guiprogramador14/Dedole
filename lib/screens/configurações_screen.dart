import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Cores reutilizadas em toda a tela (ajuste o tom se quiser bater 100%
// com o protótipo)
// ---------------------------------------------------------------------
class AppColors {
  static const navy = Color(0xFF1B2161);
  static const background = Color(0xFFF3F3FA);
  static const cardBackground = Color(0xFFFCFCFF);
}

// ---------------------------------------------------------------------
// Tela principal: "Digite a sua palavra"
// ---------------------------------------------------------------------
class TelaConfig extends StatefulWidget {
  const TelaConfig({super.key});

  @override
  State<TelaConfig> createState() => _TelaConfigState();
}

class _TelaConfigState extends State<TelaConfig> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvarPalavra() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    // TODO: aqui entra a conversão da palavra para padrões Braille
    // e o envio via Bluetooth para o ESP32.
    debugPrint('Palavra salva: $texto');
  }

  void _abrirBluetooth() {
    // TODO: navegar para a tela de pareamento/conexão BLE
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildCampoTexto(),
              const SizedBox(height: 16),
              _buildBotaoSalvar(),
              const SizedBox(height: 28),
              Expanded(child: _buildGridDeAtalhos()),
            ],
          ),
        ),
      ),
    );
  }

  // -- Cabeçalho: seta de voltar, título e ícone de bluetooth ----------
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        const Expanded(
          child: Text(
            'Digite a sua palavra:',
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

  // -- Campo de texto -----------------------------------------------
  Widget _buildCampoTexto() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navy, width: 1.2),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.navy, fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // -- Botão "Salvar" (pill outline) ---------------------------------
  Widget _buildBotaoSalvar() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _salvarPalavra,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Configuraaaarrrrr',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // -- Grade 2x2 com os atalhos ---------------------------------------
  Widget _buildGridDeAtalhos() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _CardAtalho(
          label: 'Suas palavras',
          onTap: () {},
          child: const Icon(Icons.edit_outlined, size: 44, color: AppColors.navy),
        ),
        _CardAtalho(
          label: 'Alfabeto',
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'A',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(width: 6),
              _BrailleDots(),
            ],
          ),
        ),
        _CardAtalho(
          label: 'Números',
          onTap: () {},
          child: const Text(
            '0-9',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ),
        _CardAtalho(
          label: 'Cores',
          onTap: () {},
          child: const _FlorDeCores(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Card reutilizável (borda navy, cantos arredondados)
// ---------------------------------------------------------------------
class _CardAtalho extends StatelessWidget {
  const _CardAtalho({required this.label, required this.child, required this.onTap});

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.navy, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Pontinhos estilo Braille usados no card "Alfabeto" (decorativo)
// ---------------------------------------------------------------------
class _BrailleDots extends StatelessWidget {
  const _BrailleDots();

  static const _pattern = [
    [true, false],
    [true, true],
    [false, false],
  ];

  @override
  Widget build(BuildContext context) {
    const dotSize = 9.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pattern.map((linha) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: linha.map((preenchido) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: preenchido ? AppColors.navy : Colors.transparent,
                    border: Border.all(color: AppColors.navy, width: 1.2),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------
// "Flor" de círculos coloridos usada no card "Cores" (decorativo)
// ---------------------------------------------------------------------
class _FlorDeCores extends StatelessWidget {
  const _FlorDeCores({this.size = 48});

  final double size;

  static const _cores = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.green,
    Colors.blueAccent,
    Colors.purpleAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_cores.length, (i) {
          final angulo = (i * 60) * math.pi / 180;
          final raio = size * 0.26;
          final dx = raio * math.cos(angulo);
          final dy = raio * math.sin(angulo);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cores[i].withOpacity(0.9),
              ),
            ),
          );
        }),
      ),
    );
  }
}