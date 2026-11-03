import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/SquareButton.dart';
import 'tela_alfabeto_screen.dart';
import 'tela_numeros_screen.dart';
import 'tela_cores_screen.dart';
import 'tela_suas_palavras_screen.dart';
import '../database/banco_dedole.dart';

class TelaBancoDePalavras extends StatefulWidget {
  const TelaBancoDePalavras({super.key});

  @override
  State<TelaBancoDePalavras> createState() => _TelaBancoDePalavrasState();
}

class _TelaBancoDePalavrasState extends State<TelaBancoDePalavras> {
  final TextEditingController _controller = TextEditingController();

  // CORES DINÂMICAS
  // Acompanham o tema global do Dedolê.

  Color get corPrincipal => Theme.of(context).colorScheme.primary;

  Color get corTexto => Theme.of(context).colorScheme.onSurface;

  Color get corFundo => Theme.of(context).scaffoldBackgroundColor;

  Color get corSuperficie => Theme.of(context).colorScheme.surface;

  Color get corBorda => Theme.of(context).colorScheme.outline;

  // Identifica quando os SVGs precisam mudar de cor.
  // No tema claro original, mantém as cores dos arquivos SVG.

  bool get usarCorAdaptada =>
      Theme.of(context).colorScheme.primary != const Color(0xFF1B2161);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // SALVAR PALAVRA
  // Mantém o funcionamento original com SQLite.

  Future<void> _salvarPalavra() async {
    final texto = _controller.text.trim();

    if (texto.isEmpty) return;

    await BancoDedole.adicionarPalavra(texto);

    _controller.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Palavra salva!')));
  }

  // ÍCONES SVG
  // Ajusta as cores quando o tema muda.

  Widget _iconeSvg(String caminho) {
    return SvgPicture.asset(
      caminho,
      width: 40,
      height: 40,
      colorFilter: usarCorAdaptada
          ? ColorFilter.mode(corPrincipal, BlendMode.srcIn)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
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

  // CABEÇALHO

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          tooltip: 'Voltar',
          icon: Icon(Icons.arrow_back_ios_new, color: corPrincipal),
          onPressed: () => Navigator.maybePop(context),
        ),

        Expanded(
          child: Text(
            'Digite a sua palavra:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: corTexto,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // CAMPO DE TEXTO

  Widget _buildCampoTexto() {
    return Container(
      decoration: BoxDecoration(
        color: corSuperficie,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corBorda, width: 1.2),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        style: TextStyle(color: corTexto, fontSize: 16),
        cursorColor: corPrincipal,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // BOTÃO SALVAR

  Widget _buildBotaoSalvar() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton(
        onPressed: _salvarPalavra,
        style: OutlinedButton.styleFrom(
          backgroundColor: corSuperficie,
          foregroundColor: corTexto,
          side: BorderSide(color: corBorda, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'Salvar',
          style: TextStyle(
            color: corTexto,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // GRID DE ATALHOS
  // A altura acompanha a escala de texto para reduzir
  // o risco de textos cortados.

  Widget _buildGridDeAtalhos() {
    final escalaTexto = MediaQuery.textScalerOf(context).scale(1.0);

    final fatorAltura = escalaTexto > 1.0 ? escalaTexto : 1.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05 / fatorAltura,
      children: [
        // SUAS PALAVRAS
        buildSquareButton(
          label: 'Suas palavras',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaSuasPalavras()),
            );
          },
          icon: _iconeSvg('assets/vetores/imgSuasPalavras.svg'),
        ),

        // ALFABETO
        buildSquareButton(
          label: 'Alfabeto',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaAlfabeto()),
            );
          },
          icon: _iconeSvg('assets/vetores/imgAlfabeto.svg'),
        ),

        // NÚMEROS
        buildSquareButton(
          label: 'Números',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaNumeros()),
            );
          },
          icon: _iconeSvg('assets/vetores/imgNúmeros.svg'),
        ),

        // CORES
        buildSquareButton(
          label: 'Cores',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaCores()),
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
