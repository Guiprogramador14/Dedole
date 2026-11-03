
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../utils/fila_dedole.dart';

class TelaNumeros extends StatefulWidget {
  const TelaNumeros({super.key});

  @override
  State<TelaNumeros> createState() => _TelaNumerosState();
}

class _TelaNumerosState extends State<TelaNumeros> {
  static const String digitos = '0123456789';

  final FilaDedole fila = FilaDedole.instance;
  String? mensagemAnterior;

  // ==========================================
  // CORES DINÂMICAS DO TEMA
  // ==========================================

  Color get corPrincipal =>
      Theme.of(context).colorScheme.primary;

  Color get corTexto =>
      Theme.of(context).colorScheme.onSurface;

  Color get corFundo =>
      Theme.of(context).scaffoldBackgroundColor;

  Color get corSuperficie =>
      Theme.of(context).colorScheme.surface;

  Color get corDivisoria =>
      Theme.of(context).dividerColor;

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================

  @override
  void initState() {
    super.initState();

    mensagemAnterior = fila.mensagem;
    fila.addListener(atualizar);
    fila.preparar();
  }

  // ==========================================
  // ATUALIZAÇÃO E ACESSIBILIDADE
  // ==========================================

  void atualizar() {
    if (!mounted) return;

    setState(() {});

    if (mensagemAnterior != fila.mensagem) {
      mensagemAnterior = fila.mensagem;

      SemanticsService.sendAnnouncement(
        View.of(context),
        fila.mensagem,
        TextDirection.ltr,
      );
    }
  }

  // ==========================================
  // MENSAGENS
  // ==========================================

  void aviso(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          behavior: SnackBarBehavior.floating,
        ),
      );

    SemanticsService.sendAnnouncement(
      View.of(context),
      texto,
      TextDirection.ltr,
    );
  }

  // ==========================================
  // ADICIONAR NÚMERO À FILA
  // ==========================================

  void adicionarFila(String numero) {
    if (fila.adicionar(numero)) {
      aviso(
        'Número $numero adicionado ao final da fila.',
      );
    } else {
      aviso(
        'Não foi possível adicionar o número $numero.',
      );
    }
  }

  // ==========================================
  // REPRODUZIR OU PARAR NÚMERO
  // ==========================================

  Future<void> selecionar(String numero) async {
    // Mantém o funcionamento da FilaDedole.
    //
    // Se o número já estiver sendo reproduzido,
    // interrompe a reprodução.
    //
    // Caso contrário, inicia o número escolhido.

    if (fila.palavraEmExecucao == numero) {
      await fila.parar();
    } else {
      await fila.play(numero);
    }
  }

  // ==========================================
  // FINALIZAÇÃO
  // ==========================================

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  // ==========================================
  // CRIAR ITEM DA LISTA DE NÚMEROS
  // ==========================================

  Widget criarNumero(String numero) {
    final ativo = fila.palavraEmExecucao == numero;

    final acao = ativo
        ? 'Parar número $numero'
        : 'Reproduzir número $numero';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),

          // ==================================
          // NÚMERO
          // ==================================

          title: Text(
            'NÚMERO $numero',
            softWrap: true,
            style: TextStyle(
              color: corTexto,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ==================================
          // ESTADO DA REPRODUÇÃO
          // ==================================

          subtitle: ativo
              ? Text(
                  fila.aguardandoSinalNumero
                      ? 'Sinal de número: pontos 3, 4, 5 e 6'
                      : 'Algarismo $numero: aguardando resposta',
                  softWrap: true,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 12,
                  ),
                )
              : null,

          // ==================================
          // BOTÕES
          // ==================================

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ADICIONAR À FILA

              IconButton(
                tooltip:
                    'Adicionar número $numero ao final da fila',
                onPressed: () => adicionarFila(numero),
                icon: Icon(
                  Icons.playlist_add,
                  color: corPrincipal,
                ),
              ),

              // PLAY / STOP

              IconButton(
                tooltip: acao,
                onPressed: () => selecionar(numero),
                iconSize: 40,
                color: corPrincipal,
                icon: Icon(
                  ativo
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                ),
              ),
            ],
          ),
        ),

        // DIVISÓRIA DINÂMICA

        Divider(
          height: 1,
          color: corDivisoria,
        ),
      ],
    );
  }

  // ==========================================
  // INTERFACE PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            children: [
              // ==================================
              // CABEÇALHO
              // ==================================

              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Voltar',
                    onPressed: () =>
                        Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: corPrincipal,
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'Números',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: corTexto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================
              // INSTRUÇÕES
              // ==================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione um número para representar '
                  'em Braille ou adicionar à fila',
                  softWrap: true,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================
              // ESTADO DA ATIVIDADE
              // ==================================

              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corSuperficie,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: corDivisoria,
                    ),
                  ),

                  child: Text(
                    fila.mensagem,
                    softWrap: true,
                    style: TextStyle(
                      color: corTexto,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================
              // LISTA DE NÚMEROS
              // ==================================

              Expanded(
                child: ListView.builder(
                  itemCount: digitos.length,
                  itemBuilder: (context, i) =>
                      criarNumero(digitos[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
