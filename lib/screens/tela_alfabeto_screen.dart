
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../utils/fila_dedole.dart';

class TelaAlfabeto extends StatefulWidget {
  const TelaAlfabeto({super.key});

  @override
  State<TelaAlfabeto> createState() => _TelaAlfabetoState();
}

class _TelaAlfabetoState extends State<TelaAlfabeto> {
  static const String letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final FilaDedole fila = FilaDedole.instance;
  String? mensagemAnterior;

  // ==========================================
  // CORES DINÂMICAS
  // ==========================================

  Color get corPrincipal =>
      Theme.of(context).colorScheme.primary;

  Color get corTexto =>
      Theme.of(context).colorScheme.onSurface;

  Color get corFundo =>
      Theme.of(context).scaffoldBackgroundColor;

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
  // ACESSIBILIDADE
  // ==========================================

  void falar(String mensagem) {
    if (!mounted) return;

    SemanticsService.sendAnnouncement(
      View.of(context),
      mensagem,
      TextDirection.ltr,
    );
  }

  // ==========================================
  // ATUALIZAÇÃO DA FILA
  // ==========================================

  void atualizar() {
    if (!mounted) return;

    setState(() {});

    if (mensagemAnterior != fila.mensagem) {
      mensagemAnterior = fila.mensagem;
      falar(fila.mensagem);
    }
  }

  // ==========================================
  // MENSAGENS
  // ==========================================

  void informar(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

    falar(mensagem);
  }

  // ==========================================
  // ADICIONAR LETRA À FILA
  // ==========================================

  void adicionarFila(String letra) {
    if (fila.adicionar(letra)) {
      informar(
        'Letra $letra adicionada ao final da fila.',
      );
    } else {
      informar(
        'Não foi possível adicionar a letra $letra.',
      );
    }
  }

  // ==========================================
  // REPRODUZIR OU PARAR LETRA
  // ==========================================

  Future<void> selecionar(String letra) async {
    // Se a letra já estiver sendo reproduzida,
    // o botão interrompe a reprodução.
    //
    // Caso contrário, inicia a letra selecionada
    // com a prioridade definida na FilaDedole.

    if (fila.reproduzindo &&
        fila.palavraEmExecucao == letra) {
      await fila.parar();
    } else {
      await fila.play(letra);
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
  // ITEM DA LISTA DE LETRAS
  // ==========================================

  Widget criarLetra(String letra) {
    final bool ativa = fila.reproduzindo &&
        fila.palavraEmExecucao == letra;

    final String acao = ativa ? 'Parar' : 'Reproduzir';

    return Column(
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),

            // NOME DA LETRA

            title: Text(
              'LETRA $letra',
              style: TextStyle(
                color: corTexto,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),

            // STATUS DA REPRODUÇÃO

            subtitle: ativa
                ? Text(
                    'Aguardando resposta nos botões físicos',
                    softWrap: true,
                    style: TextStyle(
                      color: corTexto,
                      fontSize: 12,
                    ),
                  )
                : null,

            // BOTÕES DE CONTROLE

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ADICIONAR À FILA

                IconButton(
                  tooltip:
                      'Adicionar letra $letra ao final da fila',
                  onPressed: () => adicionarFila(letra),
                  icon: Icon(
                    Icons.playlist_add,
                    color: corPrincipal,
                  ),
                ),

                // PLAY / STOP

                IconButton(
                  tooltip: '$acao letra $letra',
                  onPressed: () => selecionar(letra),
                  iconSize: 40,
                  color: corPrincipal,
                  icon: Icon(
                    ativa
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                  ),
                ),
              ],
            ),
          ),
        ),

        // DIVISÓRIA ADAPTADA AO TEMA

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
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: corPrincipal,
                    ),
                    onPressed: () =>
                        Navigator.maybePop(context),
                  ),

                  Expanded(
                    child: Text(
                      'Alfabeto',
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
              // INSTRUÇÃO
              // ==================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione uma letra para representar em Braille',
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
                label:
                    'Estado da atividade: ${fila.mensagem}',
                child: ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fila.mensagem,
                      softWrap: true,
                      style: TextStyle(
                        color: corTexto,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================
              // LISTA DE LETRAS
              // ==================================

              Expanded(
                child: ListView.builder(
                  itemCount: letras.length,
                  itemBuilder: (_, i) =>
                      criarLetra(letras[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
