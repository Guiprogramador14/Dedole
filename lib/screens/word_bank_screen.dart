import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/SquareButton.dart';
import 'tela_alfabeto_screen.dart';
import 'tela_numeros_screen.dart';
import 'tela_cores_screen.dart';
import 'tela_suas_palavras_screen.dart';

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

              Expanded(child: _buildGridDeAtalhos()),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B2161)),
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
        border: Border.all(color: const Color(0xFF1B2161), width: 1.2),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF1B2161), fontSize: 16),
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
          side: const BorderSide(color: Color(0xFF1B2161), width: 1.5),
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
        buildSquareButton(
          label: 'Suas palavras',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TelaSuasPalavras()),
            );
          },
          icon: SvgPicture.asset(
            'assets/vetores/imgSuasPalavras.svg',
            width: 40,
            height: 40,
          ),
        ),
        buildSquareButton(
          label: 'Alfabeto',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TelaAlfabeto()),
            );
          },
          icon: SvgPicture.asset(
            'assets/vetores/imgAlfabeto.svg',
            width: 40,
            height: 40,
          ),
        ),
        buildSquareButton(
          label: 'Números',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TelaNumeros()),
            );
          },
          icon: SvgPicture.asset(
            'assets/vetores/imgNúmeros.svg',
            width: 40,
            height: 40,
          ),
        ),
        buildSquareButton(
          label: 'Cores',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TelaCores()),
            );
          },
          icon: SvgPicture.asset(
            'assets/vetores/imgCores.svg',
            width: 40,
            height: 40,
          ),
        ),
      ],
    );
  }
}
