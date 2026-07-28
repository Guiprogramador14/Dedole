import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TelaBancoDePalavras extends StatefulWidget {
  const TelaBancoDePalavras({super.key});

  @override
  State<TelaBancoDePalavras> createState() => _TelaBancoDePalavrasState();
}

class _TelaBancoDePalavrasState extends State<TelaBancoDePalavras> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvarPalavra() {
    final texto = _controller.text.trim();

    if (texto.isEmpty) return;

    // TODO: Converter para Braille e enviar ao ESP32
    debugPrint('Palavra salva: $texto');
  }

  void _abrirBluetooth() {
    // TODO: Tela de Bluetooth
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
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

              Expanded(
                child: _buildGridDeAtalhos(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1B2161),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        const Expanded(
          child: Text(
            'Digite a sua palavra:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1B2161),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: _abrirBluetooth,
          icon: SvgPicture.asset(
            'assets/vetores/imgBluetooth.svg',
            width: 28,
            height: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTexto() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1B2161),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1B2161),
          fontSize: 16,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _salvarPalavra,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFCFCFF),
          side: const BorderSide(
            color: Color(0xFF1B2161),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'Salvar',
          style: TextStyle(
            color: Color(0xFF1B2161),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGridDeAtalhos() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _CardAtalho(
          label: 'Suas palavras',
          onTap: () {},
          child: SvgPicture.asset(
            'assets/vetores/imgSuasPalavras.svg',
            width: 40,
            height: 40,
          ),
        ),
        _CardAtalho(
          label: 'Alfabeto',
          onTap: () {},
          child: SvgPicture.asset(
            'assets/vetores/imgAlfabeto.svg',
            width: 40,
            height: 40,
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
              color: Color(0xFF1B2161),
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

class _CardAtalho extends StatelessWidget {
  const _CardAtalho({
    required this.label,
    required this.child,
    required this.onTap,
  });

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
          color: const Color(0xFFFCFCFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1B2161),
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1B2161),
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
          final angulo = i * 60 * math.pi / 180;
          final raio = size * 0.26;

          return Transform.translate(
            offset: Offset(
              raio * math.cos(angulo),
              raio * math.sin(angulo),
            ),
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